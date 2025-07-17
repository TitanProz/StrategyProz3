/*
  # Add Admin Functions
  
  1. New Functions
    - admin_list_users: Lists all users with their details
    - admin_get_user_stats: Gets user growth statistics
    - admin_reset_user: Resets a user's data
    - admin_delete_user: Deletes a user and their data
  
  2. Security
    - Functions are only accessible to authenticated users with admin role
*/

-- Drop existing functions if they exist
DROP FUNCTION IF EXISTS admin_list_users();
DROP FUNCTION IF EXISTS admin_get_user_stats();
DROP FUNCTION IF EXISTS admin_reset_user(uuid);
DROP FUNCTION IF EXISTS admin_delete_user(uuid);

-- Function to list all users
CREATE FUNCTION admin_list_users()
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
  -- Check if the calling user is an admin
  IF NOT EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = auth.uid() 
    AND email = current_setting('app.admin_email', true)
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  SELECT 
    au.id,
    au.email,
    au.created_at,
    au.last_sign_in_at,
    (au.email = current_setting('app.admin_email', true)) as is_admin
  FROM auth.users au
  ORDER BY au.created_at DESC;
END;
$$;

-- Function to get user growth statistics
CREATE FUNCTION admin_get_user_stats()
RETURNS TABLE (
  date date,
  user_count bigint
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Check if the calling user is an admin
  IF NOT EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = auth.uid() 
    AND email = current_setting('app.admin_email', true)
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  SELECT 
    date_trunc('day', created_at)::date,
    count(*) OVER (ORDER BY date_trunc('day', created_at))
  FROM auth.users
  GROUP BY 1
  ORDER BY 1;
END;
$$;

-- Function to reset a user's data
CREATE FUNCTION admin_reset_user(user_id uuid)
RETURNS void
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Check if the calling user is an admin
  IF NOT EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = auth.uid() 
    AND email = current_setting('app.admin_email', true)
  ) THEN
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
    final_report = NULL
  WHERE user_id = $1;
END;
$$;

-- Function to delete a user
CREATE FUNCTION admin_delete_user(user_id uuid)
RETURNS void
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Check if the calling user is an admin
  IF NOT EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = auth.uid() 
    AND email = current_setting('app.admin_email', true)
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  -- Delete user's data
  DELETE FROM user_responses WHERE user_id = $1;
  DELETE FROM module_progress WHERE user_id = $1;
  DELETE FROM completed_modules WHERE user_id = $1;
  DELETE FROM user_settings WHERE user_id = $1;
  DELETE FROM messages WHERE sender_id = $1 OR receiver_id = $1;
  
  -- Delete the user from auth.users
  DELETE FROM auth.users WHERE id = $1;
END;
$$;