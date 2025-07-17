/*
  # Fix user data clearing functionality

  1. Changes
    - Add RLS policies for deleting user responses and module progress
    - Add function to safely clear user data
  
  2. Security
    - Ensure users can only delete their own data
    - Prevent unauthorized deletion of other users' data
*/

-- Add delete policies for user_responses
CREATE POLICY "Users can delete their own responses"
  ON user_responses
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Add delete policies for module_progress
CREATE POLICY "Users can delete their own progress"
  ON module_progress
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Create a function to safely clear user data
CREATE OR REPLACE FUNCTION clear_user_data()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Delete user responses
  DELETE FROM user_responses
  WHERE user_id = auth.uid();
  
  -- Delete module progress
  DELETE FROM module_progress
  WHERE user_id = auth.uid();
END;
$$;