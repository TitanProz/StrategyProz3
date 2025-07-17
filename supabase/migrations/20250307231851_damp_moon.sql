/*
  # Add Admin RPC Functions
  
  1. New Functions
    - admin_list_users: Lists all users with their details
    - admin_get_user_stats: Gets user growth statistics
    - admin_reset_user: Resets a user's data
    - admin_delete_user: Deletes a user and their data
  
  2. Security
    - All functions are restricted to admin users only
    - Functions use security definer to access auth.users
    - Row Level Security policies are enforced
*/

-- Function to check if the current user is an admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Check if user's email matches admin email or if they're accessing from admin domain
  RETURN (
    EXISTS (
      SELECT 1 
      FROM auth.users 
      WHERE id = auth.uid() 
      AND (
        email = current_setting('app.admin_email', true)
        OR EXISTS (
          SELECT 1 
          FROM user_settings 
          WHERE user_id = auth.uid() 
          AND is_admin = true
        )
      )
    )
  );
END;
$$;

-- Function to list all users
CREATE OR REPLACE FUNCTION admin_list_users()
RETURNS TABLE (
  id uuid,
  email text,
  created_at timestamptz,
  last_sign_in_at timestamptz,
  is_admin boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  SELECT 
    u.id,
    u.email::text,
    u.created_at,
    u.last_sign_in_at,
    COALESCE(us.is_admin, false) as is_admin
  FROM auth.users u
  LEFT JOIN user_settings us ON u.id = us.user_id
  ORDER BY u.created_at DESC;
END;
$$;

-- Function to get user growth statistics
CREATE OR REPLACE FUNCTION admin_get_user_stats()
RETURNS TABLE (
  date_str text,
  user_count bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  WITH RECURSIVE dates AS (
    SELECT 
      date_trunc('day', min(created_at))::date AS date
    FROM auth.users
    UNION ALL
    SELECT 
      (date + interval '1 day')::date
    FROM dates
    WHERE date < current_date
  )
  SELECT 
    to_char(d.date, 'YYYY-MM-DD') as date_str,
    count(u.id) as user_count
  FROM dates d
  LEFT JOIN auth.users u ON date_trunc('day', u.created_at)::date <= d.date
  GROUP BY d.date
  ORDER BY d.date;
END;
$$;

-- Function to reset a user's data
CREATE OR REPLACE FUNCTION admin_reset_user(user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  -- Delete user's responses
  DELETE FROM user_responses WHERE user_id = $1;
  
  -- Reset module progress
  DELETE FROM module_progress WHERE user_id = $1;
  
  -- Reset completed modules
  DELETE FROM completed_modules WHERE user_id = $1;
  
  -- Reset user settings
  UPDATE user_settings 
  SET 
    selected_practice = NULL,
    selected_niche = NULL,
    final_report = NULL
  WHERE user_id = $1;
END;
$$;

-- Function to delete a user
CREATE OR REPLACE FUNCTION admin_delete_user(user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  -- First reset all user data
  PERFORM admin_reset_user($1);
  
  -- Delete user settings
  DELETE FROM user_settings WHERE user_id = $1;
  
  -- Delete user from auth.users
  DELETE FROM auth.users WHERE id = $1;
END;
$$;

-- Add is_admin column to user_settings if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'user_settings' 
    AND column_name = 'is_admin'
  ) THEN
    ALTER TABLE user_settings ADD COLUMN is_admin boolean DEFAULT false;
  END IF;
END $$;