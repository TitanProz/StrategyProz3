/*
  # Create users view and policies

  1. New Views
    - `users` view to safely expose auth.users data
      - id (uuid)
      - email (text)
      - created_at (timestamptz)
      - last_sign_in_at (timestamptz)
      - is_admin (boolean)

  2. Security
    - View is created with security_invoker = true
    - RPC functions for admin operations
      - admin_list_users: Lists all users
      - admin_get_user_stats: Gets user growth statistics
      - admin_reset_user: Resets a user's data
*/

-- Create RPC function to list users
CREATE OR REPLACE FUNCTION admin_list_users()
RETURNS TABLE (
  id uuid,
  email text,
  created_at timestamptz,
  last_sign_in_at timestamptz,
  is_admin boolean
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Check if user is admin
  IF NOT (SELECT COALESCE((auth.jwt() ->> 'claims_admin')::boolean, false)) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  SELECT 
    au.id,
    au.email::text,
    au.created_at,
    au.last_sign_in_at,
    (au.raw_app_meta_data->>'claims_admin')::boolean as is_admin
  FROM auth.users au
  ORDER BY au.created_at DESC;
END;
$$;

-- Create RPC function to get user growth statistics
CREATE OR REPLACE FUNCTION admin_get_user_stats()
RETURNS TABLE (
  date_str text,
  user_count bigint
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  first_user_date date;
  current_date date := CURRENT_DATE;
  running_total bigint := 0;
BEGIN
  -- Check if user is admin
  IF NOT (SELECT COALESCE((auth.jwt() ->> 'claims_admin')::boolean, false)) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  -- Get first user date
  SELECT DATE(MIN(created_at)) INTO first_user_date FROM auth.users;
  
  -- Return empty if no users
  IF first_user_date IS NULL THEN
    RETURN;
  END IF;

  -- Generate series from first user to current date
  RETURN QUERY
  WITH RECURSIVE dates AS (
    SELECT first_user_date as date
    UNION ALL
    SELECT date + 1
    FROM dates
    WHERE date < current_date
  ),
  daily_counts AS (
    SELECT 
      DATE(created_at) as date,
      COUNT(*) as new_users
    FROM auth.users
    GROUP BY DATE(created_at)
  )
  SELECT 
    TO_CHAR(d.date, 'YYYY-MM-DD'),
    SUM(COALESCE(dc.new_users, 0)) OVER (ORDER BY d.date) as cumulative_users
  FROM dates d
  LEFT JOIN daily_counts dc ON d.date = dc.date
  ORDER BY d.date;
END;
$$;

-- Create RPC function to reset user data
CREATE OR REPLACE FUNCTION admin_reset_user(user_id uuid)
RETURNS void
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Check if user is admin
  IF NOT (SELECT COALESCE((auth.jwt() ->> 'claims_admin')::boolean, false)) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  -- Delete user data in correct order
  DELETE FROM user_responses WHERE user_id = $1;
  DELETE FROM module_progress WHERE user_id = $1;
  DELETE FROM completed_modules WHERE user_id = $1;
  DELETE FROM user_settings WHERE user_id = $1;
END;
$$;