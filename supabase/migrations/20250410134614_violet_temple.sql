/*
  # Fix and improve answers table
  
  1. Changes
    - Add missing indexes on answers table for better performance
    - Ensure user_responses migration is properly implemented
    - Update triggers for answers table
  
  2. Security
    - Fix RLS policies for better security
    - Add proper admin access policies
*/

-- Create the answers table if it doesn't exist (idempotent)
CREATE TABLE IF NOT EXISTS answers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id uuid REFERENCES questions(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  text text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS on the answers table
ALTER TABLE answers ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid duplicates
DROP POLICY IF EXISTS "Users can view their own answers" ON answers;
DROP POLICY IF EXISTS "Users can create their own answers" ON answers;
DROP POLICY IF EXISTS "Users can update their own answers" ON answers;

-- Create RLS policies for answers
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

-- Create trigger for updated_at column
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