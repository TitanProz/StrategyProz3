/*
  # Create public view for auth users

  1. New Views
    - `users` - A public view that safely exposes auth.users data with built-in row-level security
*/

-- Create a secure view to expose auth.users data
CREATE OR REPLACE VIEW public.users AS 
SELECT 
  id,
  email,
  created_at,
  last_sign_in_at,
  raw_app_meta_data->>'claims_admin' as is_admin
FROM auth.users
WHERE 
  -- Users can only see their own data
  auth.uid() = id 
  -- Admins can see all data
  OR (SELECT COALESCE((auth.jwt() ->> 'claims_admin')::boolean, false));

-- Enable security barrier to prevent leaking data
ALTER VIEW public.users SET (security_barrier = true, security_invoker = true);