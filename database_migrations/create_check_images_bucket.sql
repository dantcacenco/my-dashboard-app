-- Create storage bucket for check images
-- Run this in Supabase SQL Editor

-- Create the bucket
INSERT INTO storage.buckets (id, name, public, avif_autodetection, file_size_limit, allowed_mime_types)
VALUES (
  'check-images',
  'check-images', 
  true, -- Public bucket so we can display images
  false,
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']::text[]
)
ON CONFLICT (id) DO NOTHING;

-- Set up RLS policies
CREATE POLICY "Authenticated users can upload check images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'check-images');

CREATE POLICY "Anyone can view check images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'check-images');

CREATE POLICY "Authenticated users can update their check images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'check-images')
WITH CHECK (bucket_id = 'check-images');

CREATE POLICY "Authenticated users can delete check images"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'check-images');

-- Add total_paid column to proposals if it doesn't exist
ALTER TABLE proposals 
ADD COLUMN IF NOT EXISTS total_paid DECIMAL(10,2) DEFAULT 0;

-- Create an improved trigger for payment recording with overpayment handling
CREATE OR REPLACE FUNCTION update_proposal_on_manual_payment_improved()
RETURNS TRIGGER AS $$
DECLARE
  v_proposal RECORD;
  v_remaining_amount DECIMAL(10,2);
  v_deposit_due DECIMAL(10,2);
  v_progress_due DECIMAL(10,2);
  v_final_due DECIMAL(10,2);
  v_deposit_paid DECIMAL(10,2);
  v_progress_paid DECIMAL(10,2);
  v_final_paid DECIMAL(10,2);
BEGIN
  -- Get current proposal details
  SELECT * INTO v_proposal FROM proposals WHERE id = NEW.proposal_id;
  
  -- Calculate what's due for each stage
  v_deposit_due := COALESCE(v_proposal.deposit_amount, v_proposal.total * 0.5);
  v_progress_due := COALESCE(v_proposal.progress_payment_amount, v_proposal.total * 0.3);
  v_final_due := COALESCE(v_proposal.final_payment_amount, v_proposal.total * 0.2);
  
  -- Get current payments for each stage
  SELECT 
    COALESCE(SUM(CASE WHEN payment_stage = 'deposit' THEN amount ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN payment_stage = 'progress' THEN amount ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN payment_stage = 'final' THEN amount ELSE 0 END), 0)
  INTO v_deposit_paid, v_progress_paid, v_final_paid
  FROM manual_payments
  WHERE proposal_id = NEW.proposal_id;
  
  -- Also add Stripe payments if any
  -- (This would need to check stripe_payments table if it exists)
  
  -- Update proposal based on total payments
  UPDATE proposals
  SET 
    total_paid = v_deposit_paid + v_progress_paid + v_final_paid,
    -- Set payment timestamps when stage is fully paid
    deposit_paid_at = CASE 
      WHEN v_deposit_paid >= v_deposit_due AND deposit_paid_at IS NULL 
      THEN NOW() 
      ELSE deposit_paid_at 
    END,
    progress_paid_at = CASE 
      WHEN v_progress_paid >= v_progress_due AND progress_paid_at IS NULL 
      THEN NOW() 
      ELSE progress_paid_at 
    END,
    final_paid_at = CASE 
      WHEN v_final_paid >= v_final_due AND final_paid_at IS NULL 
      THEN NOW() 
      ELSE final_paid_at 
    END,
    -- Update status based on payments
    status = CASE
      WHEN v_deposit_paid + v_progress_paid + v_final_paid >= v_proposal.total THEN 'final_paid'
      WHEN v_progress_paid >= v_progress_due THEN 'progress_paid'
      WHEN v_deposit_paid >= v_deposit_due THEN 'deposit_paid'
      ELSE status
    END
  WHERE id = NEW.proposal_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop old trigger if exists
DROP TRIGGER IF EXISTS trigger_manual_payment_update_proposal ON manual_payments;

-- Create new trigger
CREATE TRIGGER trigger_manual_payment_update_proposal_improved
AFTER INSERT OR UPDATE ON manual_payments
FOR EACH ROW
EXECUTE FUNCTION update_proposal_on_manual_payment_improved();