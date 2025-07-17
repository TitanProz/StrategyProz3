/*
  # Fix permissions and admin function

  1. Security
    - Drop existing policies and function with CASCADE
    - Create admin check function
    - Enable RLS on tables
    - Add policies for authenticated users
    - Add admin policies

  2. Changes
    - Add RLS policies for user_settings, module_progress, user_responses
    - Add admin check function
    - Fix permissions for auth users table
*/

-- Drop existing policies and function with CASCADE
DROP POLICY IF EXISTS "Admins can view all settings" ON user_settings;
DROP POLICY IF EXISTS "Admins can view all progress" ON module_progress;
DROP POLICY IF EXISTS "Admins can view all responses" ON user_responses;
DROP POLICY IF EXISTS "Users can view their own settings" ON user_settings;
DROP POLICY IF EXISTS "Users can insert their own settings" ON user_settings;
DROP POLICY IF EXISTS "Users can update their own settings" ON user_settings;
DROP POLICY IF EXISTS "Users can view their own progress" ON module_progress;
DROP POLICY IF EXISTS "Users can insert their own progress" ON module_progress;
DROP POLICY IF EXISTS "Users can update their own progress" ON module_progress;
DROP POLICY IF EXISTS "Users can view their own responses" ON user_responses;
DROP POLICY IF EXISTS "Users can insert their own responses" ON user_responses;
DROP POLICY IF EXISTS "Users can update their own responses" ON user_responses;
DROP FUNCTION IF EXISTS is_admin(uuid) CASCADE;

-- Create admin check function
CREATE OR REPLACE FUNCTION is_admin(checking_uid uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = checking_uid 
    AND raw_user_meta_data->>'is_admin' = 'true'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS on all tables
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE module_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_responses ENABLE ROW LEVEL SECURITY;

-- User Settings policies
CREATE POLICY "Users can view their own settings"
  ON user_settings
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own settings"
  ON user_settings
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own settings"
  ON user_settings
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Module Progress policies
CREATE POLICY "Users can view their own progress"
  ON module_progress
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own progress"
  ON module_progress
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own progress"
  ON module_progress
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- User Responses policies
CREATE POLICY "Users can view their own responses"
  ON user_responses
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own responses"
  ON user_responses
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own responses"
  ON user_responses
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Admin policies
CREATE POLICY "Admins can view all settings"
  ON user_settings
  FOR SELECT
  TO authenticated
  USING (is_admin(auth.uid()));

CREATE POLICY "Admins can view all progress"
  ON module_progress
  FOR SELECT
  TO authenticated
  USING (is_admin(auth.uid()));

CREATE POLICY "Admins can view all responses"
  ON user_responses
  FOR SELECT
  TO authenticated
  USING (is_admin(auth.uid()));