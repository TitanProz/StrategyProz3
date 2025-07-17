/*
  # Fix admin functionality

  1. Changes
    - Add admin function to list users
    - Add admin function to delete users
    - Add admin function to reset user data
    - Add admin function to get user stats

  2. Security
    - All functions are security definer
    - Access restricted to admin users only
*/

-- Create admin function to list users
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
  IF NOT EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = auth.uid() 
    AND raw_user_meta_data->>'is_admin' = 'true'
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  SELECT 
    u.id,
    u.email::text,
    u.created_at,
    u.last_sign_in_at,
    (u.raw_user_meta_data->>'is_admin')::boolean as is_admin
  FROM auth.users u;
END;
$$;

-- Create admin function to delete user
CREATE OR REPLACE FUNCTION admin_delete_user(user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = auth.uid() 
    AND raw_user_meta_data->>'is_admin' = 'true'
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  -- Delete user data
  DELETE FROM user_responses WHERE user_id = $1;
  DELETE FROM module_progress WHERE user_id = $1;
  DELETE FROM messages WHERE sender_id = $1 OR recipient_id = $1;
END;
$$;

-- Create admin function to reset user data
CREATE OR REPLACE FUNCTION admin_reset_user(user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = auth.uid() 
    AND raw_user_meta_data->>'is_admin' = 'true'
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  -- Reset user data
  DELETE FROM user_responses WHERE user_id = $1;
  DELETE FROM module_progress WHERE user_id = $1;
END;
$$;

-- Create admin function to get user stats
CREATE OR REPLACE FUNCTION admin_get_user_stats()
RETURNS TABLE (
  date date,
  user_count bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = auth.uid() 
    AND raw_user_meta_data->>'is_admin' = 'true'
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  SELECT 
    date_trunc('day', created_at)::date,
    count(*)
  FROM auth.users
  GROUP BY 1
  ORDER BY 1;
END;
$$;