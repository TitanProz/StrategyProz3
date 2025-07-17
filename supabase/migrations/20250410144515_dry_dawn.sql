/*
  # Fix Row Level Security for answers table
  
  1. Changes
    - Drop all existing policies on the answers table
    - Create a clean set of policies with proper permissions
    - Set up an automatic trigger to populate user_id on insert
    - Add admin access policies
  
  2. Security
    - Users can only access their own answers
    - Admins can access all answers
    - Trigger ensures user_id is set correctly
*/

-- Make sure the answers table exists
CREATE TABLE IF NOT EXISTS answers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id uuid REFERENCES questions(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  text text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Drop ALL existing policies to start fresh
DROP POLICY IF EXISTS "Users can view their own answers" ON answers;
DROP POLICY IF EXISTS "Users can create their own answers" ON answers;
DROP POLICY IF EXISTS "Users can update their own answers" ON answers;
DROP POLICY IF EXISTS "Admins can view all answers" ON answers;
DROP POLICY IF EXISTS "Admins have full access to answers" ON answers;

-- Make sure RLS is enabled
ALTER TABLE answers ENABLE ROW LEVEL SECURITY;

-- Create or replace the function for setting user_id
CREATE OR REPLACE FUNCTION set_answers_user_id()
RETURNS TRIGGER AS $$
BEGIN
  NEW.user_id = auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if it exists to prevent duplicates
DROP TRIGGER IF EXISTS set_answers_user_id_trigger ON answers;

-- Create trigger to set user_id automatically on insert
CREATE TRIGGER set_answers_user_id_trigger
  BEFORE INSERT ON answers
  FOR EACH ROW
  EXECUTE FUNCTION set_answers_user_id();

-- Create simple and distinct policies
-- Users can select their own answers
CREATE POLICY "Users can view their own answers"
  ON answers
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Users can insert answers (trigger will set user_id)
CREATE POLICY "Users can create their own answers"
  ON answers
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Users can update their own answers
CREATE POLICY "Users can update their own answers"
  ON answers
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Admins can view all answers
CREATE POLICY "Admins can view all answers"
  ON answers
  FOR SELECT
  TO authenticated
  USING (EXISTS (
    SELECT 1
    FROM auth.users
    WHERE ((users.id = auth.uid()) AND ((users.raw_user_meta_data ->> 'claims_admin'::text) = 'true'::text))
  ));

-- Admins have full access to all answers
CREATE POLICY "Admins have full access to answers"
  ON answers
  FOR ALL
  TO authenticated
  USING (EXISTS (
    SELECT 1
    FROM auth.users
    WHERE ((users.id = auth.uid()) AND ((users.raw_user_meta_data ->> 'claims_admin'::text) = 'true'::text))
  ));

-- Ensure indexes exist for better performance
CREATE INDEX IF NOT EXISTS idx_answers_question_id ON answers(question_id);
CREATE INDEX IF NOT EXISTS idx_answers_user_id ON answers(user_id);