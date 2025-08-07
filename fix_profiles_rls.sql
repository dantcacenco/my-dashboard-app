-- Fix RLS policies for profiles table
-- Run this in Supabase SQL editor

-- First, check if profiles table has RLS enabled
SELECT 
  schemaname, 
  tablename, 
  rowsecurity 
FROM pg_tables 
WHERE tablename = 'profiles';

-- Drop any existing policies that might be blocking
DROP POLICY IF EXISTS "Profiles are viewable by users" ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;

-- Create a simple policy that allows users to read their own profile
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT
  USING (auth.uid() = id);

-- Also allow users to view profiles if they have a valid session
CREATE POLICY "Authenticated users can view profiles" ON profiles
  FOR SELECT
  USING (auth.role() = 'authenticated');

-- Verify the policies
SELECT * FROM pg_policies WHERE tablename = 'profiles';
