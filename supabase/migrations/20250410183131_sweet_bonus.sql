/*
  # Ensure modules and questions match specifications
  
  1. Changes
    - Ensure all modules exist with correct order and titles
    - Ensure all questions exist for each module with proper content
    - Fix module and question ordering
  
  2. Security
    - Maintain existing RLS policies
*/

-- Make sure modules table exists
CREATE TABLE IF NOT EXISTS modules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  slug text UNIQUE NOT NULL,
  "order" integer NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Make sure questions table exists
CREATE TABLE IF NOT EXISTS questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  module_id uuid REFERENCES modules(id) ON DELETE CASCADE,
  content text NOT NULL,
  "order" integer NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS on modules and questions
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DO $$ 
BEGIN
  -- For modules
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'modules' AND policyname = 'Modules are viewable by public'
  ) THEN
    CREATE POLICY "Modules are viewable by public"
      ON modules FOR SELECT
      TO public
      USING (true);
  END IF;
  
  -- For questions
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'questions' AND policyname = 'Questions are viewable by public'
  ) THEN
    CREATE POLICY "Questions are viewable by public"
      ON questions FOR SELECT
      TO public
      USING (true);
  END IF;
END $$;

-- Ensure all required modules exist in the correct order
DO $$ 
DECLARE
  intro_id uuid;
  cap_inv_id uuid;
  strat_fw_id uuid;
  opp_map_id uuid;
  serv_off_id uuid;
  positioning_id uuid;
  pricing_id uuid;
  final_report_id uuid;
BEGIN
  -- Insert or update modules
  
  -- Introduction (order 0)
  IF NOT EXISTS (SELECT 1 FROM modules WHERE slug = 'introduction') THEN
    INSERT INTO modules (title, slug, "order") VALUES
      ('Introduction', 'introduction', 0);
  ELSE
    UPDATE modules SET "order" = 0, title = 'Introduction' WHERE slug = 'introduction';
  END IF;
  
  -- Capabilities Inventory (order 1)
  IF NOT EXISTS (SELECT 1 FROM modules WHERE slug = 'capabilities-inventory') THEN
    INSERT INTO modules (title, slug, "order") VALUES
      ('Capabilities Inventory', 'capabilities-inventory', 1);
  ELSE
    UPDATE modules SET "order" = 1, title = 'Capabilities Inventory' WHERE slug = 'capabilities-inventory';
  END IF;
  
  -- Strategy Framework (order 2)
  IF NOT EXISTS (SELECT 1 FROM modules WHERE slug = 'strategy-framework') THEN
    INSERT INTO modules (title, slug, "order") VALUES
      ('Strategy Framework', 'strategy-framework', 2);
  ELSE
    UPDATE modules SET "order" = 2, title = 'Strategy Framework' WHERE slug = 'strategy-framework';
  END IF;
  
  -- Opportunity Map (order 3)
  IF NOT EXISTS (SELECT 1 FROM modules WHERE slug = 'opportunity-map') THEN
    INSERT INTO modules (title, slug, "order") VALUES
      ('Opportunity Map', 'opportunity-map', 3);
  ELSE
    UPDATE modules SET "order" = 3, title = 'Opportunity Map' WHERE slug = 'opportunity-map';
  END IF;
  
  -- Service Offering Blueprint (order 4)
  IF NOT EXISTS (SELECT 1 FROM modules WHERE slug = 'service-offering') THEN
    INSERT INTO modules (title, slug, "order") VALUES
      ('Service Offering Blueprint', 'service-offering', 4);
  ELSE
    UPDATE modules SET "order" = 4, title = 'Service Offering Blueprint' WHERE slug = 'service-offering';
  END IF;
  
  -- Positioning & Differentiation Matrix (order 5)
  IF NOT EXISTS (SELECT 1 FROM modules WHERE slug = 'positioning') THEN
    INSERT INTO modules (title, slug, "order") VALUES
      ('Positioning & Differentiation Matrix', 'positioning', 5);
  ELSE
    UPDATE modules SET "order" = 5, title = 'Positioning & Differentiation Matrix' WHERE slug = 'positioning';
  END IF;
  
  -- Pricing Strategy Planner (order 6)
  IF NOT EXISTS (SELECT 1 FROM modules WHERE slug = 'pricing') THEN
    INSERT INTO modules (title, slug, "order") VALUES
      ('Pricing Strategy Planner', 'pricing', 6);
  ELSE
    UPDATE modules SET "order" = 6, title = 'Pricing Strategy Planner' WHERE slug = 'pricing';
  END IF;
  
  -- Final Report (order 7)
  IF NOT EXISTS (SELECT 1 FROM modules WHERE slug = 'final-report') THEN
    INSERT INTO modules (title, slug, "order") VALUES
      ('Final Report', 'final-report', 7);
  ELSE
    UPDATE modules SET "order" = 7, title = 'Final Report' WHERE slug = 'final-report';
  END IF;

  -- Get all module IDs
  SELECT id INTO intro_id FROM modules WHERE slug = 'introduction';
  SELECT id INTO cap_inv_id FROM modules WHERE slug = 'capabilities-inventory';
  SELECT id INTO strat_fw_id FROM modules WHERE slug = 'strategy-framework';
  SELECT id INTO opp_map_id FROM modules WHERE slug = 'opportunity-map';
  SELECT id INTO serv_off_id FROM modules WHERE slug = 'service-offering';
  SELECT id INTO positioning_id FROM modules WHERE slug = 'positioning';
  SELECT id INTO pricing_id FROM modules WHERE slug = 'pricing';
  SELECT id INTO final_report_id FROM modules WHERE slug = 'final-report';

  -- Ensure Introduction module has questions
  IF NOT EXISTS (SELECT 1 FROM questions WHERE module_id = intro_id) THEN
    INSERT INTO questions (module_id, content, "order") VALUES
      (intro_id, 'Welcome to the Consulting Course Platform. This introduction will guide you through the process of developing your consulting strategy.', 1),
      (intro_id, 'Throughout this course, you will answer questions across several modules to help define your consulting practice, target market, service offerings, and pricing strategy.', 2),
      (intro_id, 'Click "Continue" to proceed to the first module: Capabilities Inventory.', 3);
  END IF;

  -- Ensure Capabilities Inventory module has the correct questions
  DELETE FROM questions WHERE module_id = cap_inv_id;
  INSERT INTO questions (module_id, content, "order") VALUES
    (cap_inv_id, 'Describe the work you have been doing, the number of years of experience you have, and the roles you''ve held.', 1),
    (cap_inv_id, 'Describe any key projects or achievements that demonstrate your expertise and various capabilities.', 2),
    (cap_inv_id, 'What are your 7-10 top skills or strengths (e.g., strategic thinking, leadership, technical expertise). Add as much detail as you can.', 3),
    (cap_inv_id, 'What are some concrete examples of how you''ve used these capabilities in your career, your personal life, hobbies, volunteer work, etc.?', 4),
    (cap_inv_id, 'What you hope to achieve by starting your own independent consulting practice (e.g., more autonomy, better work–life balance, a new revenue stream).', 5),
    (cap_inv_id, 'Are there any geographic, technological, or personal factors that might influence your consulting focus.', 6),
    (cap_inv_id, 'How would you describe your ideal work style (e.g., hands-on implementation vs. advisory roles).', 7);

  -- Ensure Strategy Framework module has the correct questions
  DELETE FROM questions WHERE module_id = strat_fw_id;
  INSERT INTO questions (module_id, content, "order") VALUES
    (strat_fw_id, 'Now that you have chosen your niche, provide a description of your consulting practice.', 1),
    (strat_fw_id, 'What specific types of problems do you plan to solve?', 2),
    (strat_fw_id, 'Do you have any examples or case studies to support your solutions?', 3),
    (strat_fw_id, 'Provide any metrics or tangible results that illustrate the value you can deliver.', 4),
    (strat_fw_id, 'Describe any transformational benefits your consulting efforts could provide.', 5),
    (strat_fw_id, 'How do your skills, capabilities, and experience set you apart from competitors?', 6),
    (strat_fw_id, 'Are there any additional details regarding the client profiles you wish to serve?', 7),
    (strat_fw_id, 'Are there any demographic factors that should influence your consulting focus?', 8),
    (strat_fw_id, 'Share any insights on competitors in your intended niche.', 9),
    (strat_fw_id, 'List any gaps you see in the current market.', 10);

  -- Ensure Opportunity Map module has the correct questions
  DELETE FROM questions WHERE module_id = opp_map_id;
  INSERT INTO questions (module_id, content, "order") VALUES
    (opp_map_id, 'Provide a clear and detailed description of each service you plan to offer (e.g., "DEI strategy workshops," "retainer-based HR audits," "process optimization assessments").', 1),
    (opp_map_id, 'For each service detail:
• Who are the specific groups or individuals that will be receiving the services
• What are the key deliverables that are a part of the service
• How you intend for the service to be structured (e.g., one-off engagement, ongoing retainer, group training session).', 2),
    (opp_map_id, 'Share any information on your service delivery style (hands-on, advisory, hybrid) and any preliminary ideas about pricing models or value packages.', 3),
    (opp_map_id, 'How do you envision clients interacting with these services (e.g., online sessions, on-site workshops).', 4),
    (opp_map_id, 'Provide any additional details on your ideal client characteristics—such as company size, specific decision-maker roles, geographic regions, and industry segments.', 5),
    (opp_map_id, 'List any known pain points or challenges these clients typically face that your services will address.', 6),
    (opp_map_id, 'Provide any examples or summaries of what competitors are offering in your niche, including their strengths and weaknesses.', 7),
    (opp_map_id, 'Share any insights or projections you have on the demand, ease of entry, and profitability for each service or client segment.', 8),
    (opp_map_id, 'List any potential obstacles you anticipate for each service/client combination (like regulatory hurdles, resource limitations, or fierce competition).', 9),
    (opp_map_id, 'List any known legal, financial, or technological constraints that could impact service delivery.', 10);

  -- Ensure Service Offering Blueprint module has the correct questions
  DELETE FROM questions WHERE module_id = serv_off_id;
  INSERT INTO questions (module_id, content, "order") VALUES
    (serv_off_id, 'Share these same details from your Opportunity Map inputs:
a) Provide a clear and detailed description of each service you plan to offer
b) Who are the specific groups or individuals that will be receiving the services
c) What are the key deliverables that are a part of the service
d) How you intend for the service to be structured', 1),
    (serv_off_id, 'List any concrete outcomes you believe you can deliver (such as "reduce operational inefficiencies by 15%," "improve employee retention by 10%"), along with any case studies, success stories, or quantitative metrics.', 2),
    (serv_off_id, 'List any additional value-added elements you can offer (like personalized support, exclusive industry insights, access to a network of experts, or tailored follow-up resources) and how these differentiate you from competitors.', 3),
    (serv_off_id, 'Identify your initial thoughts on structuring your services into tiered packages. Include ideas for what might be in each tier (e.g., level of support, frequency of consultations, additional deliverables) and any preliminary pricing ideas.
a) Basic
b) Mid-level
c) Premium', 4),
    (serv_off_id, 'List any potential enhancements or follow-on services that could be offered after the initial service delivery that would ensure continuous engagement and broader support.—(such as advanced workshops, ongoing retainer services, or digital courses)', 5),
    (serv_off_id, 'Share any detailed characteristics of your ideal clients (company size, decision-maker roles, industry segments, geographic areas, typical pain points) and any other data that indicates where your services might be most in demand.', 6),
    (serv_off_id, 'Share how you plan to test and validate your service packages (pilot programs, surveys, A/B testing, client interviews) and any initial feedback you may have already received that could influence your packaging and pricing strategy.', 7);

  -- Ensure Positioning & Differentiation Matrix module has the correct questions
  DELETE FROM questions WHERE module_id = positioning_id;
  INSERT INTO questions (module_id, content, "order") VALUES
    (positioning_id, 'Share these same details from your Opportunity Map inputs:
a) Provide a clear and detailed description of each service you plan to offer
b) Who are the specific groups or individuals that will be receiving the services
c) What are the key deliverables that are a part of the service
d) How you intend for the service to be structured', 1),
    (positioning_id, 'What are any unique methods, insights, or approaches you plan to implement that competitors might overlook.', 2),
    (positioning_id, 'Explain why these aspects set you apart.', 3),
    (positioning_id, 'If you plan to offer tiered packages (basic, mid-level, premium), describe what each tier includes (e.g., level of support, frequency of consultations, additional deliverables).', 4),
    (positioning_id, 'List detailed characteristics of your ideal clients such as:
a) Company size (startups, mid-market, large enterprises)
b) Key decision-makers (CEOs, HR Directors, Marketing Managers)
c) Geographic regions
d) Any common challenges they face.', 5),
    (positioning_id, 'Share any specific examples of what competitors in your intended niche are currently offering:
a) Types of service
b) What they seem to do well
c) What they seem to do poorly
d) Any insights on pricing strategy', 6),
    (positioning_id, 'Describe the gaps you see in competitors'' offerings', 7),
    (positioning_id, 'Share why your approach or methodology is superior.', 8),
    (positioning_id, 'How would you plan to address needs that aren''t currently met?', 9),
    (positioning_id, 'What messaging, taglines, or branding elements do you aspire to use', 10),
    (positioning_id, 'Share your value proposition.', 11);

  -- Ensure Pricing Strategy Planner module has the correct questions
  DELETE FROM questions WHERE module_id = pricing_id;
  INSERT INTO questions (module_id, content, "order") VALUES
    (pricing_id, 'Share the breakdown of what''s included in a basic, mid-level, and premium services if that they are structured that way', 1),
    (pricing_id, 'Share the specific outcomes you plan to deliver (with metrics if available)', 2),
    (pricing_id, 'List any examples of competitors'' pricing models (hourly rates, project fees, retainer amounts) that you know or have researched.', 3),
    (pricing_id, 'Share any transformational benefits you plan to offer and how they set you apart from competitors.', 4),
    (pricing_id, 'List any aspects of your services or delivery methods that could justify a premium value?', 5),
    (pricing_id, 'What revenue targets do you have in mind?', 6),
    (pricing_id, 'Are there any constraints or cost structures (operational expenses, desired profit margins) that influence your pricing strategy.', 7);

  -- Ensure Final Report module has appropriate questions if needed
  IF NOT EXISTS (SELECT 1 FROM questions WHERE module_id = final_report_id) THEN
    INSERT INTO questions (module_id, content, "order") VALUES
      (final_report_id, 'Click "Generate" to create your comprehensive consulting strategy report based on all your previous responses.', 1);
  END IF;
END $$;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_questions_module_id ON questions(module_id);
CREATE INDEX IF NOT EXISTS idx_modules_order ON modules("order");
CREATE INDEX IF NOT EXISTS idx_modules_slug ON modules(slug);