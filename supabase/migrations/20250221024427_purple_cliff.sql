-- Create a secure function to get user data
CREATE OR REPLACE FUNCTION public.get_users()
RETURNS TABLE (
  id uuid,
  email text,
  created_at timestamptz,
  last_sign_in_at timestamptz,
  raw_user_meta_data jsonb,
  raw_app_meta_data jsonb
) 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Check if the user is authenticated and is an admin
  IF (SELECT (raw_user_meta_data->>'is_admin')::boolean 
      FROM auth.users 
      WHERE id = auth.uid()) THEN
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