/*
  # Fix user responses table and policies
  
  1. Changes
    - Add module_id column to user_responses
    - Update RLS policies
    - Add indexes for performance
    
  2. Security
    - Maintain RLS policies for data isolation
    - Ensure proper user access control
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can read their own responses" ON user_responses;
DROP POLICY IF EXISTS "Users can create their own responses" ON user_responses;
DROP POLICY IF EXISTS "Users can modify their own responses" ON user_responses;

-- Add module_id column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_responses' 
    AND column_name = 'module_id'
  ) THEN
    ALTER TABLE user_responses 
    ADD COLUMN module_id uuid REFERENCES modules(id) ON DELETE CASCADE;

    -- Backfill module_id from questions table
    UPDATE user_responses ur
    SET module_id = q.module_id
    FROM questions q
    WHERE ur.question_id = q.id;

    -- Make module_id NOT NULL after backfill
    ALTER TABLE user_responses 
    ALTER COLUMN module_id SET NOT NULL;
  END IF;
END $$;

-- Create new RLS policies
CREATE POLICY "Users can read their own responses"
  ON user_responses FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own responses"
  ON user_responses FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can modify their own responses"
  ON user_responses FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_responses_user_id ON user_responses(user_id);
CREATE INDEX IF NOT EXISTS idx_user_responses_module_id ON user_responses(module_id);
CREATE INDEX IF NOT EXISTS idx_user_responses_question_id ON user_responses(question_id);