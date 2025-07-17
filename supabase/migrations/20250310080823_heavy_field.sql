/*
  # Add Admin Features

  1. New Functions
    - Add function to check admin status
    - Add function to manage user data

  2. Security
    - Add policies for admin access
    - Ensure proper data isolation
*/

-- Function to check if a user is an admin
CREATE OR REPLACE FUNCTION is_admin(user_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_settings
    WHERE user_id = $1 AND is_admin = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to clear user data (for reset functionality)
CREATE OR REPLACE FUNCTION clear_user_data(target_user_id uuid)
RETURNS void AS $$
BEGIN
  -- Only allow if executor is admin
  IF NOT is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Permission denied';
  END IF;

  -- Delete user responses
  DELETE FROM user_responses WHERE user_id = target_user_id;
  
  -- Reset module progress
  DELETE FROM module_progress WHERE user_id = target_user_id;
  
  -- Clear completed modules
  DELETE FROM completed_modules WHERE user_id = target_user_id;
  
  -- Reset user settings (preserve admin status if exists)
  UPDATE user_settings 
  SET 
    selected_practice = NULL,
    selected_niche = NULL,
    final_report = NULL
  WHERE user_id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add admin-specific policies
ALTER TABLE user_responses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view all responses"
  ON user_responses
  FOR SELECT
  TO authenticated
  USING (is_admin(auth.uid()));

-- Ensure proper indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_responses_user_id ON user_responses(user_id);
CREATE INDEX IF NOT EXISTS idx_module_progress_user_id ON module_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_completed_modules_user_id ON completed_modules(user_id);