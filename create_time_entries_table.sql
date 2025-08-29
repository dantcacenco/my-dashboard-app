-- Create time_entries table for technician time tracking
-- Run this in your Supabase SQL editor

CREATE TABLE IF NOT EXISTS time_entries (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  technician_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX idx_time_entries_job_id ON time_entries(job_id);
CREATE INDEX idx_time_entries_technician_id ON time_entries(technician_id);
CREATE INDEX idx_time_entries_start_time ON time_entries(start_time);

-- Add RLS policies
ALTER TABLE time_entries ENABLE ROW LEVEL SECURITY;

-- Policy: Technicians can view their own time entries
CREATE POLICY "Technicians can view own time entries" ON time_entries
  FOR SELECT USING (auth.uid() = technician_id);

-- Policy: Technicians can insert their own time entries
CREATE POLICY "Technicians can insert own time entries" ON time_entries
  FOR INSERT WITH CHECK (auth.uid() = technician_id);

-- Policy: Technicians can update their own time entries
CREATE POLICY "Technicians can update own time entries" ON time_entries
  FOR UPDATE USING (auth.uid() = technician_id);

-- Policy: Admins can view all time entries
CREATE POLICY "Admins can view all time entries" ON time_entries
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND (profiles.role = 'admin' OR profiles.role = 'boss')
    )
  );

-- Add updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_time_entries_updated_at
  BEFORE UPDATE ON time_entries
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();