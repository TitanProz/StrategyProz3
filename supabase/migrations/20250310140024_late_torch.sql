/*
  # Fix RLS Policies and Functions

  1. Changes
    - Drop existing policies and functions with CASCADE
    - Create admin check function with unique name
    - Enable RLS on all tables
    - Create new policies with proper user checks
    - Add admin policies for viewing all data

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users to manage their own data
    - Add policies for admins to view all data
    - Use proper security definer function for admin checks
*/

-- First drop everything with CASCADE to clean up
DROP POLICY IF EXISTS "Users can view their own settings" ON user_settings CASCADE;
DROP POLICY IF EXISTS "Users can insert their own settings" ON user_settings CASCADE;
DROP POLICY IF EXISTS "Users can update their own settings" ON user_settings CASCADE;
DROP POLICY IF EXISTS "Users can view their own progress" ON module_progress CASCADE;
DROP POLICY IF EXISTS "Users can insert their own progress" ON module_progress CASCADE;
DROP POLICY IF EXISTS "Users can update their own progress" ON module_progress CASCADE;
DROP POLICY IF EXISTS "Users can view their own responses" ON user_responses CASCADE;
DROP POLICY IF EXISTS "Users can insert their own responses" ON user_responses CASCADE;
DROP POLICY IF EXISTS "Users can update their own responses" ON user_responses CASCADE;
DROP POLICY IF EXISTS "Admins can view all settings" ON user_settings CASCADE;
DROP POLICY IF EXISTS "Admins can view all progress" ON module_progress CASCADE;
DROP POLICY IF EXISTS "Admins can view all responses" ON user_responses CASCADE;

-- Create admin check function with unique name and proper permissions
CREATE OR REPLACE FUNCTION public.check_is_admin(checking_uid uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = checking_uid 
    AND (
      raw_user_meta_data->>'is_admin' = 'true'
      OR email = 'admin@strategyproz.com'
    )
  );
END;
$$;

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
  USING (check_is_admin(auth.uid()));

CREATE POLICY "Admins can view all progress"
  ON module_progress
  FOR SELECT
  TO authenticated
  USING (check_is_admin(auth.uid()));

CREATE POLICY "Admins can view all responses"
  ON user_responses
  FOR SELECT
  TO authenticated
  USING (check_is_admin(auth.uid()));

-- Add admin delete function
CREATE OR REPLACE FUNCTION public.admin_delete_user(user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT check_is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Permission denied';
  END IF;

  -- Delete all user data
  DELETE FROM user_responses WHERE user_id = $1;
  DELETE FROM module_progress WHERE user_id = $1;
  DELETE FROM completed_modules WHERE user_id = $1;
  DELETE FROM user_settings WHERE user_id = $1;
  
  -- Delete the user from auth.users
  DELETE FROM auth.users WHERE id = $1;
END;
$$;