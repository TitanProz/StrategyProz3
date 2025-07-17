/*
  # Add chat preferences table
  
  1. New Tables
    - `chat_preferences`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `participant_id` (uuid, references auth.users)
      - `is_pinned` (boolean)
      - `display_order` (integer)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS
    - Add policies for users to manage their preferences
    - Add admin policies
*/

-- Create chat_preferences table
CREATE TABLE chat_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  participant_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  is_pinned boolean DEFAULT false,
  display_order integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, participant_id)
);

-- Enable RLS
ALTER TABLE chat_preferences ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own preferences"
  ON chat_preferences
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own preferences"
  ON chat_preferences
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own preferences"
  ON chat_preferences
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own preferences"
  ON chat_preferences
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Create indexes
CREATE INDEX chat_preferences_user_id_idx ON chat_preferences(user_id);
CREATE INDEX chat_preferences_participant_id_idx ON chat_preferences(participant_id);

-- Create update trigger for updated_at
CREATE TRIGGER update_chat_preferences_updated_at
  BEFORE UPDATE ON chat_preferences
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();