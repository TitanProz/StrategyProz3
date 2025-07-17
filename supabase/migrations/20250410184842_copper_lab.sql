/*
  # Delete Introduction Module
  
  1. Changes
    - Delete the introduction module
    - Delete associated questions
    - Ensure proper module ordering
*/

-- Delete the introduction module and its questions (cascade will handle questions)
DELETE FROM modules WHERE slug = 'introduction';

-- Ensure proper module ordering
UPDATE modules 
SET "order" = "order" - 1
WHERE "order" > 0;