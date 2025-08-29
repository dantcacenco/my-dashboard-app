-- Manual payment recording for cash/check
CREATE TABLE IF NOT EXISTS manual_payments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  proposal_id UUID REFERENCES proposals(id),
  payment_stage VARCHAR(50), -- 'deposit', 'progress', 'final'
  amount DECIMAL(10,2),
  payment_method VARCHAR(50), -- 'cash', 'check', 'other'
  check_number VARCHAR(100),
  payment_date DATE DEFAULT CURRENT_DATE,
  recorded_by UUID REFERENCES profiles(id),
  notes TEXT,
  check_image_url TEXT, -- URL to uploaded check image
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Add index for faster lookups
CREATE INDEX idx_manual_payments_proposal ON manual_payments(proposal_id);
CREATE INDEX idx_manual_payments_date ON manual_payments(payment_date);

-- Add trigger to update proposal payment status
CREATE OR REPLACE FUNCTION update_proposal_on_manual_payment()
RETURNS TRIGGER AS $$
BEGIN
  -- Update the appropriate payment timestamp based on stage
  IF NEW.payment_stage = 'deposit' THEN
    UPDATE proposals 
    SET deposit_paid_at = NOW(),
        total_paid = COALESCE(total_paid, 0) + NEW.amount
    WHERE id = NEW.proposal_id;
  ELSIF NEW.payment_stage = 'progress' THEN
    UPDATE proposals 
    SET progress_paid_at = NOW(),
        total_paid = COALESCE(total_paid, 0) + NEW.amount
    WHERE id = NEW.proposal_id;
  ELSIF NEW.payment_stage = 'final' THEN
    UPDATE proposals 
    SET final_paid_at = NOW(),
        total_paid = COALESCE(total_paid, 0) + NEW.amount
    WHERE id = NEW.proposal_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_manual_payment_update_proposal
AFTER INSERT ON manual_payments
FOR EACH ROW
EXECUTE FUNCTION update_proposal_on_manual_payment();