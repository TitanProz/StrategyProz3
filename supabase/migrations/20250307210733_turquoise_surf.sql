/*
  # Admin Functions Migration
  
  1. Functions
    - admin_list_users: Lists all users with their metadata
    - admin_get_user_stats: Gets user growth statistics
    - admin_reset_user: Resets a user's data
    - admin_delete_user: Deletes a user and their data
  
  2. Security
    - All functions are SECURITY DEFINER
    - Access restricted to admin users only
*/

-- Function to list all users with metadata
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
  -- Check if the user is an admin
  IF NOT EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND raw_user_meta_data->>'is_admin' = 'true'
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  SELECT 
    au.id,
    au.email::text,
    au.created_at,
    (au.raw_user_meta_data->>'last_sign_in_at')::timestamptz,
    (au.raw_user_meta_data->>'is_admin')::boolean
  FROM auth.users au
  ORDER BY au.created_at DESC;
END;
$$;

-- Function to get user statistics
CREATE OR REPLACE FUNCTION admin_get_user_stats()
RETURNS TABLE (
  date date,
  user_count bigint
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Check if the user is an admin
  IF NOT EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND raw_user_meta_data->>'is_admin' = 'true'
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  SELECT 
    d::date,
    COUNT(u.created_at) OVER (ORDER BY d::date) as user_count
  FROM generate_series(
    (SELECT date_trunc('day', MIN(created_at))::date FROM auth.users),
    CURRENT_DATE,
    '1 day'::interval
  ) d
  LEFT JOIN auth.users u ON date_trunc('day', u.created_at)::date <= d::date
  GROUP BY d, u.created_at
  ORDER BY d;
END;
$$;

-- Function to reset a user's data
CREATE OR REPLACE FUNCTION admin_reset_user(user_id uuid)
RETURNS void
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Check if the user is an admin
  IF NOT EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND raw_user_meta_data->>'is_admin' = 'true'
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  -- Delete user's data
  DELETE FROM user_responses WHERE user_id = $1;
  DELETE FROM module_progress WHERE user_id = $1;
  DELETE FROM completed_modules WHERE user_id = $1;
  DELETE FROM user_settings WHERE user_id = $1;
  DELETE FROM messages WHERE sender_id = $1 OR receiver_id = $1;
  DELETE FROM chat_messages WHERE sender_id = $1 OR receiver_id = $1;
END;
$$;

-- Function to delete a user
CREATE OR REPLACE FUNCTION admin_delete_user(user_id uuid)
RETURNS void
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Check if the user is an admin
  IF NOT EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND raw_user_meta_data->>'is_admin' = 'true'
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  -- Delete user's data
  PERFORM admin_reset_user(user_id);
  
  -- Delete the user from auth.users
  DELETE FROM auth.users WHERE id = user_id;
END;
$$;