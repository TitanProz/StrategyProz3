export interface Module {
  id: string;
  title: string;
  slug: string;
  order: number;
  created_at: string;
}

export interface Question {
  id: string;
  module_id: string;
  content: string;
  order: number;
  created_at: string;
}

export interface UserResponse {
  id: string;
  user_id: string;
  question_id: string;
  content: string;
  created_at: string;
  updated_at: string;
}

export interface ModuleProgress {
  id?: string;
  user_id?: string;
  module_id: string;
  completed: boolean;
  current_question: string | null;
  created_at?: string;
  updated_at?: string;
}