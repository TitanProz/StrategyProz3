/*
  # Fix answers table RLS policy and trigger
  
  1. Changes
    - Drop existing INSERT policy and recreate with correct permissions
    - Ensure trigger function is properly defined with SECURITY DEFINER
    - Add additional admin policy for full access
  
  2. Security
    - Properly handle user_id assignment via trigger
    - Ensure authenticated users can create answers
*/

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can create their own answers" ON answers;

-- Ensure the trigger function exists and is properly defined
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

-- Create a simpler policy that just checks if authenticated
CREATE POLICY "Users can create their own answers"
  ON answers FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Add admin policy for full access
CREATE POLICY "Admins have full access to answers"
  ON answers
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM auth.users
      WHERE ((users.id = auth.uid()) AND ((users.raw_user_meta_data ->> 'claims_admin'::text) = 'true'::text))
    )
  );

-- Ensure indexes exist for better performance
CREATE INDEX IF NOT EXISTS idx_answers_question_id ON answers(question_id);
CREATE INDEX IF NOT EXISTS idx_answers_user_id ON answers(user_id);