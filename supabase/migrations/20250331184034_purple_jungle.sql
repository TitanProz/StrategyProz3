/*
  # Fix RLS Policies and Add Admin Controls
  
  1. Changes
    - Enable RLS on all tables
    - Drop and recreate policies with proper naming
    - Add admin access controls
    - Add clear_user_data function
  
  2. Security
    - Ensure proper data isolation
    - Add admin access controls
    - Maintain existing security model
*/

-- Enable RLS on all tables
ALTER TABLE public.user_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.module_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.completed_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view their own responses" ON user_responses;
DROP POLICY IF EXISTS "Users can insert their own responses" ON user_responses;
DROP POLICY IF EXISTS "Users can update their own responses" ON user_responses;
DROP POLICY IF EXISTS "Admins can view all responses" ON user_responses;

DROP POLICY IF EXISTS "Users can view their own progress" ON module_progress;
DROP POLICY IF EXISTS "Users can insert their own progress" ON module_progress;
DROP POLICY IF EXISTS "Users can update their own progress" ON module_progress;
DROP POLICY IF EXISTS "Admins can view all progress" ON module_progress;

DROP POLICY IF EXISTS "Users can view their own completed modules" ON completed_modules;
DROP POLICY IF EXISTS "Users can insert their own completed modules" ON completed_modules;
DROP POLICY IF EXISTS "Users can update their own completed modules" ON completed_modules;
DROP POLICY IF EXISTS "Users can delete their own completed modules" ON completed_modules;
DROP POLICY IF EXISTS "Admins can view all completed modules" ON completed_modules;

DROP POLICY IF EXISTS "Users can view their own settings" ON user_settings;
DROP POLICY IF EXISTS "Users can insert their own settings" ON user_settings;
DROP POLICY IF EXISTS "Users can update their own settings" ON user_settings;
DROP POLICY IF EXISTS "Admins can view all settings" ON user_settings;

-- Create RLS policies for user_responses
CREATE POLICY "Users can read their own responses"
  ON user_responses FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id OR is_admin());

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
  USING (auth.uid() = user_id OR is_admin());

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
  USING (auth.uid() = user_id OR is_admin());

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
  USING (auth.uid() = user_id OR is_admin());

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

-- Create RLS policies for chat_messages
CREATE POLICY "Users can read their own chat messages"
  ON chat_messages FOR SELECT
  TO authenticated
  USING (auth.uid() IN (sender_id, receiver_id));

CREATE POLICY "Users can send chat messages"
  ON chat_messages FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can mark received chat messages as read"
  ON chat_messages FOR UPDATE
  TO authenticated
  USING (auth.uid() = receiver_id)
  WITH CHECK (auth.uid() = receiver_id);

-- Create function to clear user data
CREATE OR REPLACE FUNCTION clear_user_data()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only allow users to clear their own data
  DELETE FROM user_responses WHERE user_id = auth.uid();
  DELETE FROM module_progress WHERE user_id = auth.uid();
  DELETE FROM completed_modules WHERE user_id = auth.uid();
  DELETE FROM user_settings WHERE user_id = auth.uid();
  DELETE FROM messages WHERE sender_id = auth.uid() OR receiver_id = auth.uid();
  DELETE FROM chat_messages WHERE sender_id = auth.uid() OR receiver_id = auth.uid();
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION clear_user_data() TO authenticated;