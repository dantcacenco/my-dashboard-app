-- RLS Policies for Customer Token Access
-- Run this in Supabase SQL editor

-- Drop existing policies that might conflict
DROP POLICY IF EXISTS "Customers can view proposals via token" ON proposals;
DROP POLICY IF EXISTS "Customers can view proposal items via token" ON proposal_items;
DROP POLICY IF EXISTS "Customers can view activities via token" ON proposal_activities;

-- Create new policies for token-based access

-- 1. Allow customers to view proposals using customer_view_token
CREATE POLICY "Customers can view proposals via token" ON proposals
FOR SELECT
USING (
  -- Allow if the user has the correct token in the URL
  current_setting('request.headers', true)::json->>'x-proposal-token' = customer_view_token
  OR 
  -- Also allow regular authenticated users with proper roles
  auth.uid() IN (
    SELECT user_id FROM user_profiles 
    WHERE user_id = auth.uid() 
    AND role IN ('admin', 'boss', 'tech')
  )
);

-- 2. Allow customers to view proposal items for proposals they can access
CREATE POLICY "Customers can view proposal items via token" ON proposal_items
FOR SELECT
USING (
  proposal_id IN (
    SELECT id FROM proposals 
    WHERE current_setting('request.headers', true)::json->>'x-proposal-token' = customer_view_token
  )
  OR
  -- Also allow regular authenticated users
  auth.uid() IN (
    SELECT user_id FROM user_profiles 
    WHERE user_id = auth.uid() 
    AND role IN ('admin', 'boss', 'tech')
  )
);

-- 3. Allow customers to view activities for proposals they can access
CREATE POLICY "Customers can view activities via token" ON proposal_activities
FOR SELECT
USING (
  proposal_id IN (
    SELECT id FROM proposals 
    WHERE current_setting('request.headers', true)::json->>'x-proposal-token' = customer_view_token
  )
  OR
  -- Also allow regular authenticated users
  auth.uid() IN (
    SELECT user_id FROM user_profiles 
    WHERE user_id = auth.uid() 
    AND role IN ('admin', 'boss', 'tech')
  )
);

-- 4. Allow customers to update proposals (for approvals) via token
CREATE POLICY "Customers can update proposals via token" ON proposals
FOR UPDATE
USING (
  current_setting('request.headers', true)::json->>'x-proposal-token' = customer_view_token
  OR
  auth.uid() IN (
    SELECT user_id FROM user_profiles 
    WHERE user_id = auth.uid() 
    AND role IN ('admin', 'boss')
  )
)
WITH CHECK (
  current_setting('request.headers', true)::json->>'x-proposal-token' = customer_view_token
  OR
  auth.uid() IN (
    SELECT user_id FROM user_profiles 
    WHERE user_id = auth.uid() 
    AND role IN ('admin', 'boss')
  )
);

-- 5. Ensure customers table has proper RLS for viewing
DROP POLICY IF EXISTS "Customers viewable by proposal token" ON customers;
CREATE POLICY "Customers viewable by proposal token" ON customers
FOR SELECT
USING (
  id IN (
    SELECT customer_id FROM proposals 
    WHERE current_setting('request.headers', true)::json->>'x-proposal-token' = customer_view_token
  )
  OR
  auth.uid() IN (
    SELECT user_id FROM user_profiles 
    WHERE user_id = auth.uid() 
    AND role IN ('admin', 'boss', 'tech')
  )
);

-- Note: For this to work properly, you'll need to ensure your client code
-- sends the token as a header when making requests. This is typically done
-- in the Supabase client configuration.
