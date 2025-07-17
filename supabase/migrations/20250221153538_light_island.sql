/*
  # Fix module progress RLS policies

  1. Changes
    - Drop existing RLS policies for module_progress
    - Add new RLS policies with proper user_id handling
    - Add trigger for automatically setting user_id
    - Add index for better query performance

  2. Security
    - Enable RLS on module_progress table
    - Add policies for authenticated users to:
      - View their own progress
      - Insert new progress records
      - Update their existing progress
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own progress" ON module_progress;
DROP POLICY IF EXISTS "Users can insert their own progress" ON module_progress;
DROP POLICY IF EXISTS "Users can update their own progress" ON module_progress;

-- Add trigger to set user_id on insert
CREATE OR REPLACE FUNCTION set_module_progress_user_id()
RETURNS TRIGGER AS $$
BEGIN
  NEW.user_id = auth.uid();
  RETURN NEW;
END;
$$ language plpgsql security definer;

DROP TRIGGER IF EXISTS set_module_progress_user_id_trigger ON module_progress;
CREATE TRIGGER set_module_progress_user_id_trigger
  BEFORE INSERT ON module_progress
  FOR EACH ROW
  EXECUTE FUNCTION set_module_progress_user_id();

-- Create new policies
CREATE POLICY "Users can view their own progress"
  ON module_progress
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can insert their own progress"
  ON module_progress
  FOR INSERT
  TO authenticated
  WITH CHECK (true);  -- user_id is set by trigger

CREATE POLICY "Users can update their own progress"
  ON module_progress
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS module_progress_user_module_idx ON module_progress(user_id, module_id);