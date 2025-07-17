/*
  # Add Chat Preferences Columns
  
  1. Changes
    - Add chat_notifications column (boolean, default false)
    - Add chat_sounds column (boolean, default false)
    - Add these to user_settings table
  
  2. Security
    - Maintain existing RLS policies
    - No additional security needed as user_settings already has proper policies
*/

-- Add chat preference columns if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_settings' 
    AND column_name = 'chat_notifications'
  ) THEN
    ALTER TABLE user_settings ADD COLUMN chat_notifications boolean DEFAULT false;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_settings' 
    AND column_name = 'chat_sounds'
  ) THEN
    ALTER TABLE user_settings ADD COLUMN chat_sounds boolean DEFAULT false;
  END IF;
END $$;