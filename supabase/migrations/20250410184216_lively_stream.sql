/*
  # Update Strategy Framework Questions
  
  1. Changes
    - Update the questions for the Strategy Framework module
    - Ensure proper ordering of questions
    
  2. Security
    - No security changes needed
*/

-- Update questions for Strategy Framework module
DO $$
DECLARE
  module_strat_fw_id uuid;
BEGIN
  -- Get module ID
  SELECT id INTO module_strat_fw_id FROM modules WHERE slug = 'strategy-framework';

  -- Check if module exists
  IF module_strat_fw_id IS NOT NULL THEN
    -- Delete existing questions for Strategy Framework
    DELETE FROM questions WHERE module_id = module_strat_fw_id;

    -- Insert the updated questions
    INSERT INTO questions (module_id, content, "order") VALUES
      (module_strat_fw_id, 'Describe the work you have been doing, the number of years of experience you have, and the roles you''ve held.', 1),
      (module_strat_fw_id, 'Describe any key projects or achievements that demonstrate your expertise and various capabilities.', 2),
      (module_strat_fw_id, 'What are your 7-10 top skills or strengths (e.g., strategic thinking, leadership, technical expertise). Add as much detail as you can.', 3),
      (module_strat_fw_id, 'What are some concrete examples of how you''ve used these capabilities in your career, your personal life, hobbies, volunteer work, etc.?', 4),
      (module_strat_fw_id, 'What you hope to achieve by starting your own independent consulting practice (e.g., more autonomy, better work–life balance, a new revenue stream).', 5),
      (module_strat_fw_id, 'Are there any geographic, technological, or personal factors that might influence your consulting focus.', 6),
      (module_strat_fw_id, 'How would you describe your ideal work style (e.g., hands-on implementation vs. advisory roles).', 7);
  END IF;
END $$;