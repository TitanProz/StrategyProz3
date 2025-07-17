/*
  # Add bolt_config table for global settings
  
  1. New Tables
    - `bolt_config` - Stores global application configuration
      - `key` (text, primary key)
      - `value` (jsonb)
      - `updated_at` (timestamp)
  
  2. Security
    - Enable RLS
    - Add policies for admin access
*/

-- Create bolt_config table if it doesn't exist
CREATE TABLE IF NOT EXISTS bolt_config (
  key text PRIMARY KEY,
  value jsonb NOT NULL,
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE bolt_config ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Admins can manage bolt_config" ON bolt_config;
DROP POLICY IF EXISTS "Admins can read bolt_config" ON bolt_config;

-- Create policies for admin access
CREATE POLICY "Admins can manage bolt_config"
  ON bolt_config
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM auth.users 
      WHERE id = auth.uid() 
      AND raw_user_meta_data->>'claims_admin' = 'true'
    )
  );

CREATE POLICY "Anyone can read bolt_config"
  ON bolt_config
  FOR SELECT
  TO authenticated
  USING (true);

-- Insert default values if they don't exist
INSERT INTO bolt_config (key, value)
VALUES ('graph_reset', '{"reset_at": null, "first_user_after_reset_at": null}')
ON CONFLICT (key) DO NOTHING;

-- Function to reset graph data
CREATE OR REPLACE FUNCTION reset_graph_data()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Check if user is admin
  IF NOT EXISTS (
    SELECT 1 
    FROM auth.users 
    WHERE id = auth.uid() 
    AND raw_user_meta_data->>'claims_admin' = 'true'
  ) THEN
    RAISE EXCEPTION 'Permission denied';
  END IF;

  -- Update the bolt_config table with current timestamp
  UPDATE bolt_config
  SET 
    value = jsonb_build_object('reset_at', to_char(now(), 'YYYY-MM-DD"T"HH24:MI:SS"Z"'), 'first_user_after_reset_at', null),
    updated_at = now()
  WHERE key = 'graph_reset';
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION reset_graph_data() TO authenticated;