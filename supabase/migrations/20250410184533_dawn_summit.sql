/*
  # Fix duplicate introduction modules
  
  1. Changes
    - Remove duplicate introduction modules
    - Ensure there's only one introduction module with order=0
    - Make all modules viewable by public
  
  2. Security
    - Update RLS policies for modules and questions
*/

-- Delete any duplicate introduction modules, keeping only the one with the lowest created_at
WITH dupe_intros AS (
  SELECT id, 
         ROW_NUMBER() OVER (ORDER BY created_at) as rn
  FROM modules
  WHERE slug = 'introduction'
)
DELETE FROM modules
WHERE id IN (
  SELECT id FROM dupe_intros WHERE rn > 1
);

-- Ensure the remaining introduction module has order=0
UPDATE modules 
SET "order" = 0
WHERE slug = 'introduction';

-- Make sure all other modules have the correct order
DO $$
BEGIN
  -- Capabilities Inventory (order 1)
  UPDATE modules SET "order" = 1 WHERE slug = 'capabilities-inventory';
  
  -- Strategy Framework (order 2)
  UPDATE modules SET "order" = 2 WHERE slug = 'strategy-framework';
  
  -- Opportunity Map (order 3)
  UPDATE modules SET "order" = 3 WHERE slug = 'opportunity-map';
  
  -- Service Offering Blueprint (order 4)
  UPDATE modules SET "order" = 4 WHERE slug = 'service-offering';
  
  -- Positioning & Differentiation Matrix (order 5)
  UPDATE modules SET "order" = 5 WHERE slug = 'positioning';
  
  -- Pricing Strategy Planner (order 6)
  UPDATE modules SET "order" = 6 WHERE slug = 'pricing';
  
  -- Final Report (order 7)
  UPDATE modules SET "order" = 7 WHERE slug = 'final-report';
END $$;

-- Make sure modules and questions are viewable by public
DROP POLICY IF EXISTS "Everyone can view modules" ON modules;
DROP POLICY IF EXISTS "Modules are viewable by public" ON modules;
DROP POLICY IF EXISTS "Everyone can view questions" ON questions;
DROP POLICY IF EXISTS "Questions are viewable by public" ON questions;

-- Create or replace viewing policies
CREATE POLICY "Modules are viewable by public"
  ON modules FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Questions are viewable by public"
  ON questions FOR SELECT
  TO public
  USING (true);