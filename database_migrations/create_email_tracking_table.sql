-- Create email_tracking table for monitoring Resend usage
-- This helps prevent hitting the 100/day and 3000/month limits

CREATE TABLE IF NOT EXISTS email_tracking (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  date DATE NOT NULL UNIQUE,
  count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create index for faster date lookups
CREATE INDEX IF NOT EXISTS idx_email_tracking_date ON email_tracking(date);

-- Add RLS policies
ALTER TABLE email_tracking ENABLE ROW LEVEL SECURITY;

-- Allow service role to manage tracking (for API routes)
CREATE POLICY "Service role can manage email tracking" ON email_tracking
  FOR ALL USING (true);

-- Optional: Create a function to get current usage
CREATE OR REPLACE FUNCTION get_email_usage()
RETURNS TABLE (
  today_count INTEGER,
  month_count INTEGER,
  today_remaining INTEGER,
  month_remaining INTEGER
) AS $$
DECLARE
  today_date DATE := CURRENT_DATE;
  month_start DATE := DATE_TRUNC('month', CURRENT_DATE);
  today_usage INTEGER;
  month_usage INTEGER;
BEGIN
  -- Get today's count
  SELECT COALESCE(count, 0) INTO today_usage
  FROM email_tracking
  WHERE date = today_date;
  
  -- Get month's total
  SELECT COALESCE(SUM(count), 0) INTO month_usage
  FROM email_tracking
  WHERE date >= month_start;
  
  RETURN QUERY SELECT 
    today_usage,
    month_usage::INTEGER,
    (100 - today_usage),
    (3000 - month_usage::INTEGER);
END;
$$ LANGUAGE plpgsql;

-- Optional: Create a view for dashboard
CREATE OR REPLACE VIEW email_usage_stats AS
SELECT 
  date,
  count,
  100 - count as remaining_today,
  CASE 
    WHEN count >= 90 THEN 'critical'
    WHEN count >= 75 THEN 'warning'
    ELSE 'normal'
  END as status
FROM email_tracking
WHERE date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY date DESC;