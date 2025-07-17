/*
  # Fix Answers Table RLS Policy
  
  1. Changes
    - Drop existing policies on the answers table
    - Create a trigger function to automatically set user_id on insert
    - Add trigger to the answers table
    - Create new RLS policies with proper configurations
    
  2. Security
    - Enable RLS on the answers table
    - Allow authenticated users to view and update only their own data
    - Allow admins to view all answers
    - Set user_id automatically on insert for better security
*/

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view their own answers" ON answers;
DROP POLICY IF EXISTS "Users can create their own answers" ON answers;
DROP POLICY IF EXISTS "Users can update their own answers" ON answers;
DROP POLICY IF EXISTS "Admins can view all answers" ON answers;

-- Create or replace the trigger function to set user_id
CREATE OR REPLACE FUNCTION set_answers_user_id()
RETURNS TRIGGER AS $$
BEGIN
  NEW.user_id = auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if it exists
DROP TRIGGER IF EXISTS set_answers_user_id_trigger ON answers;

-- Create trigger to set user_id automatically on insert
CREATE TRIGGER set_answers_user_id_trigger
  BEFORE INSERT ON answers
  FOR EACH ROW
  EXECUTE FUNCTION set_answers_user_id();

-- Make sure RLS is enabled
ALTER TABLE answers ENABLE ROW LEVEL SECURITY;

-- Create new policies with proper conditions
CREATE POLICY "Users can view their own answers"
  ON answers FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Important: This policy now just checks that the user is authenticated
-- since the trigger will set the user_id automatically
CREATE POLICY "Users can create their own answers"
  ON answers FOR INSERT
  TO authenticated
  WITH CHECK (true); 

CREATE POLICY "Users can update their own answers"
  ON answers FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Add admin policy to view all answers
CREATE POLICY "Admins can view all answers"
  ON answers FOR SELECT
  TO authenticated
  USING (EXISTS (
    SELECT 1
    FROM auth.users
    WHERE ((users.id = auth.uid()) AND ((users.raw_user_meta_data ->> 'claims_admin'::text) = 'true'::text))
  ));

-- Create or update indexes for better performance
CREATE INDEX IF NOT EXISTS idx_answers_question_id ON answers(question_id);
CREATE INDEX IF NOT EXISTS idx_answers_user_id ON answers(user_id);