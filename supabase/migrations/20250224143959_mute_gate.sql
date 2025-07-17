/*
  # Add messages table if not exists

  1. New Tables (if not exists)
    - `messages`
      - `id` (uuid, primary key)
      - `sender_id` (uuid, references auth.users)
      - `recipient_id` (uuid, references auth.users)
      - `content` (text)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on `messages` table
    - Add policies for authenticated users to:
      - Insert their own messages
      - Read messages where they are sender or recipient
*/

DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'messages') THEN
    CREATE TABLE messages (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      sender_id UUID REFERENCES auth.users(id),
      recipient_id UUID REFERENCES auth.users(id),
      content TEXT NOT NULL,
      created_at TIMESTAMPTZ DEFAULT now()
    );

    -- Enable RLS
    ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

    -- Create policies
    CREATE POLICY "Users can send messages"
      ON messages
      FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = sender_id);

    CREATE POLICY "Users can read their messages"
      ON messages
      FOR SELECT
      TO authenticated
      USING (auth.uid() IN (sender_id, recipient_id));

    -- Create index for better query performance
    CREATE INDEX messages_sender_recipient_idx ON messages(sender_id, recipient_id);
  END IF;
END $$;