/*
  # Add admin_verify_email function
  
  1. New Functions
    - admin_verify_email: Automatically verifies a user's email
  
  2. Security
    - Function is security definer
    - Only accessible through RPC
*/

CREATE OR REPLACE FUNCTION admin_verify_email(user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Update the user's email_confirmed_at timestamp
  UPDATE auth.users
  SET email_confirmed_at = now(),
      updated_at = now()
  WHERE id = user_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION admin_verify_email(uuid) TO authenticated;