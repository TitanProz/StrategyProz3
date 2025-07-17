/*
  # Fix ambiguous id reference in admin_list_users function
  
  1. Changes
    - Update admin_list_users function to use explicit table references
    - Add proper column qualifiers to avoid ambiguous column references
*/

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
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM auth.users WHERE auth.uid() = auth.users.id AND auth.users.email = current_setting('app.admin_email', true)
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  SELECT 
    users.id,
    users.email::text,
    users.created_at,
    users.last_sign_in_at,
    users.email = current_setting('app.admin_email', true) as is_admin
  FROM auth.users AS users
  ORDER BY users.created_at DESC;
END;
$$;