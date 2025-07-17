/*
  # Fix database schema and ensure answers table exists
  
  1. Changes
    - Create answers table if it doesn't exist
    - Conditionally create the trigger to avoid conflicts
    - Add indexes for better query performance
  
  2. Security
    - Add appropriate RLS policies for the answers table
*/

-- First check that our tables exist
CREATE TABLE IF NOT EXISTS modules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  slug text UNIQUE NOT NULL,
  "order" integer NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Ensure questions table exists
CREATE TABLE IF NOT EXISTS questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  module_id uuid REFERENCES modules(id) ON DELETE CASCADE,
  content text NOT NULL,
  "order" integer NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Create answers table if it doesn't exist
CREATE TABLE IF NOT EXISTS answers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id uuid REFERENCES questions(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  text text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Check if trigger exists before creating it
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

-- Enable RLS on tables
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE answers ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (only if they don't exist)
DO $$ 
BEGIN
  -- For modules
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'modules' AND policyname = 'Modules are viewable by public'
  ) THEN
    CREATE POLICY "Modules are viewable by public"
      ON modules FOR SELECT
      TO public
      USING (true);
  END IF;
  
  -- For questions
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'questions' AND policyname = 'Questions are viewable by public'
  ) THEN
    CREATE POLICY "Questions are viewable by public"
      ON questions FOR SELECT
      TO public
      USING (true);
  END IF;
  
  -- For answers (select)
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'answers' AND policyname = 'Users can view their own answers'
  ) THEN
    CREATE POLICY "Users can view their own answers"
      ON answers FOR SELECT
      TO authenticated
      USING (auth.uid() = user_id);
  END IF;
  
  -- For answers (insert)
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'answers' AND policyname = 'Users can create their own answers'
  ) THEN
    CREATE POLICY "Users can create their own answers"
      ON answers FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = user_id);
  END IF;
  
  -- For answers (update)
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'answers' AND policyname = 'Users can update their own answers'
  ) THEN
    CREATE POLICY "Users can update their own answers"
      ON answers FOR UPDATE
      TO authenticated
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- Create indexes for better performance (idempotent)
CREATE INDEX IF NOT EXISTS idx_questions_module_id ON questions(module_id);
CREATE INDEX IF NOT EXISTS idx_answers_question_id ON answers(question_id);
CREATE INDEX IF NOT EXISTS idx_answers_user_id ON answers(user_id);

-- Add worksheets table for better organization if it doesn't exist
CREATE TABLE IF NOT EXISTS worksheets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS on worksheets
ALTER TABLE worksheets ENABLE ROW LEVEL SECURITY;

-- Add policy for worksheets if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'worksheets' AND policyname = 'Worksheets are viewable by authenticated users'
  ) THEN
    CREATE POLICY "Worksheets are viewable by authenticated users"
      ON worksheets FOR SELECT
      TO authenticated
      USING (true);
  END IF;
END $$;