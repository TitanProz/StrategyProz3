/*
  # Fix Admin Access
  
  1. Changes
    - Add function to check admin status
    - Add function to set admin status
    - Update RLS policies
*/

-- Function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = auth.uid() 
    AND (
      raw_user_meta_data->>'claims_admin' = 'true'
      OR email = 'admin@strategyproz.com'
    )
  );
END;
$$;

-- Function to set admin status
CREATE OR REPLACE FUNCTION set_admin_status(target_user_id uuid, is_admin boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Update user metadata
  UPDATE auth.users
  SET raw_user_meta_data = 
    CASE 
      WHEN is_admin THEN 
        jsonb_set(COALESCE(raw_user_meta_data, '{}'::jsonb), '{claims_admin}', 'true'::jsonb)
      ELSE 
        raw_user_meta_data - 'claims_admin'
    END
  WHERE id = target_user_id;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION set_admin_status(uuid, boolean) TO authenticated;