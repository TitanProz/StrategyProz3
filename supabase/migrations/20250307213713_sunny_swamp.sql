/*
  # Fix Admin User Functions
  
  1. Changes
    - Drop existing functions to avoid return type conflicts
    - Recreate admin functions with proper schema references
    - Add proper security checks and error handling
  
  2. Security
    - Functions are security definer to access auth schema
    - Proper admin role checks
*/

-- Drop existing functions if they exist
DROP FUNCTION IF EXISTS admin_list_users();
DROP FUNCTION IF EXISTS admin_get_user_stats();

-- Function to list all users (admin only)
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
  IF NOT (SELECT EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND raw_app_meta_data->>'claims_admin' = 'true'
  )) THEN
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

-- Function to get user growth statistics (admin only)
CREATE OR REPLACE FUNCTION admin_get_user_stats()
RETURNS TABLE (
  date_str text,
  user_count bigint
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Check if user is admin
  IF NOT (SELECT EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND raw_app_meta_data->>'claims_admin' = 'true'
  )) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  WITH RECURSIVE dates AS (
    SELECT date_trunc('day', min(created_at))::date AS date
    FROM auth.users
    UNION ALL
    SELECT (date + interval '1 day')::date
    FROM dates
    WHERE date < current_date
  ),
  daily_counts AS (
    SELECT 
      date_trunc('day', created_at)::date as join_date,
      count(*) as new_users
    FROM auth.users
    GROUP BY 1
  )
  SELECT 
    to_char(d.date, 'YYYY-MM-DD') as date_str,
    sum(coalesce(dc.new_users, 0)) OVER (ORDER BY d.date) as user_count
  FROM dates d
  LEFT JOIN daily_counts dc ON d.date = dc.join_date
  ORDER BY d.date;
END;
$$;