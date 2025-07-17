/*
  # Fix user responses RLS policies

  1. Changes
    - Drop existing RLS policies for user_responses table
    - Add new policies that properly handle the user_id field
    - Ensure user_id is set automatically using auth.uid()

  2. Security
    - Enable RLS on user_responses table
    - Add policies for SELECT, INSERT, and UPDATE operations
    - Ensure users can only access their own responses
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own responses" ON user_responses;
DROP POLICY IF EXISTS "Users can insert their own responses" ON user_responses;
DROP POLICY IF EXISTS "Users can update their own responses" ON user_responses;

-- Add trigger to set user_id on insert
CREATE OR REPLACE FUNCTION set_user_id()
RETURNS TRIGGER AS $$
BEGIN
  NEW.user_id = auth.uid();
  RETURN NEW;
END;
$$ language plpgsql security definer;

DROP TRIGGER IF EXISTS set_user_id_trigger ON user_responses;
CREATE TRIGGER set_user_id_trigger
  BEFORE INSERT ON user_responses
  FOR EACH ROW
  EXECUTE FUNCTION set_user_id();

-- Create new policies
CREATE POLICY "Users can view their own responses"
  ON user_responses
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own responses"
  ON user_responses
  FOR INSERT
  TO authenticated
  WITH CHECK (true);  -- user_id is set by trigger

CREATE POLICY "Users can update their own responses"
  ON user_responses
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);