-- Fix the payment cascade trigger to use correct status values
CREATE OR REPLACE FUNCTION update_proposal_on_manual_payment_cascade()
RETURNS TRIGGER AS $$
DECLARE
  v_proposal RECORD;
  v_payment_amount DECIMAL(10,2);
  v_deposit_due DECIMAL(10,2);
  v_progress_due DECIMAL(10,2);
  v_final_due DECIMAL(10,2);
  v_deposit_paid_before DECIMAL(10,2);
  v_progress_paid_before DECIMAL(10,2);
  v_final_paid_before DECIMAL(10,2);
  v_deposit_paid_after DECIMAL(10,2);
  v_progress_paid_after DECIMAL(10,2);
  v_final_paid_after DECIMAL(10,2);
  v_total_paid_before DECIMAL(10,2);
  v_total_paid_after DECIMAL(10,2);
  v_remaining_deposit DECIMAL(10,2);
  v_remaining_progress DECIMAL(10,2);
  v_remaining_final DECIMAL(10,2);
  v_amount_to_apply DECIMAL(10,2);
BEGIN
  -- Get current proposal details
  SELECT * INTO v_proposal FROM proposals WHERE id = NEW.proposal_id;
  
  -- Calculate what's due for each stage
  v_deposit_due := COALESCE(v_proposal.deposit_amount, v_proposal.total * 0.5);
  v_progress_due := COALESCE(v_proposal.progress_payment_amount, v_proposal.total * 0.3);
  v_final_due := COALESCE(v_proposal.final_payment_amount, v_proposal.total * 0.2);
  
  -- Get current payments for each stage (before this payment)
  SELECT 
    COALESCE(SUM(CASE WHEN payment_stage = 'deposit' THEN amount ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN payment_stage = 'progress' THEN amount ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN payment_stage = 'final' THEN amount ELSE 0 END), 0)
  INTO v_deposit_paid_before, v_progress_paid_before, v_final_paid_before
  FROM manual_payments
  WHERE proposal_id = NEW.proposal_id
    AND id != NEW.id;  -- Exclude current payment to avoid double counting
  
  -- Calculate total paid before this payment
  v_total_paid_before := v_deposit_paid_before + v_progress_paid_before + v_final_paid_before;
  
  -- Check if payment would exceed total proposal amount
  IF (v_total_paid_before + NEW.amount) > v_proposal.total THEN
    RAISE EXCEPTION 'Payment of $% would exceed total proposal amount. Maximum payable: $%', 
      NEW.amount, (v_proposal.total - v_total_paid_before);
  END IF;
  
  -- Initialize after values with before values
  v_deposit_paid_after := v_deposit_paid_before;
  v_progress_paid_after := v_progress_paid_before;
  v_final_paid_after := v_final_paid_before;
  
  -- Calculate remaining amounts for each stage
  v_remaining_deposit := GREATEST(0, v_deposit_due - v_deposit_paid_before);
  v_remaining_progress := GREATEST(0, v_progress_due - v_progress_paid_before);
  v_remaining_final := GREATEST(0, v_final_due - v_final_paid_before);
  
  -- Apply payment with cascading logic
  v_amount_to_apply := NEW.amount;
  
  IF NEW.payment_stage = 'deposit' THEN
    -- Apply to deposit first (up to what's remaining)
    IF v_remaining_deposit > 0 THEN
      v_deposit_paid_after := v_deposit_paid_after + LEAST(v_amount_to_apply, v_remaining_deposit);
      v_amount_to_apply := v_amount_to_apply - LEAST(v_amount_to_apply, v_remaining_deposit);
    END IF;
    
    -- Cascade overflow to progress
    IF v_amount_to_apply > 0 AND v_remaining_progress > 0 THEN
      v_progress_paid_after := v_progress_paid_after + LEAST(v_amount_to_apply, v_remaining_progress);
      v_amount_to_apply := v_amount_to_apply - LEAST(v_amount_to_apply, v_remaining_progress);
    END IF;
    
    -- Cascade remaining to final
    IF v_amount_to_apply > 0 AND v_remaining_final > 0 THEN
      v_final_paid_after := v_final_paid_after + LEAST(v_amount_to_apply, v_remaining_final);
      v_amount_to_apply := v_amount_to_apply - LEAST(v_amount_to_apply, v_remaining_final);
    END IF;
    
  ELSIF NEW.payment_stage = 'progress' THEN
    -- Apply to progress first
    IF v_remaining_progress > 0 THEN
      v_progress_paid_after := v_progress_paid_after + LEAST(v_amount_to_apply, v_remaining_progress);
      v_amount_to_apply := v_amount_to_apply - LEAST(v_amount_to_apply, v_remaining_progress);
    END IF;
    
    -- Cascade overflow to final
    IF v_amount_to_apply > 0 AND v_remaining_final > 0 THEN
      v_final_paid_after := v_final_paid_after + LEAST(v_amount_to_apply, v_remaining_final);
      v_amount_to_apply := v_amount_to_apply - LEAST(v_amount_to_apply, v_remaining_final);
    END IF;
    
  ELSIF NEW.payment_stage = 'final' THEN
    -- Apply to final only
    v_final_paid_after := v_final_paid_after + v_amount_to_apply;
  END IF;
  
  -- Calculate new total
  v_total_paid_after := v_deposit_paid_after + v_progress_paid_after + v_final_paid_after;
  
  -- Update proposal with cascaded payments
  UPDATE proposals
  SET 
    total_paid = v_total_paid_after,
    -- Set payment timestamps when stage is fully paid
    deposit_paid_at = CASE 
      WHEN v_deposit_paid_after >= v_deposit_due AND deposit_paid_at IS NULL 
      THEN NOW() 
      ELSE deposit_paid_at 
    END,
    progress_paid_at = CASE 
      WHEN v_progress_paid_after >= v_progress_due AND progress_paid_at IS NULL 
      THEN NOW() 
      ELSE progress_paid_at 
    END,
    final_paid_at = CASE 
      WHEN v_final_paid_after >= v_final_due AND final_paid_at IS NULL 
      THEN NOW() 
      ELSE final_paid_at 
    END,
    -- Update status based on payments (use correct format with spaces, not underscores)
    status = CASE
      WHEN v_total_paid_after >= v_proposal.total THEN 'completed'
      WHEN v_final_paid_after > 0 OR v_progress_paid_after >= v_progress_due THEN 'rough-in paid'
      WHEN v_deposit_paid_after >= v_deposit_due THEN 'deposit paid'
      ELSE status
    END
  WHERE id = NEW.proposal_id;
  
  -- Add a note about overflow in the payment record if it cascaded
  IF NEW.payment_stage = 'deposit' AND (v_progress_paid_after > v_progress_paid_before OR v_final_paid_after > v_final_paid_before) THEN
    UPDATE manual_payments
    SET notes = COALESCE(notes || ' | ', '') || 'Payment cascaded to next stage(s)'
    WHERE id = NEW.id;
  ELSIF NEW.payment_stage = 'progress' AND v_final_paid_after > v_final_paid_before THEN
    UPDATE manual_payments
    SET notes = COALESCE(notes || ' | ', '') || 'Payment cascaded to final stage'
    WHERE id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;