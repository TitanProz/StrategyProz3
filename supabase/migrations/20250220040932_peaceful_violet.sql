/*
  # Add detailed questions for each module

  1. Changes
    - Delete existing questions
    - Add new comprehensive questions for each module
    - Maintain proper ordering and module associations

  2. Security
    - Maintains existing RLS policies
*/

-- Delete existing questions
DELETE FROM questions;

-- Insert questions for Capabilities Inventory
INSERT INTO questions (module_id, content, "order") VALUES
  ((SELECT id FROM modules WHERE slug = 'capabilities-inventory'), 'Describe the work you have been doing, the number of years of experience you have, and the roles you''ve held.', 1),
  ((SELECT id FROM modules WHERE slug = 'capabilities-inventory'), 'Describe any key projects or achievements that demonstrate your expertise and various capabilities.', 2),
  ((SELECT id FROM modules WHERE slug = 'capabilities-inventory'), 'What are your 7-10 top skills or strengths (e.g., strategic thinking, leadership, technical expertise). Add as much detail as you can.', 3),
  ((SELECT id FROM modules WHERE slug = 'capabilities-inventory'), 'What are some concrete examples of how you''ve used these capabilities in your career, your personal life, hobbies, volunteer work, etc.?', 4),
  ((SELECT id FROM modules WHERE slug = 'capabilities-inventory'), 'What you hope to achieve by starting your own independent consulting practice (e.g., more autonomy, better work–life balance, a new revenue stream).', 5),
  ((SELECT id FROM modules WHERE slug = 'capabilities-inventory'), 'Are there any geographic, technological, or personal factors that might influence your consulting focus.', 6),
  ((SELECT id FROM modules WHERE slug = 'capabilities-inventory'), 'How would you describe your ideal work style (e.g., hands-on implementation vs. advisory roles).', 7);

-- Insert questions for Strategy Framework
INSERT INTO questions (module_id, content, "order") VALUES
  ((SELECT id FROM modules WHERE slug = 'strategy-framework'), 'Now that you have chosen your niche provide a clear description of the particular consulting practice you intend to pursue? (for example, "DEI strategy for mid-market tech companies" or "process optimization for healthcare providers").', 1),
  ((SELECT id FROM modules WHERE slug = 'strategy-framework'), 'What are the specific types of problems you plan to solve or the outcomes you feel you can provide to your clients?(e.g., "improve team engagement and retention," "reduce operational inefficiencies").', 2),
  ((SELECT id FROM modules WHERE slug = 'strategy-framework'), 'Do you have any examples or case studies that demonstrate how you might have solved these problems or delivered similar outcomes in previous roles?', 3),
  ((SELECT id FROM modules WHERE slug = 'strategy-framework'), 'Please add any metrics or tangible results (like "increased revenue by X%," "improved efficiency by Y%") that illustrate the value you can deliver.', 4),
  ((SELECT id FROM modules WHERE slug = 'strategy-framework'), 'Describe any transformational benefits your consulting efforts could provide to clients (e.g., "helping clients transition to agile cultures," "unlocking hidden growth opportunities through data-driven insights", help them declutter their closets and their lives").', 5),
  ((SELECT id FROM modules WHERE slug = 'strategy-framework'), 'How do your skills, capabilities, strengths, and experiences set you apart from competitors in terms of approach, methodology, or mindset?', 6),
  ((SELECT id FROM modules WHERE slug = 'strategy-framework'), 'Are there any other more specific details about the clients you wish to serve—such as company size (startups, mid-market, large enterprises), the decision-makers (CEOs, HR Directors, Marketing Managers), and their typical challenges or pain points?', 7),
  ((SELECT id FROM modules WHERE slug = 'strategy-framework'), 'Are there any relevant demographics (e.g., geographic regions, industry segments, market maturity) that should influence which industries you should target.', 8),
  ((SELECT id FROM modules WHERE slug = 'strategy-framework'), 'Share any insights on competitors in your intended niche in terms of what they are doing and where you believe you can offer something different or superior.', 9),
  ((SELECT id FROM modules WHERE slug = 'strategy-framework'), 'List any the gaps in the current market that your experience and skills can uniquely address.', 10);

-- Insert questions for Opportunity Map
INSERT INTO questions (module_id, content, "order") VALUES
  ((SELECT id FROM modules WHERE slug = 'opportunity-map'), 'Provide a clear and detailed description of each service you plan to offer (e.g., "DEI strategy workshops," "retainer-based HR audits," "process optimization assessments").', 1),
  ((SELECT id FROM modules WHERE slug = 'opportunity-map'), 'For each service detail:
• Who are the specific groups or individuals that will be receiving the services
• What are the key deliverables that are a part of the service
• How you intend for the service to be structured (e.g., one-off engagement, ongoing retainer, group training session).', 2),
  ((SELECT id FROM modules WHERE slug = 'opportunity-map'), 'Share any information on your service delivery style (hands-on, advisory, hybrid) and any preliminary ideas about pricing models or value packages.', 3),
  ((SELECT id FROM modules WHERE slug = 'opportunity-map'), 'How do you envision clients interacting with these services (e.g., online sessions, on-site workshops).', 4),
  ((SELECT id FROM modules WHERE slug = 'opportunity-map'), 'Provide any additional details on your ideal client characteristics—such as company size, specific decision-maker roles, geographic regions, and industry segments.', 5),
  ((SELECT id FROM modules WHERE slug = 'opportunity-map'), 'List any known pain points or challenges these clients typically face that your services will address.', 6),
  ((SELECT id FROM modules WHERE slug = 'opportunity-map'), 'Provide any examples or summaries of what competitors are offering in your niche, including their strengths and weaknesses.', 7),
  ((SELECT id FROM modules WHERE slug = 'opportunity-map'), 'Share any insights or projections you have on the demand, ease of entry, and profitability for each service or client segment.', 8),
  ((SELECT id FROM modules WHERE slug = 'opportunity-map'), 'List any potential obstacles you anticipate for each service/client combination (like regulatory hurdles, resource limitations, or fierce competition).', 9),
  ((SELECT id FROM modules WHERE slug = 'opportunity-map'), 'List any known legal, financial, or technological constraints that could impact service delivery.', 10);

-- Insert questions for Service Offering Blueprint
INSERT INTO questions (module_id, content, "order") VALUES
  ((SELECT id FROM modules WHERE slug = 'service-offering'), 'Share these same details from your Opportunity Map inputs:
a) Provide a clear and detailed description of each service you plan to offer
b) Who are the specific groups or individuals that will be receiving the services
c) What are the key deliverables that are a part of the service
d) How you intend for the service to be structured', 1),
  ((SELECT id FROM modules WHERE slug = 'service-offering'), 'List any concrete outcomes you believe you can deliver (such as "reduce operational inefficiencies by 15%," "improve employee retention by 10%"), along with any case studies, success stories, or quantitative metrics.', 2),
  ((SELECT id FROM modules WHERE slug = 'service-offering'), 'List any additional value-added elements you can offer (like personalized support, exclusive industry insights, access to a network of experts, or tailored follow-up resources) and how these differentiate you from competitors.', 3),
  ((SELECT id FROM modules WHERE slug = 'service-offering'), 'Identify your initial thoughts on structuring your services into tiered packages. Include ideas for what might be in each tier (e.g., level of support, frequency of consultations, additional deliverables) and any preliminary pricing ideas.
a) Basic
b) Mid-level
c) Premium', 4),
  ((SELECT id FROM modules WHERE slug = 'service-offering'), 'List any potential enhancements or follow-on services that could be offered after the initial service delivery that would ensure continuous engagement and broader support.—(such as advanced workshops, ongoing retainer services, or digital courses)', 5),
  ((SELECT id FROM modules WHERE slug = 'service-offering'), 'Share any detailed characteristics of your ideal clients (company size, decision-maker roles, industry segments, geographic areas, typical pain points) and any other data that indicates where your services might be most in demand.', 6),
  ((SELECT id FROM modules WHERE slug = 'service-offering'), 'Share how you plan to test and validate your service packages (pilot programs, surveys, A/B testing, client interviews) and any initial feedback you may have already received that could influence your packaging and pricing strategy.', 7);

-- Insert questions for Positioning & Differentiation Matrix
INSERT INTO questions (module_id, content, "order") VALUES
  ((SELECT id FROM modules WHERE slug = 'positioning'), 'Share these same details from your Opportunity Map inputs:
a) Provide a clear and detailed description of each service you plan to offer
b) Who are the specific groups or individuals that will be receiving the services
c) What are the key deliverables that are a part of the service
d) How you intend for the service to be structured', 1),
  ((SELECT id FROM modules WHERE slug = 'positioning'), 'What are any unique methods, insights, or approaches you plan to implement that competitors might overlook.', 2),
  ((SELECT id FROM modules WHERE slug = 'positioning'), 'Explain why these aspects set you apart.', 3),
  ((SELECT id FROM modules WHERE slug = 'positioning'), 'If you plan to offer tiered packages (basic, mid-level, premium), describe what each tier includes (e.g., level of support, frequency of consultations, additional deliverables).', 4),
  ((SELECT id FROM modules WHERE slug = 'positioning'), 'List detailed characteristics of your ideal clients such as:
a) Company size (startups, mid-market, large enterprises)
b) Key decision-makers (CEOs, HR Directors, Marketing Managers)
c) Geographic regions
d) Any common challenges they face.', 5),
  ((SELECT id FROM modules WHERE slug = 'positioning'), 'Share any specific examples of what competitors in your intended niche are currently offering:
a) Types of service
b) What they seem to do well
c) What they seem to do poorly
d) Any insights on pricing strategy', 6),
  ((SELECT id FROM modules WHERE slug = 'positioning'), 'Describe the gaps you see in competitors'' offerings', 7),
  ((SELECT id FROM modules WHERE slug = 'positioning'), 'Share why your approach or methodology is superior.', 8),
  ((SELECT id FROM modules WHERE slug = 'positioning'), 'How would you plan to address needs that aren''t currently met?', 9),
  ((SELECT id FROM modules WHERE slug = 'positioning'), 'What messaging, taglines, or branding elements do you aspire to use', 10),
  ((SELECT id FROM modules WHERE slug = 'positioning'), 'Share your value proposition.', 11);

-- Insert questions for Pricing Strategy Planner
INSERT INTO questions (module_id, content, "order") VALUES
  ((SELECT id FROM modules WHERE slug = 'pricing'), 'Share the breakdown of what''s included in a basic, mid-level, and premium services if that they are structured that way', 1),
  ((SELECT id FROM modules WHERE slug = 'pricing'), 'Share the specific outcomes you plan to deliver (with metrics if available)', 2),
  ((SELECT id FROM modules WHERE slug = 'pricing'), 'List any examples of competitors'' pricing models (hourly rates, project fees, retainer amounts) that you know or have researched.', 3),
  ((SELECT id FROM modules WHERE slug = 'pricing'), 'Share any transformational benefits you plan to offer and how they set you apart from competitors.', 4),
  ((SELECT id FROM modules WHERE slug = 'pricing'), 'List any aspects of your services or delivery methods that could justify a premium value?', 5),
  ((SELECT id FROM modules WHERE slug = 'pricing'), 'What revenue targets do you have in mind?', 6),
  ((SELECT id FROM modules WHERE slug = 'pricing'), 'Are there any constraints or cost structures (operational expenses, desired profit margins) that influence your pricing strategy.', 7);