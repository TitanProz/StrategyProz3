/*
  # Fix answers table RLS policies
  
  1. Changes
    - Drop existing policies
    - Create new RLS policies with proper permissions
    - Add trigger to set user_id on insert
    - Add indexes for performance
  
  2. Security
    - Enable RLS on answers table
    - Ensure users can only access their own answers
    - Allow admins to view all answers
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own answers" ON answers;
DROP POLICY IF EXISTS "Users can create their own answers" ON answers;
DROP POLICY IF EXISTS "Users can update their own answers" ON answers;
DROP POLICY IF EXISTS "Admins can view all answers" ON answers;
DROP POLICY IF EXISTS "Admins have full access to answers" ON answers;

-- Make sure RLS is enabled
ALTER TABLE answers ENABLE ROW LEVEL SECURITY;

-- Create or replace the trigger function
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

-- Create RLS policies
CREATE POLICY "Users can view their own answers"
  ON answers FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own answers"
  ON answers FOR INSERT
  TO authenticated
  WITH CHECK (true);  -- user_id is set by trigger

CREATE POLICY "Users can update their own answers"
  ON answers FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Add admin policies
CREATE POLICY "Admins can view all answers"
  ON answers FOR SELECT
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND raw_user_meta_data->>'claims_admin' = 'true'
  ));

CREATE POLICY "Admins have full access to answers"
  ON answers FOR ALL
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND raw_user_meta_data->>'claims_admin' = 'true'
  ));

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_answers_question_id ON answers(question_id);
CREATE INDEX IF NOT EXISTS idx_answers_user_id ON answers(user_id);
CREATE INDEX IF NOT EXISTS idx_answers_user_question ON answers(user_id, question_id);