-- Drop existing function first
DROP FUNCTION IF EXISTS public.get_users();

-- Create a secure function to get user data
CREATE FUNCTION public.get_users()
RETURNS TABLE (
  id uuid,
  email varchar,
  created_at timestamp with time zone,
  last_sign_in_at timestamp with time zone,
  raw_user_meta_data jsonb,
  raw_app_meta_data jsonb
) 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  is_admin boolean;
BEGIN
  -- Get admin status first to avoid ambiguous column reference
  SELECT (u.raw_user_meta_data->>'is_admin')::boolean INTO is_admin
  FROM auth.users u 
  WHERE u.id = auth.uid();

  -- Check if the user is authenticated and is an admin
  IF is_admin THEN
    -- Return all users for admins
    RETURN QUERY
    SELECT 
      u.id,
      u.email,
      u.created_at,
      u.last_sign_in_at,
      u.raw_user_meta_data,
      u.raw_app_meta_data
    FROM auth.users u;
  ELSE
    -- Return only the current user's data for non-admins
    RETURN QUERY
    SELECT 
      u.id,
      u.email,
      u.created_at,
      u.last_sign_in_at,
      u.raw_user_meta_data,
      u.raw_app_meta_data
    FROM auth.users u
    WHERE u.id = auth.uid();
  END IF;
END;
$$;