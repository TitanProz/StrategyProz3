/*
  # Fix answers table RLS policies

  1. Changes
    - Drop existing policies for the answers table
    - Create new RLS policies with proper permissions
    - Add admin policy to view all answers
    - Ensure proper indexes for performance

  2. Security
    - Enable RLS on answers table
    - Verify user_id matches authenticated user for operations
    - Allow users to view, create and update their own answers
    - Allow admins to view all answers
*/

-- First drop existing policies to start fresh
DROP POLICY IF EXISTS "Users can view their own answers" ON answers;
DROP POLICY IF EXISTS "Users can create their own answers" ON answers;
DROP POLICY IF EXISTS "Users can update their own answers" ON answers;
DROP POLICY IF EXISTS "Admins can view all answers" ON answers;

-- Make sure RLS is enabled
ALTER TABLE answers ENABLE ROW LEVEL SECURITY;

-- Create new policies with proper conditions
CREATE POLICY "Users can view their own answers"
  ON answers FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own answers"
  ON answers FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

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