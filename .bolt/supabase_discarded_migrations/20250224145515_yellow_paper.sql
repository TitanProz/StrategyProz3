-- Drop existing functions first
DROP FUNCTION IF EXISTS admin_list_users();
DROP FUNCTION IF EXISTS admin_delete_user(target_user_id uuid);
DROP FUNCTION IF EXISTS admin_reset_user(target_user_id uuid);
DROP FUNCTION IF EXISTS admin_get_user_stats();

-- Create admin function to list users with proper column references
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
DECLARE
  requesting_user auth.users%ROWTYPE;
BEGIN
  -- Get the requesting user's full record
  SELECT * INTO requesting_user
  FROM auth.users
  WHERE auth.users.id = auth.uid();

  -- Check if the requesting user is an admin
  IF NOT (requesting_user.raw_user_meta_data->>'is_admin')::boolean THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  SELECT 
    auth_users.id,
    auth_users.email::text,
    auth_users.created_at,
    auth_users.last_sign_in_at,
    (auth_users.raw_user_meta_data->>'is_admin')::boolean
  FROM auth.users auth_users;
END;
$$;

-- Create admin function to delete user with proper column references
CREATE OR REPLACE FUNCTION admin_delete_user(target_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  requesting_user auth.users%ROWTYPE;
BEGIN
  -- Get the requesting user's full record
  SELECT * INTO requesting_user
  FROM auth.users
  WHERE auth.users.id = auth.uid();

  -- Check if the requesting user is an admin
  IF NOT (requesting_user.raw_user_meta_data->>'is_admin')::boolean THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  -- Delete user data
  DELETE FROM user_responses WHERE user_responses.user_id = target_user_id;
  DELETE FROM module_progress WHERE module_progress.user_id = target_user_id;
  DELETE FROM messages WHERE messages.sender_id = target_user_id OR messages.receiver_id = target_user_id;
END;
$$;

-- Create admin function to reset user with proper column references
CREATE OR REPLACE FUNCTION admin_reset_user(target_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  requesting_user auth.users%ROWTYPE;
BEGIN
  -- Get the requesting user's full record
  SELECT * INTO requesting_user
  FROM auth.users
  WHERE auth.users.id = auth.uid();

  -- Check if the requesting user is an admin
  IF NOT (requesting_user.raw_user_meta_data->>'is_admin')::boolean THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  -- Reset user data
  DELETE FROM user_responses WHERE user_responses.user_id = target_user_id;
  DELETE FROM module_progress WHERE module_progress.user_id = target_user_id;
END;
$$;

-- Create admin function to get user stats with proper column references
CREATE OR REPLACE FUNCTION admin_get_user_stats()
RETURNS TABLE (
  date date,
  user_count bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  requesting_user auth.users%ROWTYPE;
BEGIN
  -- Get the requesting user's full record
  SELECT * INTO requesting_user
  FROM auth.users
  WHERE auth.users.id = auth.uid();

  -- Check if the requesting user is an admin
  IF NOT (requesting_user.raw_user_meta_data->>'is_admin')::boolean THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  SELECT 
    date_trunc('day', auth_users.created_at)::date,
    count(*)::bigint
  FROM auth.users auth_users
  GROUP BY date_trunc('day', auth_users.created_at)::date
  ORDER BY date_trunc('day', auth_users.created_at)::date;
END;
$$;