#!/bin/bash

# Database connection details
DB_PASSWORD="sedho4-zebban-cAppoz"
DB_HOST="aws-0-us-west-1.pooler.supabase.com"
DB_NAME="postgres"
DB_USER="postgres.dqcxwekmehrqkigcufug"
DB_PORT="6543"

echo "🚀 Running time_entries migration..."
echo ""

# Using psql with the correct connection string
export PGPASSWORD="$DB_PASSWORD"

psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" << 'EOF'
-- Create time_entries table for technician time tracking
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
CREATE INDEX IF NOT EXISTS idx_time_entries_job_id ON time_entries(job_id);
CREATE INDEX IF NOT EXISTS idx_time_entries_technician_id ON time_entries(technician_id);
CREATE INDEX IF NOT EXISTS idx_time_entries_start_time ON time_entries(start_time);

-- Add RLS policies
ALTER TABLE time_entries ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Technicians can view own time entries" ON time_entries;
DROP POLICY IF EXISTS "Technicians can insert own time entries" ON time_entries;
DROP POLICY IF EXISTS "Technicians can update own time entries" ON time_entries;
DROP POLICY IF EXISTS "Admins can view all time entries" ON time_entries;

-- Create new policies
CREATE POLICY "Technicians can view own time entries" ON time_entries
  FOR SELECT USING (auth.uid() = technician_id);

CREATE POLICY "Technicians can insert own time entries" ON time_entries
  FOR INSERT WITH CHECK (auth.uid() = technician_id);

CREATE POLICY "Technicians can update own time entries" ON time_entries
  FOR UPDATE USING (auth.uid() = technician_id);

CREATE POLICY "Admins can view all time entries" ON time_entries
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND (profiles.role = 'admin' OR profiles.role = 'boss')
    )
  );

-- Create or replace the trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS \$\$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
\$\$ LANGUAGE plpgsql;

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS update_time_entries_updated_at ON time_entries;

-- Create trigger for time_entries
CREATE TRIGGER update_time_entries_updated_at
  BEFORE UPDATE ON time_entries
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Verify table was created
\dt time_entries
EOF

echo ""
echo "✅ Migration completed!"