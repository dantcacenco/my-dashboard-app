-- Fix RLS Policies for Profiles Table
-- Run this entire script in Supabase SQL Editor

-- 1. Drop ALL existing restrictive policies
DROP POLICY IF EXISTS "Authenticated users can view profiles" ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "users_update_own_profile" ON profiles;
DROP POLICY IF EXISTS "users_view_own_profile" ON profiles;

-- 2. Create new, better policies

-- Allow ALL authenticated users to view ALL profiles (needed for technician assignment)
CREATE POLICY "Anyone authenticated can view all profiles" 
ON profiles FOR SELECT 
TO authenticated 
USING (true);

-- Users can only update their own profile
CREATE POLICY "Users update own profile only" 
ON profiles FOR UPDATE 
TO authenticated 
USING (auth.uid() = id);

-- Boss/admin can insert new profiles
CREATE POLICY "Boss admin can create profiles" 
ON profiles FOR INSERT 
TO authenticated 
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() 
    AND role IN ('boss', 'admin')
  )
);

-- Boss/admin can delete profiles
CREATE POLICY "Boss admin can delete profiles" 
ON profiles FOR DELETE 
TO authenticated 
USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() 
    AND role IN ('boss', 'admin')
  )
);

-- 3. Verify the policies are correct
SELECT * FROM pg_policies WHERE tablename = 'profiles';

-- 4. Test that you can now see all profiles
SELECT id, email, full_name, role, is_active 
FROM profiles 
ORDER BY role, full_name;
