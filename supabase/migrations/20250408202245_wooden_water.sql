/*
  # Add recent_activities table
  
  1. New Tables
    - `recent_activities`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `text` (text)
      - `created_at` (timestamp)
  
  2. Security
    - Enable RLS on the table
    - Add policies for users to insert and view their own activities
*/

-- Create recent_activities table if it doesn't exist
CREATE TABLE IF NOT EXISTS recent_activities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  text text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE recent_activities ENABLE ROW LEVEL SECURITY;

-- Create policies only if they don't exist
DO $$
BEGIN
  -- Policy for viewing activities
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'recent_activities' AND policyname = 'Users can view their own activities'
  ) THEN
    CREATE POLICY "Users can view their own activities"
      ON recent_activities FOR SELECT
      TO authenticated
      USING (auth.uid() = user_id);
  END IF;
  
  -- Policy for inserting activities
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'recent_activities' AND policyname = 'Users can insert their own activities'
  ) THEN
    CREATE POLICY "Users can insert their own activities"
      ON recent_activities FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_recent_activities_user_id ON recent_activities(user_id);