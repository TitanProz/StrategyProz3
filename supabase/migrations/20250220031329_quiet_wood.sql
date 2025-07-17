/*
  # Module System Database Schema

  1. New Tables
    - `modules`
      - `id` (uuid, primary key)
      - `title` (text)
      - `slug` (text, unique)
      - `order` (integer)
      - `created_at` (timestamp)
    
    - `questions`
      - `id` (uuid, primary key)
      - `module_id` (uuid, foreign key)
      - `content` (text)
      - `order` (integer)
      - `created_at` (timestamp)
    
    - `user_responses`
      - `id` (uuid, primary key)
      - `user_id` (uuid, foreign key)
      - `question_id` (uuid, foreign key)
      - `content` (text)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
    
    - `module_progress`
      - `id` (uuid, primary key)
      - `user_id` (uuid, foreign key)
      - `module_id` (uuid, foreign key)
      - `completed` (boolean)
      - `current_question` (uuid, foreign key)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users to:
      - Read modules and questions
      - Read/write their own responses
      - Read/write their own progress
*/

-- Create modules table
CREATE TABLE modules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  slug text UNIQUE NOT NULL,
  "order" integer NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Create questions table
CREATE TABLE questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  module_id uuid REFERENCES modules(id) ON DELETE CASCADE,
  content text NOT NULL,
  "order" integer NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Create user_responses table
CREATE TABLE user_responses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  question_id uuid REFERENCES questions(id) ON DELETE CASCADE,
  content text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create module_progress table
CREATE TABLE module_progress (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  module_id uuid REFERENCES modules(id) ON DELETE CASCADE,
  completed boolean DEFAULT false,
  current_question uuid REFERENCES questions(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, module_id)
);

-- Enable Row Level Security
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE module_progress ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Modules are viewable by authenticated users"
  ON modules FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Questions are viewable by authenticated users"
  ON questions FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can view their own responses"
  ON user_responses FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own responses"
  ON user_responses FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own responses"
  ON user_responses FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own progress"
  ON module_progress FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own progress"
  ON module_progress FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own progress"
  ON module_progress FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Insert initial modules
INSERT INTO modules (title, slug, "order") VALUES
  ('Capabilities Inventory', 'capabilities-inventory', 1),
  ('Strategy Framework', 'strategy-framework', 2),
  ('Opportunity Map', 'opportunity-map', 3),
  ('Service Offering Blueprint', 'service-offering', 4),
  ('Positioning & Differentiation Matrix', 'positioning', 5),
  ('Pricing Strategy Planner', 'pricing', 6),
  ('Final Report', 'final-report', 7);

-- Insert initial questions for Capabilities Inventory
INSERT INTO questions (module_id, content, "order") VALUES
  ((SELECT id FROM modules WHERE slug = 'capabilities-inventory'), 'What are your primary areas of professional expertise?', 1),
  ((SELECT id FROM modules WHERE slug = 'capabilities-inventory'), 'Describe your most significant professional achievements.', 2),
  ((SELECT id FROM modules WHERE slug = 'capabilities-inventory'), 'What unique methodologies or approaches have you developed in your field?', 3),
  ((SELECT id FROM modules WHERE slug = 'capabilities-inventory'), 'What are your short-term and long-term consulting goals?', 4);

-- Create function to update timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_user_responses_updated_at
  BEFORE UPDATE ON user_responses
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_module_progress_updated_at
  BEFORE UPDATE ON module_progress
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();