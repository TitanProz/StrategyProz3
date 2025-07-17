/*
  # Fix completed_modules RLS policies

  1. Changes
    - Drop and recreate RLS policies for completed_modules table
    - Ensure proper access for authenticated users
*/

-- Drop existing policies for completed_modules
DROP POLICY IF EXISTS "Users can view their own completed modules" ON completed_modules;
DROP POLICY IF EXISTS "Users can insert their own completed modules" ON completed_modules;
DROP POLICY IF EXISTS "Users can delete their own completed modules" ON completed_modules;

-- Create updated policies for completed_modules
CREATE POLICY "Users can view their own completed modules"
  ON completed_modules FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own completed modules"
  ON completed_modules FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own completed modules"
  ON completed_modules FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own completed modules"
  ON completed_modules FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);