-- Create missing tables for complete functionality

-- Tasks table (individual work items)
CREATE TABLE IF NOT EXISTS tasks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  task_number TEXT UNIQUE NOT NULL,
  job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  task_type TEXT NOT NULL DEFAULT 'service_call',
  scheduled_date DATE NOT NULL,
  scheduled_start_time TIME NOT NULL,
  scheduled_end_time TIME,
  actual_start_time TIMESTAMPTZ,
  actual_end_time TIMESTAMPTZ,
  status TEXT DEFAULT 'scheduled',
  address TEXT,
  notes TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Task technician assignments (many-to-many)
CREATE TABLE IF NOT EXISTS task_technicians (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
  technician_id UUID REFERENCES profiles(id),
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  assigned_by UUID REFERENCES profiles(id),
  is_lead BOOLEAN DEFAULT FALSE,
  UNIQUE(task_id, technician_id)
);

-- Enhanced task time logs
CREATE TABLE IF NOT EXISTS task_time_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
  technician_id UUID REFERENCES profiles(id),
  log_date DATE NOT NULL,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ,
  total_hours NUMERIC,
  work_description TEXT,
  additional_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Task photos
CREATE TABLE IF NOT EXISTS task_photos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
  time_log_id UUID REFERENCES task_time_logs(id),
  uploaded_by UUID REFERENCES profiles(id),
  photo_url TEXT NOT NULL,
  thumbnail_url TEXT,
  caption TEXT,
  taken_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Job-Proposal junction table
CREATE TABLE IF NOT EXISTS job_proposals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
  proposal_id UUID REFERENCES proposals(id) ON DELETE CASCADE,
  attached_at TIMESTAMPTZ DEFAULT NOW(),
  attached_by UUID REFERENCES profiles(id),
  UNIQUE(job_id, proposal_id)
);

-- Job files table
CREATE TABLE IF NOT EXISTS job_files (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
  uploaded_by UUID REFERENCES profiles(id),
  file_name TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_size BIGINT,
  mime_type TEXT,
  is_visible_to_all BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Task types lookup table
CREATE TABLE IF NOT EXISTS task_types (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  type_name TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  color TEXT DEFAULT '#6B7280',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default task types if not exist
INSERT INTO task_types (type_name, display_name, color) 
VALUES 
  ('service_call', 'Service Call', '#3B82F6'),
  ('repair', 'Repair', '#EF4444'),
  ('maintenance', 'Maintenance', '#10B981'),
  ('rough_in', 'Rough In', '#F59E0B'),
  ('startup', 'Startup', '#8B5CF6'),
  ('meeting', 'Meeting', '#6B7280'),
  ('office', 'Office', '#EC4899')
ON CONFLICT (type_name) DO NOTHING;

-- Create storage buckets (run these in the storage section)
-- Note: These need to be created via Supabase dashboard or API
-- job-files bucket for documents
-- task-photos bucket for task photos

-- Enable RLS on new tables
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_technicians ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_time_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_proposals ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_types ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for tasks (everyone can read, boss/admin can write)
CREATE POLICY "Anyone can view tasks" ON tasks FOR SELECT USING (true);
CREATE POLICY "Boss/admin can manage tasks" ON tasks FOR ALL 
  USING (auth.uid() IN (SELECT id FROM profiles WHERE role IN ('boss', 'admin')));

-- Create RLS policies for task_technicians
CREATE POLICY "Anyone can view assignments" ON task_technicians FOR SELECT USING (true);
CREATE POLICY "Boss/admin can manage assignments" ON task_technicians FOR ALL 
  USING (auth.uid() IN (SELECT id FROM profiles WHERE role IN ('boss', 'admin')));

-- Create RLS policies for time logs (technicians can create their own)
CREATE POLICY "Anyone can view time logs" ON task_time_logs FOR SELECT USING (true);
CREATE POLICY "Technicians can create own time logs" ON task_time_logs FOR INSERT 
  WITH CHECK (auth.uid() = technician_id);
CREATE POLICY "Boss/admin can manage all time logs" ON task_time_logs FOR ALL 
  USING (auth.uid() IN (SELECT id FROM profiles WHERE role IN ('boss', 'admin')));

-- Add is_active column to profiles if not exists
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
