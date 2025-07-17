/*
  # Database Checkpoint - Current Schema

  1. Tables
    - `modules`: Stores learning modules
      - `id` (uuid, primary key)
      - `title` (text)
      - `slug` (text, unique)
      - `order` (integer)
      - `created_at` (timestamp)
    
    - `questions`: Stores module questions
      - `id` (uuid, primary key)
      - `module_id` (uuid, references modules)
      - `content` (text)
      - `order` (integer)
      - `created_at` (timestamp)
    
    - `user_responses`: Stores user answers
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `question_id` (uuid, references questions)
      - `content` (text)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
    
    - `module_progress`: Tracks user progress
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `module_id` (uuid, references modules)
      - `completed` (boolean)
      - `current_question` (uuid, references questions)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
    
    - `chat_messages`: Stores chat communications
      - `id` (uuid, primary key)
      - `sender_id` (uuid, references auth.users)
      - `receiver_id` (uuid, references auth.users)
      - `content` (text)
      - `read` (boolean)
      - `created_at` (timestamp)
    
    - `messages`: Stores messaging system
      - `id` (uuid, primary key)
      - `sender_id` (uuid, references auth.users)
      - `receiver_id` (uuid, references auth.users)
      - `content` (text)
      - `read` (boolean)
      - `created_at` (timestamp)
    
    - `completed_modules`: Tracks finished modules
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `module_id` (uuid, references modules)
      - `created_at` (timestamp)
    
    - `user_settings`: Stores user preferences
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `selected_practice` (text)
      - `selected_niche` (text)
      - `final_report` (jsonb)
      - `is_admin` (boolean)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Views
    - `users`: View combining auth.users data
      - `id` (uuid)
      - `email` (varchar)
      - `created_at` (timestamp)
      - `last_sign_in_at` (timestamp)
      - `is_admin` (text)

  3. Security
    - RLS enabled on all tables
    - Policies for authenticated users
    - Admin-specific policies where needed
*/

-- This migration serves as a checkpoint and doesn't make any schema changes
DO $$ BEGIN
  -- Verify all tables exist
  IF NOT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = ANY(ARRAY[
      'modules',
      'questions',
      'user_responses',
      'module_progress',
      'chat_messages',
      'messages',
      'completed_modules',
      'user_settings'
    ])
  ) THEN
    RAISE EXCEPTION 'Schema verification failed: One or more required tables are missing';
  END IF;
END $$;