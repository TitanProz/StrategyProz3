/*
  # Fix questions repetition issue
  
  1. Changes
    - Enable RLS on answers table
    - Add admin policy to view all answers
    - Add user policy to manage their own answers
    - Add trigger to set user_id on insert
  
  2. Security
    - Maintain existing security model
    - Add proper admin access controls
*/

-- Drop existing conflicting policies if they exist
DROP POLICY IF EXISTS "Users can view their own answers" ON answers;
DROP POLICY IF EXISTS "Users can create their own answers" ON answers;
DROP POLICY IF EXISTS "Users can update their own answers" ON answers;
DROP POLICY IF EXISTS "Admins can view all answers" ON answers;
DROP POLICY IF EXISTS "Admins have full access to answers" ON answers;

-- Create or replace the trigger function for setting user_id
CREATE OR REPLACE FUNCTION set_answers_user_id()
RETURNS TRIGGER AS $$
BEGIN
  NEW.user_id = auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop the trigger if it exists to avoid duplicate triggers
DROP TRIGGER IF EXISTS set_answers_user_id_trigger ON answers;

-- Create trigger to set user_id automatically on insert
CREATE TRIGGER set_answers_user_id_trigger
  BEFORE INSERT ON answers
  FOR EACH ROW
  EXECUTE FUNCTION set_answers_user_id();

-- Enable RLS on the answers table
ALTER TABLE answers ENABLE ROW LEVEL SECURITY;

-- Create comprehensive policies for the answers table
CREATE POLICY "Users can view their own answers"
  ON answers
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own answers"
  ON answers
  FOR INSERT
  TO authenticated
  WITH CHECK (true);  -- user_id is set by trigger

CREATE POLICY "Users can update their own answers"
  ON answers
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all answers"
  ON answers
  FOR SELECT
  TO authenticated
  USING (EXISTS (
    SELECT 1
    FROM auth.users
    WHERE ((users.id = auth.uid()) AND ((users.raw_user_meta_data ->> 'claims_admin'::text) = 'true'::text))
  ));

CREATE POLICY "Admins have full access to answers"
  ON answers
  FOR ALL
  TO authenticated
  USING (EXISTS (
    SELECT 1
    FROM auth.users
    WHERE ((users.id = auth.uid()) AND ((users.raw_user_meta_data ->> 'claims_admin'::text) = 'true'::text))
  ));

-- Create trigger for updated_at column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'update_answers_updated_at'
  ) THEN
    CREATE TRIGGER update_answers_updated_at
      BEFORE UPDATE ON answers
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_answers_question_id ON answers(question_id);
CREATE INDEX IF NOT EXISTS idx_answers_user_id ON answers(user_id);