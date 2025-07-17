/*
  # Fix Admin Access to User Responses

  1. Changes
    - Add admin policies for viewing all user responses
    - Fix RLS policies to properly handle admin access
    - Ensure proper access to user data for admins

  2. Security
    - Maintain existing user security
    - Add proper admin access controls
*/

-- Drop existing admin policies if they exist
DROP POLICY IF EXISTS "Admins can view all responses" ON user_responses;
DROP POLICY IF EXISTS "Admins can view all user settings" ON user_settings;

-- Create new admin policies with proper checks
CREATE POLICY "Admins can view all responses"
  ON user_responses
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = auth.uid() 
      AND (
        raw_user_meta_data->>'claims_admin' = 'true'
        OR email = 'admin@strategyproz.com'
      )
    )
  );

CREATE POLICY "Admins can view all user settings"
  ON user_settings
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = auth.uid() 
      AND (
        raw_user_meta_data->>'claims_admin' = 'true'
        OR email = 'admin@strategyproz.com'
      )
    )
  );