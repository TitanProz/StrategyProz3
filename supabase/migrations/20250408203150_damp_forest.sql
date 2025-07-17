/*
  # Fix Questions Data Migration
  
  1. Changes
    - Insert questions for empty modules
    - Proper variable naming to avoid ambiguity
    - Safe DB operations with existence checks
  
  2. Security
    - No security changes needed
*/

-- Insert questions for each module if they don't exist
DO $$ 
DECLARE
  cap_inv_count integer := 0;
  strat_fw_count integer := 0;
  opp_map_count integer := 0;
  serv_off_count integer := 0;
  pos_count integer := 0;
  pricing_count integer := 0;
  
  module_cap_inv_id uuid;
  module_strat_fw_id uuid;
  module_opp_map_id uuid;
  module_serv_off_id uuid;
  module_pos_id uuid;
  module_pricing_id uuid;
BEGIN
  -- Get module IDs
  SELECT id INTO module_cap_inv_id FROM modules WHERE slug = 'capabilities-inventory';
  SELECT id INTO module_strat_fw_id FROM modules WHERE slug = 'strategy-framework';
  SELECT id INTO module_opp_map_id FROM modules WHERE slug = 'opportunity-map';
  SELECT id INTO module_serv_off_id FROM modules WHERE slug = 'service-offering';
  SELECT id INTO module_pos_id FROM modules WHERE slug = 'positioning';
  SELECT id INTO module_pricing_id FROM modules WHERE slug = 'pricing';
  
  -- Count questions for each module directly without using a function
  IF module_cap_inv_id IS NOT NULL THEN
    SELECT COUNT(*) INTO cap_inv_count FROM questions WHERE module_id = module_cap_inv_id;
  END IF;
  
  IF module_strat_fw_id IS NOT NULL THEN
    SELECT COUNT(*) INTO strat_fw_count FROM questions WHERE module_id = module_strat_fw_id;
  END IF;
  
  IF module_opp_map_id IS NOT NULL THEN
    SELECT COUNT(*) INTO opp_map_count FROM questions WHERE module_id = module_opp_map_id;
  END IF;
  
  IF module_serv_off_id IS NOT NULL THEN
    SELECT COUNT(*) INTO serv_off_count FROM questions WHERE module_id = module_serv_off_id;
  END IF;
  
  IF module_pos_id IS NOT NULL THEN
    SELECT COUNT(*) INTO pos_count FROM questions WHERE module_id = module_pos_id;
  END IF;
  
  IF module_pricing_id IS NOT NULL THEN
    SELECT COUNT(*) INTO pricing_count FROM questions WHERE module_id = module_pricing_id;
  END IF;
  
  -- Insert questions for Capabilities Inventory if needed
  IF cap_inv_count = 0 AND module_cap_inv_id IS NOT NULL THEN
    INSERT INTO questions (module_id, content, "order") VALUES
      (module_cap_inv_id, 'Describe the work you have been doing, the number of years of experience you have, and the roles you''ve held.', 1),
      (module_cap_inv_id, 'Describe any key projects or achievements that demonstrate your expertise and various capabilities.', 2),
      (module_cap_inv_id, 'What are your 7-10 top skills or strengths (e.g., strategic thinking, leadership, technical expertise). Add as much detail as you can.', 3),
      (module_cap_inv_id, 'What are some concrete examples of how you''ve used these capabilities in your career, your personal life, hobbies, volunteer work, etc.?', 4),
      (module_cap_inv_id, 'What you hope to achieve by starting your own independent consulting practice (e.g., more autonomy, better work–life balance, a new revenue stream).', 5),
      (module_cap_inv_id, 'Are there any geographic, technological, or personal factors that might influence your consulting focus.', 6),
      (module_cap_inv_id, 'How would you describe your ideal work style (e.g., hands-on implementation vs. advisory roles).', 7);
  END IF;

  -- Insert questions for Strategy Framework if needed
  IF strat_fw_count = 0 AND module_strat_fw_id IS NOT NULL THEN
    INSERT INTO questions (module_id, content, "order") VALUES
      (module_strat_fw_id, 'Now that you have chosen your niche provide a clear description of the particular consulting practice you intend to pursue? (for example, "DEI strategy for mid-market tech companies" or "process optimization for healthcare providers").', 1),
      (module_strat_fw_id, 'What are the specific types of problems you plan to solve or the outcomes you feel you can provide to your clients?(e.g., "improve team engagement and retention," "reduce operational inefficiencies").', 2),
      (module_strat_fw_id, 'Do you have any examples or case studies that demonstrate how you might have solved these problems or delivered similar outcomes in previous roles?', 3),
      (module_strat_fw_id, 'Please add any metrics or tangible results (like "increased revenue by X%," "improved efficiency by Y%") that illustrate the value you can deliver.', 4),
      (module_strat_fw_id, 'Describe any transformational benefits your consulting efforts could provide to clients (e.g., "helping clients transition to agile cultures," "unlocking hidden growth opportunities through data-driven insights", help them declutter their closets and their lives").', 5),
      (module_strat_fw_id, 'How do your skills, capabilities, strengths, and experiences set you apart from competitors in terms of approach, methodology, or mindset?', 6),
      (module_strat_fw_id, 'Are there any other more specific details about the clients you wish to serve—such as company size (startups, mid-market, large enterprises), the decision-makers (CEOs, HR Directors, Marketing Managers), and their typical challenges or pain points?', 7),
      (module_strat_fw_id, 'Are there any relevant demographics (e.g., geographic regions, industry segments, market maturity) that should influence which industries you should target.', 8),
      (module_strat_fw_id, 'Share any insights on competitors in your intended niche in terms of what they are doing and where you believe you can offer something different or superior.', 9),
      (module_strat_fw_id, 'List any the gaps in the current market that your experience and skills can uniquely address.', 10);
  END IF;

  -- Insert questions for Opportunity Map if needed
  IF opp_map_count = 0 AND module_opp_map_id IS NOT NULL THEN
    INSERT INTO questions (module_id, content, "order") VALUES
      (module_opp_map_id, 'Provide a clear and detailed description of each service you plan to offer (e.g., "DEI strategy workshops," "retainer-based HR audits," "process optimization assessments").', 1),
      (module_opp_map_id, 'For each service detail:
• Who are the specific groups or individuals that will be receiving the services
• What are the key deliverables that are a part of the service
• How you intend for the service to be structured (e.g., one-off engagement, ongoing retainer, group training session).', 2),
      (module_opp_map_id, 'Share any information on your service delivery style (hands-on, advisory, hybrid) and any preliminary ideas about pricing models or value packages.', 3),
      (module_opp_map_id, 'How do you envision clients interacting with these services (e.g., online sessions, on-site workshops).', 4),
      (module_opp_map_id, 'Provide any additional details on your ideal client characteristics—such as company size, specific decision-maker roles, geographic regions, and industry segments.', 5),
      (module_opp_map_id, 'List any known pain points or challenges these clients typically face that your services will address.', 6),
      (module_opp_map_id, 'Provide any examples or summaries of what competitors are offering in your niche, including their strengths and weaknesses.', 7),
      (module_opp_map_id, 'Share any insights or projections you have on the demand, ease of entry, and profitability for each service or client segment.', 8),
      (module_opp_map_id, 'List any potential obstacles you anticipate for each service/client combination (like regulatory hurdles, resource limitations, or fierce competition).', 9),
      (module_opp_map_id, 'List any known legal, financial, or technological constraints that could impact service delivery.', 10);
  END IF;

  -- Insert questions for Service Offering Blueprint if needed
  IF serv_off_count = 0 AND module_serv_off_id IS NOT NULL THEN
    INSERT INTO questions (module_id, content, "order") VALUES
      (module_serv_off_id, 'Share these same details from your Opportunity Map inputs:
a) Provide a clear and detailed description of each service you plan to offer
b) Who are the specific groups or individuals that will be receiving the services
c) What are the key deliverables that are a part of the service
d) How you intend for the service to be structured', 1),
      (module_serv_off_id, 'List any concrete outcomes you believe you can deliver (such as "reduce operational inefficiencies by 15%," "improve employee retention by 10%"), along with any case studies, success stories, or quantitative metrics.', 2),
      (module_serv_off_id, 'List any additional value-added elements you can offer (like personalized support, exclusive industry insights, access to a network of experts, or tailored follow-up resources) and how these differentiate you from competitors.', 3),
      (module_serv_off_id, 'Identify your initial thoughts on structuring your services into tiered packages. Include ideas for what might be in each tier (e.g., level of support, frequency of consultations, additional deliverables) and any preliminary pricing ideas.
a) Basic
b) Mid-level
c) Premium', 4),
      (module_serv_off_id, 'List any potential enhancements or follow-on services that could be offered after the initial service delivery that would ensure continuous engagement and broader support.—(such as advanced workshops, ongoing retainer services, or digital courses)', 5),
      (module_serv_off_id, 'Share any detailed characteristics of your ideal clients (company size, decision-maker roles, industry segments, geographic areas, typical pain points) and any other data that indicates where your services might be most in demand.', 6),
      (module_serv_off_id, 'Share how you plan to test and validate your service packages (pilot programs, surveys, A/B testing, client interviews) and any initial feedback you may have already received that could influence your packaging and pricing strategy.', 7);
  END IF;

  -- Insert questions for Positioning & Differentiation Matrix if needed
  IF pos_count = 0 AND module_pos_id IS NOT NULL THEN
    INSERT INTO questions (module_id, content, "order") VALUES
      (module_pos_id, 'Share these same details from your Opportunity Map inputs:
a) Provide a clear and detailed description of each service you plan to offer
b) Who are the specific groups or individuals that will be receiving the services
c) What are the key deliverables that are a part of the service
d) How you intend for the service to be structured', 1),
      (module_pos_id, 'What are any unique methods, insights, or approaches you plan to implement that competitors might overlook.', 2),
      (module_pos_id, 'Explain why these aspects set you apart.', 3),
      (module_pos_id, 'If you plan to offer tiered packages (basic, mid-level, premium), describe what each tier includes (e.g., level of support, frequency of consultations, additional deliverables).', 4),
      (module_pos_id, 'List detailed characteristics of your ideal clients such as:
a) Company size (startups, mid-market, large enterprises)
b) Key decision-makers (CEOs, HR Directors, Marketing Managers)
c) Geographic regions
d) Any common challenges they face.', 5),
      (module_pos_id, 'Share any specific examples of what competitors in your intended niche are currently offering:
a) Types of service
b) What they seem to do well
c) What they seem to do poorly
d) Any insights on pricing strategy', 6),
      (module_pos_id, 'Describe the gaps you see in competitors'' offerings', 7),
      (module_pos_id, 'Share why your approach or methodology is superior.', 8),
      (module_pos_id, 'How would you plan to address needs that aren''t currently met?', 9),
      (module_pos_id, 'What messaging, taglines, or branding elements do you aspire to use', 10),
      (module_pos_id, 'Share your value proposition.', 11);
  END IF;

  -- Insert questions for Pricing Strategy Planner if needed
  IF pricing_count = 0 AND module_pricing_id IS NOT NULL THEN
    INSERT INTO questions (module_id, content, "order") VALUES
      (module_pricing_id, 'Share the breakdown of what''s included in a basic, mid-level, and premium services if that they are structured that way', 1),
      (module_pricing_id, 'Share the specific outcomes you plan to deliver (with metrics if available)', 2),
      (module_pricing_id, 'List any examples of competitors'' pricing models (hourly rates, project fees, retainer amounts) that you know or have researched.', 3),
      (module_pricing_id, 'Share any transformational benefits you plan to offer and how they set you apart from competitors.', 4),
      (module_pricing_id, 'List any aspects of your services or delivery methods that could justify a premium value?', 5),
      (module_pricing_id, 'What revenue targets do you have in mind?', 6),
      (module_pricing_id, 'Are there any constraints or cost structures (operational expenses, desired profit margins) that influence your pricing strategy.', 7);
  END IF;
END $$;