-- Fix RLS Policy for Profiles Table
-- Run this in Supabase SQL Editor

-- 1. First, check existing policies
SELECT * FROM pg_policies WHERE tablename = 'profiles';

-- 2. Drop restrictive policies if they exist
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Profiles are viewable by authenticated users" ON profiles;

-- 3. Create new policies that allow viewing technicians
-- Allow authenticated users to view all profiles (for job assignment)
CREATE POLICY "Authenticated users can view all profiles" 
ON profiles FOR SELECT 
TO authenticated 
USING (true);

-- Users can only update their own profile
CREATE POLICY "Users can update own profile" 
ON profiles FOR UPDATE 
TO authenticated 
USING (auth.uid() = id);

-- Boss/admin can update any profile
CREATE POLICY "Boss can update any profile" 
ON profiles FOR UPDATE 
TO authenticated 
USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() 
    AND role IN ('boss', 'admin')
  )
);

-- Boss/admin can insert profiles (for adding technicians)
CREATE POLICY "Boss can create profiles" 
ON profiles FOR INSERT 
TO authenticated 
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() 
    AND role IN ('boss', 'admin')
  )
);

-- 4. Verify the fix
SELECT * FROM profiles;
