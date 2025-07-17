/*
  # Remove user_responses and update functions
  
  1. Changes
    - Drop user_responses table and related policies
    - Update clear_user_data function
    - Update admin functions
  
  2. Security
    - Maintain RLS policies for remaining tables
    - Update admin functions to handle new schema
*/

-- Drop user_responses table and related policies
DROP TABLE IF EXISTS user_responses CASCADE;

-- Update clear_user_data function
CREATE OR REPLACE FUNCTION clear_user_data()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Delete user's answers
  DELETE FROM answers WHERE user_id = auth.uid();
  
  -- Delete module progress
  DELETE FROM module_progress WHERE user_id = auth.uid();
  
  -- Delete completed modules
  DELETE FROM completed_modules WHERE user_id = auth.uid();
  
  -- Delete recent activities
  DELETE FROM recent_activities WHERE user_id = auth.uid();
  
  -- Reset user settings
  UPDATE user_settings 
  SET 
    selected_practice = NULL,
    selected_niche = NULL,
    final_report = NULL
  WHERE user_id = auth.uid();
END;
$$;

-- Update admin_delete_user function
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
    AND raw_user_meta_data->>'claims_admin' = 'true'
  ) THEN
    RAISE EXCEPTION 'Permission denied';
  END IF;

  -- Delete user data
  DELETE FROM answers WHERE user_id = $1;
  DELETE FROM module_progress WHERE user_id = $1;
  DELETE FROM completed_modules WHERE user_id = $1;
  DELETE FROM recent_activities WHERE user_id = $1;
  DELETE FROM user_settings WHERE user_id = $1;
  DELETE FROM messages WHERE sender_id = $1 OR receiver_id = $1;
  
  -- Delete the user
  DELETE FROM auth.users WHERE id = $1;
END;
$$;