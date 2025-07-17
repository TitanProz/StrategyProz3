-- Function to clear user data
CREATE OR REPLACE FUNCTION clear_user_data()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Delete all data for the current user
  DELETE FROM user_responses WHERE user_id = auth.uid();
  DELETE FROM module_progress WHERE user_id = auth.uid();
  DELETE FROM completed_modules WHERE user_id = auth.uid();
  DELETE FROM user_settings WHERE user_id = auth.uid();
  DELETE FROM messages WHERE sender_id = auth.uid() OR receiver_id = auth.uid();
  DELETE FROM chat_messages WHERE sender_id = auth.uid() OR receiver_id = auth.uid();
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION clear_user_data() TO authenticated;