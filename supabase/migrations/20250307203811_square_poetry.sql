/*
  # Add selected_niche column to user_settings table

  1. Changes
    - Add selected_niche column to user_settings table
    - Make it nullable text field
    - Add index for performance

  2. Security
    - No changes to RLS policies needed
    - Existing policies will cover the new column
*/

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_settings' 
    AND column_name = 'selected_niche'
  ) THEN
    ALTER TABLE user_settings ADD COLUMN selected_niche text;
    CREATE INDEX user_settings_selected_niche_idx ON user_settings (selected_niche);
  END IF;
END $$;