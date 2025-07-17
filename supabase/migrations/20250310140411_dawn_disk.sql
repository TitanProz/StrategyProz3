/*
  # Fix RLS Policies

  1. Changes
    - Drop existing policies and functions
    - Create admin check function
    - Enable RLS on all tables
    - Add policies for authenticated users
    - Add policies for admins
    - Set up proper permissions and constraints

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users to access their own data
    - Add policies for admins to access all data
*/

-- First drop existing policies and functions
DROP POLICY IF EXISTS "Users can view their own settings" ON public.user_settings;
DROP POLICY IF EXISTS "Users can insert their own settings" ON public.user_settings;
DROP POLICY IF EXISTS "Users can update their own settings" ON public.user_settings;
DROP POLICY IF EXISTS "Admins can view all settings" ON public.user_settings;

DROP POLICY IF EXISTS "Users can view their own progress" ON public.module_progress;
DROP POLICY IF EXISTS "Users can insert their own progress" ON public.module_progress;
DROP POLICY IF EXISTS "Users can update their own progress" ON public.module_progress;
DROP POLICY IF EXISTS "Admins can view all progress" ON public.module_progress;

DROP POLICY IF EXISTS "Users can view their own responses" ON public.user_responses;
DROP POLICY IF EXISTS "Users can insert their own responses" ON public.user_responses;
DROP POLICY IF EXISTS "Users can update their own responses" ON public.user_responses;
DROP POLICY IF EXISTS "Admins can view all responses" ON public.user_responses;

DROP FUNCTION IF EXISTS public.check_is_admin CASCADE;
DROP FUNCTION IF EXISTS public.admin_delete_user CASCADE;

-- Create admin check function
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
      raw_app_meta_data->>'claims_admin' = 'true'
      OR email = current_setting('app.admin_email', true)
    )
  );
END;
$$;

-- Enable RLS on all tables
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.module_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_responses ENABLE ROW LEVEL SECURITY;

-- User Settings Policies
CREATE POLICY "Users can view their own settings"
  ON public.user_settings
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own settings"
  ON public.user_settings
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own settings"
  ON public.user_settings
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all settings"
  ON public.user_settings
  FOR SELECT
  TO authenticated
  USING (check_is_admin(auth.uid()));

-- Module Progress Policies
CREATE POLICY "Users can view their own progress"
  ON public.module_progress
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own progress"
  ON public.module_progress
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own progress"
  ON public.module_progress
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all progress"
  ON public.module_progress
  FOR SELECT
  TO authenticated
  USING (check_is_admin(auth.uid()));

-- User Responses Policies
CREATE POLICY "Users can view their own responses"
  ON public.user_responses
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own responses"
  ON public.user_responses
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own responses"
  ON public.user_responses
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all responses"
  ON public.user_responses
  FOR SELECT
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

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT SELECT ON auth.users TO authenticated;

-- Add foreign key constraints with cascading deletes
ALTER TABLE public.user_settings
  DROP CONSTRAINT IF EXISTS user_settings_user_id_fkey,
  ADD CONSTRAINT user_settings_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES auth.users(id)
  ON DELETE CASCADE;

ALTER TABLE public.module_progress
  DROP CONSTRAINT IF EXISTS module_progress_user_id_fkey,
  ADD CONSTRAINT module_progress_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES auth.users(id)
  ON DELETE CASCADE;

ALTER TABLE public.user_responses
  DROP CONSTRAINT IF EXISTS user_responses_user_id_fkey,
  ADD CONSTRAINT user_responses_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES auth.users(id)
  ON DELETE CASCADE;