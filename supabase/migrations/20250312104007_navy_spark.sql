/*
  # Fix Admin Access to User Data
  
  1. Changes
    - Drop and recreate all admin-related policies
    - Add comprehensive admin access policies
    - Fix admin authentication checks
    - Ensure proper access to all user data tables
    
  2. Security
    - Maintain existing user security
    - Add proper admin access controls
    - Use consistent admin verification
*/

-- First drop all existing admin policies
DROP POLICY IF EXISTS "Admins can view all responses" ON user_responses;
DROP POLICY IF EXISTS "Admins can view all settings" ON user_settings;
DROP POLICY IF EXISTS "Admins can view all progress" ON module_progress;
DROP POLICY IF EXISTS "Admins can view all completed modules" ON completed_modules;

-- Create function to check admin status
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = auth.uid() 
    AND (
      raw_user_meta_data->>'claims_admin' = 'true'
      OR email = 'admin@strategyproz.com'
    )
  );
END;
$$;

-- Create comprehensive admin policies for all relevant tables
CREATE POLICY "Admins can view all responses"
  ON user_responses
  FOR ALL
  TO authenticated
  USING (is_admin());

CREATE POLICY "Admins can view all settings"
  ON user_settings
  FOR ALL
  TO authenticated
  USING (is_admin());

CREATE POLICY "Admins can view all progress"
  ON module_progress
  FOR ALL
  TO authenticated
  USING (is_admin());

CREATE POLICY "Admins can view all completed modules"
  ON completed_modules
  FOR ALL
  TO authenticated
  USING (is_admin());

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_user_responses_user_id ON user_responses(user_id);
CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON user_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_module_progress_user_id ON module_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_completed_modules_user_id ON completed_modules(user_id);