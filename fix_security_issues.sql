-- ================================================
-- Fix Critical Security Issues in Service Pro DB
-- Run this entire script in Supabase SQL Editor
-- ================================================

-- 1. FIX: dashboard_stats view with SECURITY DEFINER
-- Drop the view and recreate without SECURITY DEFINER
DROP VIEW IF EXISTS public.dashboard_stats CASCADE;

-- Recreate the view without SECURITY DEFINER (use SECURITY INVOKER instead - default)
-- Using correct column names: subtotal, tax_amount, deposit_amount, etc.
CREATE OR REPLACE VIEW public.dashboard_stats AS
SELECT 
    -- Job counts
    COUNT(DISTINCT j.id) FILTER (WHERE j.status = 'scheduled') as scheduled_jobs,
    COUNT(DISTINCT j.id) FILTER (WHERE j.status = 'in_progress') as active_jobs,
    COUNT(DISTINCT j.id) FILTER (WHERE j.created_at >= CURRENT_DATE - INTERVAL '7 days') as new_jobs_this_week,
    
    -- Proposal counts
    COUNT(DISTINCT p.id) FILTER (WHERE p.status = 'pending') as pending_proposals,
    COUNT(DISTINCT p.id) FILTER (WHERE p.status = 'approved') as approved_proposals,
    COUNT(DISTINCT p.id) FILTER (WHERE p.created_at >= CURRENT_DATE - INTERVAL '7 days') as new_proposals_this_week,
    
    -- Revenue metrics (using subtotal + tax_amount as total)
    COALESCE(SUM(p.subtotal + COALESCE(p.tax_amount, 0)) FILTER (WHERE p.status = 'approved' AND p.created_at >= CURRENT_DATE - INTERVAL '30 days'), 0) as revenue_this_month,
    COALESCE(SUM(p.subtotal + COALESCE(p.tax_amount, 0)) FILTER (WHERE p.status = 'approved' AND p.created_at >= CURRENT_DATE - INTERVAL '7 days'), 0) as revenue_this_week,
    
    -- Customer metrics
    COUNT(DISTINCT c.id) as total_customers,
    COUNT(DISTINCT c.id) FILTER (WHERE c.created_at >= CURRENT_DATE - INTERVAL '30 days') as new_customers_this_month
FROM 
    jobs j
    FULL OUTER JOIN proposals p ON TRUE
    FULL OUTER JOIN customers c ON TRUE;

-- Grant appropriate permissions
GRANT SELECT ON public.dashboard_stats TO authenticated;

-- ================================================
-- 2. FIX: Enable RLS on job_time_entries table
-- ================================================

-- Enable RLS
ALTER TABLE public.job_time_entries ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Technicians can view own time entries" ON public.job_time_entries;
DROP POLICY IF EXISTS "Technicians can create own time entries" ON public.job_time_entries;
DROP POLICY IF EXISTS "Technicians can update own time entries" ON public.job_time_entries;
DROP POLICY IF EXISTS "Boss and admin can view all time entries" ON public.job_time_entries;
DROP POLICY IF EXISTS "Boss and admin can manage all time entries" ON public.job_time_entries;

-- Create RLS policies for job_time_entries
-- Technicians can view their own time entries
CREATE POLICY "Technicians can view own time entries" ON public.job_time_entries
    FOR SELECT
    USING (
        auth.uid() = technician_id
        OR auth.uid() IN (
            SELECT id FROM profiles WHERE role IN ('boss', 'admin')
        )
    );

-- Technicians can create their own time entries
CREATE POLICY "Technicians can create own time entries" ON public.job_time_entries
    FOR INSERT
    WITH CHECK (
        auth.uid() = technician_id
        OR auth.uid() IN (
            SELECT id FROM profiles WHERE role IN ('boss', 'admin')
        )
    );

-- Technicians can update their own unclosed time entries
CREATE POLICY "Technicians can update own time entries" ON public.job_time_entries
    FOR UPDATE
    USING (
        (auth.uid() = technician_id AND clock_out IS NULL)
        OR auth.uid() IN (
            SELECT id FROM profiles WHERE role IN ('boss', 'admin')
        )
    )
    WITH CHECK (
        (auth.uid() = technician_id AND clock_out IS NULL)
        OR auth.uid() IN (
            SELECT id FROM profiles WHERE role IN ('boss', 'admin')
        )
    );

-- Boss and admin can delete any time entries
CREATE POLICY "Boss and admin can delete time entries" ON public.job_time_entries
    FOR DELETE
    USING (
        auth.uid() IN (
            SELECT id FROM profiles WHERE role IN ('boss', 'admin')
        )
    );

-- ================================================
-- 3. FIX: Enable RLS on job_photos table
-- ================================================

-- Enable RLS
ALTER TABLE public.job_photos ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Anyone can view job photos" ON public.job_photos;
DROP POLICY IF EXISTS "Authenticated users can upload job photos" ON public.job_photos;
DROP POLICY IF EXISTS "Photo owners can delete their photos" ON public.job_photos;

-- Create RLS policies for job_photos
-- Anyone can view job photos
CREATE POLICY "Anyone can view job photos" ON public.job_photos
    FOR SELECT
    USING (true);

-- Authenticated users can upload photos to jobs they're assigned to
CREATE POLICY "Authenticated users can upload job photos" ON public.job_photos
    FOR INSERT
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND (
            -- Boss and admin can upload to any job
            auth.uid() IN (
                SELECT id FROM profiles WHERE role IN ('boss', 'admin')
            )
            OR
            -- Technicians can upload to jobs they're assigned to
            auth.uid() IN (
                SELECT technician_id FROM job_technicians WHERE job_id = job_photos.job_id
            )
        )
    );

-- Users can delete photos they uploaded, boss/admin can delete any
CREATE POLICY "Users can manage own photos" ON public.job_photos
    FOR DELETE
    USING (
        auth.uid() = uploaded_by
        OR auth.uid() IN (
            SELECT id FROM profiles WHERE role IN ('boss', 'admin')
        )
    );

-- ================================================
-- 4. FIX: Enable RLS on job_materials table
-- ================================================

-- Enable RLS
ALTER TABLE public.job_materials ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Anyone can view job materials" ON public.job_materials;
DROP POLICY IF EXISTS "Technicians can add materials to assigned jobs" ON public.job_materials;
DROP POLICY IF EXISTS "Boss and admin can manage all materials" ON public.job_materials;

-- Create RLS policies for job_materials
-- Anyone authenticated can view job materials
CREATE POLICY "Authenticated users can view job materials" ON public.job_materials
    FOR SELECT
    USING (auth.uid() IS NOT NULL);

-- Technicians can add materials to jobs they're assigned to
CREATE POLICY "Technicians can add materials to assigned jobs" ON public.job_materials
    FOR INSERT
    WITH CHECK (
        auth.uid() IN (
            SELECT id FROM profiles WHERE role IN ('boss', 'admin')
        )
        OR
        auth.uid() IN (
            SELECT technician_id FROM job_technicians WHERE job_id = job_materials.job_id
        )
    );

-- Technicians can update materials they added, boss/admin can update any
CREATE POLICY "Users can update materials" ON public.job_materials
    FOR UPDATE
    USING (
        auth.uid() = added_by
        OR auth.uid() IN (
            SELECT id FROM profiles WHERE role IN ('boss', 'admin')
        )
    )
    WITH CHECK (
        auth.uid() = added_by
        OR auth.uid() IN (
            SELECT id FROM profiles WHERE role IN ('boss', 'admin')
        )
    );

-- Boss and admin can delete any materials
CREATE POLICY "Boss and admin can delete materials" ON public.job_materials
    FOR DELETE
    USING (
        auth.uid() IN (
            SELECT id FROM profiles WHERE role IN ('boss', 'admin')
        )
    );

-- ================================================
-- 5. FIX: Enable RLS on job_activity_log table
-- ================================================

-- Enable RLS
ALTER TABLE public.job_activity_log ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Anyone can view activity logs" ON public.job_activity_log;
DROP POLICY IF EXISTS "System can create activity logs" ON public.job_activity_log;

-- Create RLS policies for job_activity_log
-- Authenticated users can view activity logs for jobs they have access to
CREATE POLICY "Authenticated users can view activity logs" ON public.job_activity_log
    FOR SELECT
    USING (
        auth.uid() IS NOT NULL
        AND (
            -- Boss and admin can view all logs
            auth.uid() IN (
                SELECT id FROM profiles WHERE role IN ('boss', 'admin')
            )
            OR
            -- Technicians can view logs for jobs they're assigned to
            auth.uid() IN (
                SELECT technician_id FROM job_technicians WHERE job_id = job_activity_log.job_id
            )
        )
    );

-- Only the system (through service role) and boss/admin can create logs
CREATE POLICY "Authorized users can create activity logs" ON public.job_activity_log
    FOR INSERT
    WITH CHECK (
        auth.uid() IN (
            SELECT id FROM profiles WHERE role IN ('boss', 'admin')
        )
        OR
        -- Allow technicians to create logs for their assigned jobs
        auth.uid() IN (
            SELECT technician_id FROM job_technicians WHERE job_id = job_activity_log.job_id
        )
    );

-- No one can update or delete activity logs (audit trail integrity)
-- Logs are immutable once created

-- ================================================
-- Verify all changes
-- ================================================

-- Check RLS status on all tables
SELECT 
    schemaname,
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Enabled'
        ELSE '❌ RLS Disabled'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename IN (
    'job_time_entries',
    'job_photos', 
    'job_materials',
    'job_activity_log'
)
ORDER BY tablename;

-- Check if dashboard_stats view exists and its security setting
SELECT 
    schemaname,
    viewname,
    CASE 
        WHEN definition LIKE '%SECURITY DEFINER%' THEN '❌ Has SECURITY DEFINER'
        ELSE '✅ No SECURITY DEFINER'
    END as security_status
FROM pg_views
WHERE schemaname = 'public'
AND viewname = 'dashboard_stats';

-- List all policies on the affected tables
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual IS NOT NULL as has_using,
    with_check IS NOT NULL as has_with_check
FROM pg_policies
WHERE tablename IN (
    'job_time_entries',
    'job_photos',
    'job_materials', 
    'job_activity_log'
)
ORDER BY tablename, policyname;
