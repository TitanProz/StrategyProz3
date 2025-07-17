/*
  # Fix Database Permissions and Policies

  1. Changes
    - Create secure users view
    - Set up admin check function
    - Enable RLS on all tables
    - Create policies for user access control
    - Add admin delete function

  2. Security
    - Restrict direct access to auth.users
    - Ensure proper RLS enforcement
    - Add secure admin functions
*/

-- Create a secure view for accessing user data
CREATE OR REPLACE VIEW public.users AS
SELECT 
  id,
  email,
  created_at,
  last_sign_in_at,
  raw_app_meta_data->>'claims_admin' as is_admin
FROM auth.users;

-- Grant access to the view
GRANT SELECT ON public.users TO authenticated;

-- Update admin check function to use claims_admin
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
    AND raw_app_meta_data->>'claims_admin' = 'true'
  );
END;
$$;

-- Enable RLS on all tables
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.module_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.completed_modules ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DO $$ 
BEGIN
  -- User Settings
  DROP POLICY IF EXISTS "Users can view their own settings" ON public.user_settings;
  DROP POLICY IF EXISTS "Users can insert their own settings" ON public.user_settings;
  DROP POLICY IF EXISTS "Users can update their own settings" ON public.user_settings;
  DROP POLICY IF EXISTS "Admins can view all settings" ON public.user_settings;

  -- Module Progress
  DROP POLICY IF EXISTS "Users can view their own progress" ON public.module_progress;
  DROP POLICY IF EXISTS "Users can insert their own progress" ON public.module_progress;
  DROP POLICY IF EXISTS "Users can update their own progress" ON public.module_progress;
  DROP POLICY IF EXISTS "Admins can view all progress" ON public.module_progress;

  -- User Responses
  DROP POLICY IF EXISTS "Users can view their own responses" ON public.user_responses;
  DROP POLICY IF EXISTS "Users can insert their own responses" ON public.user_responses;
  DROP POLICY IF EXISTS "Users can update their own responses" ON public.user_responses;
  DROP POLICY IF EXISTS "Admins can view all responses" ON public.user_responses;

  -- Completed Modules
  DROP POLICY IF EXISTS "Users can view their completed modules" ON public.completed_modules;
  DROP POLICY IF EXISTS "Users can insert completed modules" ON public.completed_modules;
  DROP POLICY IF EXISTS "Users can delete their completed modules" ON public.completed_modules;
  DROP POLICY IF EXISTS "Admins can view all completed modules" ON public.completed_modules;
END $$;

-- Create new policies

-- User Settings policies
CREATE POLICY "Users can view their own settings"
  ON public.user_settings FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own settings"
  ON public.user_settings FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own settings"
  ON public.user_settings FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all settings"
  ON public.user_settings FOR SELECT
  TO authenticated
  USING (check_is_admin(auth.uid()));

-- Module Progress policies
CREATE POLICY "Users can view their own progress"
  ON public.module_progress FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own progress"
  ON public.module_progress FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own progress"
  ON public.module_progress FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all progress"
  ON public.module_progress FOR SELECT
  TO authenticated
  USING (check_is_admin(auth.uid()));

-- User Responses policies
CREATE POLICY "Users can view their own responses"
  ON public.user_responses FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own responses"
  ON public.user_responses FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own responses"
  ON public.user_responses FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all responses"
  ON public.user_responses FOR SELECT
  TO authenticated
  USING (check_is_admin(auth.uid()));

-- Completed Modules policies
CREATE POLICY "Users can view their completed modules"
  ON public.completed_modules FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert completed modules"
  ON public.completed_modules FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their completed modules"
  ON public.completed_modules FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all completed modules"
  ON public.completed_modules FOR SELECT
  TO authenticated
  USING (check_is_admin(auth.uid()));

-- Add admin delete function with proper permissions
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

  -- Delete all user data (cascading will handle foreign key relationships)
  DELETE FROM auth.users WHERE id = user_id;
END;
$$;