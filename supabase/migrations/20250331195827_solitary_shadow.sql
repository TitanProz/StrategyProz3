/*
  # Fix user data isolation and RLS policies
  
  1. Changes
    - Drop existing policies
    - Create new RLS policies for user data isolation
    - Add indexes for performance
  
  2. Security
    - Enable RLS on all tables
    - Ensure users can only access their own data
*/

-- Drop existing policies
DO $$ BEGIN
  DROP POLICY IF EXISTS "Users can read their own responses" ON user_responses;
  DROP POLICY IF EXISTS "Users can create their own responses" ON user_responses;
  DROP POLICY IF EXISTS "Users can modify their own responses" ON user_responses;
  DROP POLICY IF EXISTS "Users can read their own progress" ON module_progress;
  DROP POLICY IF EXISTS "Users can create their own progress" ON module_progress;
  DROP POLICY IF EXISTS "Users can modify their own progress" ON module_progress;
  DROP POLICY IF EXISTS "Users can read their own completed modules" ON completed_modules;
  DROP POLICY IF EXISTS "Users can create their own completed modules" ON completed_modules;
  DROP POLICY IF EXISTS "Users can remove their own completed modules" ON completed_modules;
  DROP POLICY IF EXISTS "Users can read their own settings" ON user_settings;
  DROP POLICY IF EXISTS "Users can create their own settings" ON user_settings;
  DROP POLICY IF EXISTS "Users can modify their own settings" ON user_settings;
  DROP POLICY IF EXISTS "Users can read their own messages" ON messages;
  DROP POLICY IF EXISTS "Users can send messages" ON messages;
  DROP POLICY IF EXISTS "Users can mark received messages as read" ON messages;
END $$;

-- Enable RLS on all tables
ALTER TABLE user_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE module_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE completed_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for user_responses
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

-- Create RLS policies for module_progress
CREATE POLICY "Users can read their own progress"
  ON module_progress FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own progress"
  ON module_progress FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can modify their own progress"
  ON module_progress FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Create RLS policies for completed_modules
CREATE POLICY "Users can read their own completed modules"
  ON completed_modules FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own completed modules"
  ON completed_modules FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove their own completed modules"
  ON completed_modules FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Create RLS policies for user_settings
CREATE POLICY "Users can read their own settings"
  ON user_settings FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own settings"
  ON user_settings FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can modify their own settings"
  ON user_settings FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Create RLS policies for messages
CREATE POLICY "Users can read their own messages"
  ON messages FOR SELECT
  TO authenticated
  USING (auth.uid() IN (sender_id, receiver_id));

CREATE POLICY "Users can send messages"
  ON messages FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can mark received messages as read"
  ON messages FOR UPDATE
  TO authenticated
  USING (auth.uid() = receiver_id)
  WITH CHECK (auth.uid() = receiver_id);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_user_responses_user_id ON user_responses(user_id);
CREATE INDEX IF NOT EXISTS idx_module_progress_user_id ON module_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_completed_modules_user_id ON completed_modules(user_id);
CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON user_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON messages(receiver_id);