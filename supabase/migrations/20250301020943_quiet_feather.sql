/*
  # Add final_report column to user_settings table

  1. Changes
    - Add final_report column to user_settings table to store the final report JSON
*/

-- Add final_report column to user_settings table if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_settings' AND column_name = 'final_report'
  ) THEN
    ALTER TABLE user_settings ADD COLUMN final_report JSONB;
  END IF;
END $$;