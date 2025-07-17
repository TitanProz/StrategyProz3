/*
  # Fix Modules Visibility
  
  1. Changes
    - Ensure modules table exists
    - Fix RLS policies for modules and questions
    - Insert initial modules and questions data if missing
  
  2. Security
    - Update RLS policies for better visibility
    - Ensure both users and admins can see modules
*/

-- Check if modules table exists and create if not
CREATE TABLE IF NOT EXISTS modules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  slug text UNIQUE NOT NULL,
  "order" integer NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Ensure questions table exists
CREATE TABLE IF NOT EXISTS questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  module_id uuid REFERENCES modules(id) ON DELETE CASCADE,
  content text NOT NULL,
  "order" integer NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Fix RLS policies
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Modules are viewable by authenticated users" ON modules;
DROP POLICY IF EXISTS "Questions are viewable by authenticated users" ON questions;

-- Create new policies with broader access
CREATE POLICY "Everyone can view modules"
  ON modules FOR SELECT
  USING (true);

CREATE POLICY "Everyone can view questions"
  ON questions FOR SELECT
  USING (true);

-- Insert initial modules if the table is empty
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM modules LIMIT 1) THEN
    INSERT INTO modules (title, slug, "order") VALUES
      ('Capabilities Inventory', 'capabilities-inventory', 1),
      ('Strategy Framework', 'strategy-framework', 2),
      ('Opportunity Map', 'opportunity-map', 3),
      ('Service Offering Blueprint', 'service-offering', 4),
      ('Positioning & Differentiation Matrix', 'positioning', 5),
      ('Pricing Strategy Planner', 'pricing', 6),
      ('Final Report', 'final-report', 7);
  END IF;
END $$;

-- Insert questions for Capabilities Inventory if they don't exist
DO $$
DECLARE
  cap_inv_id uuid;
BEGIN
  -- Get Capabilities Inventory module ID
  SELECT id INTO cap_inv_id FROM modules WHERE slug = 'capabilities-inventory';
  
  -- Insert questions if none exist for this module
  IF NOT EXISTS (SELECT 1 FROM questions WHERE module_id = cap_inv_id LIMIT 1) THEN
    INSERT INTO questions (module_id, content, "order") VALUES
      (cap_inv_id, 'Describe the work you have been doing, the number of years of experience you have, and the roles you''ve held.', 1),
      (cap_inv_id, 'Describe any key projects or achievements that demonstrate your expertise and various capabilities.', 2),
      (cap_inv_id, 'What are your 7-10 top skills or strengths (e.g., strategic thinking, leadership, technical expertise). Add as much detail as you can.', 3),
      (cap_inv_id, 'What are some concrete examples of how you''ve used these capabilities in your career, your personal life, hobbies, volunteer work, etc.?', 4),
      (cap_inv_id, 'What you hope to achieve by starting your own independent consulting practice (e.g., more autonomy, better work–life balance, a new revenue stream).', 5),
      (cap_inv_id, 'Are there any geographic, technological, or personal factors that might influence your consulting focus.', 6),
      (cap_inv_id, 'How would you describe your ideal work style (e.g., hands-on implementation vs. advisory roles).', 7);
  END IF;
END $$;

-- Grant necessary permissions
GRANT ALL ON TABLE modules TO authenticated;
GRANT ALL ON TABLE questions TO authenticated;