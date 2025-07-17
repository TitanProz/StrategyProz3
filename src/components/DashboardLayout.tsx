import React, { useEffect, useState } from 'react';
import { Outlet, useNavigate } from 'react-router-dom';
import { ModulesList } from '../components/ModulesList';
import { MessageCircle, Loader2 } from 'lucide-react';
import { useAuthStore } from '../store/authStore';
import { toast } from 'sonner';
import { ChatInterface } from '../components/ChatInterface';
import { supabase } from '../lib/supabase';
import { createClient } from '@supabase/supabase-js';

// For user email lookups if needed:
const serviceRoleSupabase = createClient(
  'https://hnvrdgsjieeehisepcal.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhudnJkZ3NqaWVlZWhpc2VwY2FsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0MjI0MDkxNSwiZXhwIjoyMDU3ODE2OTE1fQ.oLYIyk4HfRhtXWAns-5liG5Oz13ddtc3tfWHaAXMZD4'
);

export function DashboardLayout() {
  const navigate = useNavigate();
  const { user, signOut, isAdmin } = useAuthStore();
  const [unreadCount, setUnreadCount] = useState(0);
  const [isLoggingOut, setIsLoggingOut] = useState(false);
  const [isChatOpen, setIsChatOpen] = useState(false);

  // Chat preferences
  const [enableNotifications, setEnableNotifications] = useState(false);
  const [enableSounds, setEnableSounds] = useState(false);

  // Beep function
  function beep(duration = 200, frequency = 500, volume = 1) {
    try {
      const audioCtx = new AudioContext();
      const oscillator = audioCtx.createOscillator();
      const gainNode = audioCtx.createGain();

      oscillator.connect(gainNode);
      gainNode.connect(audioCtx.destination);

      gainNode.gain.value = volume;
      oscillator.frequency.value = frequency;
      oscillator.type = 'square';
      oscillator.start();

      setTimeout(() => {
        oscillator.stop();
        audioCtx.close();
      }, duration);
    } catch (err) {
      console.error('Beep error:', err);
    }
  }

  // Load user chat preferences
  useEffect(() => {
    if (!user) return;
    supabase
      .from('user_settings')
      .select('chat_notifications, chat_sounds')
      .eq('user_id', user.id)
      .maybeSingle()
      .then(({ data, error }) => {
        if (error) {
          console.error('Error loading chat prefs:', error);
          return;
        }
        if (data) {
          if (typeof data.chat_notifications === 'boolean') {
            setEnableNotifications(data.chat_notifications);
          }
          if (typeof data.chat_sounds === 'boolean') {
            setEnableSounds(data.chat_sounds);
          }
        }
      });
  }, [user]);

  // Subscribe to new messages in real-time
  useEffect(() => {
    if (!user) return;

    const channel = supabase
      .channel('userMessages')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'messages' },
        async (payload) => {
          const newMessage = payload.new;
          if (newMessage.receiver_id === user.id) {
            // Chat is closed => notify if enabled
            if (!isChatOpen && enableNotifications) {
              try {
                const { data: userLookup } = await serviceRoleSupabase.auth.admin.getUserById(
                  newMessage.sender_id
                );
                const senderEmail = userLookup?.user?.email || 'Unknown';
                toast(`New message from ${senderEmail}`);
                if (enableSounds) {
                  beep(200, 600, 1);
                }
              } catch (err) {
                console.error('Error fetching sender email:', err);
              }
            }
            setUnreadCount((prev) => prev + 1);
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [user, isChatOpen, enableNotifications, enableSounds]);

  const handleSignOut = async () => {
    setIsLoggingOut(true);
    await signOut();
    toast.success('Successfully signed out');
    navigate('/');
  };

  return (
    <div className="flex min-h-screen bg-[#E0F2FF]">
      <aside className="fixed left-0 top-0 h-screen w-80 bg-[#1E3A8A] shadow-sm z-20">
        <ModulesList />
      </aside>

      <div className="flex-1 pl-80 flex flex-col min-h-screen bg-[#E0F2FF]">
        {/* Header */}
        <header className="h-20 bg-[#E0F2FF] fixed top-0 right-0 left-80 z-10 w-auto">
          <div className="h-full px-8 flex items-center justify-between">
            <div className="w-48"></div>
            <h1 className="text-2xl font-medium text-black text-center tracking-wide absolute left-0 right-0">
              Consulting Assessment
            </h1>
            <div className="z-10 relative flex items-center gap-4">
              {isAdmin && (
                <button
                  onClick={() => navigate('/admin')}
                  className="bg-[#1E3A8A] text-white px-4 py-2 rounded-lg hover:bg-[#0c1f4b] transition-colors"
                >
                  Control Panel
                </button>
              )}
              <button
                onClick={handleSignOut}
                disabled={isLoggingOut}
                className="bg-[#1E3A8A] text-white px-4 py-2 rounded-lg hover:bg-[#0c1f4b] transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2 cursor-pointer"
              >
                {isLoggingOut ? (
                  <>
                    <Loader2 className="h-4 w-4 animate-[smooth-spin_1s_linear_infinite]" />
                    Logging Out
                  </>
                ) : (
                  'Logout'
                )}
              </button>
            </div>
          </div>
        </header>

        <main className="flex-1 pt-20 w-full bg-[#E0F2FF]">
          <div className="max-w-[1920px] mx-auto w-full">
            <div className="min-h-[calc(100vh-5rem)] w-full bg-[#E0F2FF]">
              <Outlet />
            </div>
          </div>

          {/* Updated Chat button */}
          <button
            className="
              fixed bottom-8 right-8
              bg-[#1E3A8A] text-white p-4 rounded-full shadow-lg
              hover:bg-[#14306d] transition-colors cursor-pointer
              border border-white
            "
            onClick={() => setIsChatOpen(true)}
          >
            <MessageCircle className="h-6 w-6" />
            {unreadCount > 0 && (
              <span className="absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center">
                {unreadCount}
              </span>
            )}
          </button>

          {isChatOpen && (
            <ChatInterface
              onClose={() => {
                setIsChatOpen(false);
                setUnreadCount(0);
              }}
              setUnreadCount={setUnreadCount}
            />
          )}
        </main>
      </div>
    </div>
  );
}