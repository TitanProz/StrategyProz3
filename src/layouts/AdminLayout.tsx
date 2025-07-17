import React, { useState } from 'react';
import { Outlet, useNavigate } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';
import { toast } from 'sonner';
import { Loader2, ArrowLeft } from 'lucide-react';
import { ChatInterface } from '../components/ChatInterface';
import { supabase } from '../lib/supabase';

export function AdminLayout() {
  const navigate = useNavigate();
  const { signOut } = useAuthStore();
  const [isLoggingOut, setIsLoggingOut] = useState(false);
  const [isChatOpen, setIsChatOpen] = useState(false);
  const [unreadCount, setUnreadCount] = useState(0);

  // Handle sign out
  const handleSignOut = async () => {
    setIsLoggingOut(true);
    await signOut();
    toast.success('');
    navigate('/');
  };

  // Handle return to modules
  const handleReturn = () => {
    navigate('/modules');
  };

  // Handle "Reset Graph"
  const handleResetGraph = async () => {
    try {
      const { error } = await supabase.rpc('reset_graph_data');
      if (error) throw error;
      toast.success('Graph data has been reset for all users.');
    } catch (err: any) {
      toast.error('Failed to reset graph: ' + err.message);
    }
  };

  return (
    <div className="min-h-screen w-full bg-[#1E3A8A] flex flex-col">
      {/* Header */}
      <header className="w-full h-20 bg-white px-8 flex items-center justify-between border-b border-black">
        {/* Left side buttons */}
        <div className="flex items-center gap-4">
          <button
            onClick={handleReturn}
            className="bg-[#1E3A8A] text-white px-4 py-2 rounded-lg hover:bg-[#0c1f4b] transition-colors flex items-center gap-2"
          >
            <ArrowLeft className="h-4 w-4" />
            Return
          </button>
        </div>

        <div className="absolute left-1/2 transform -translate-x-1/2">
          <img src="https://storage.googleapis.com/msgsndr/jY21tpLjXFAMvoP23PQ2/media/67fd32fca11941504dc59d68.png" alt="StrategyProz" className="h-16" />
        </div>

        {/* Right side: Reset Graph + Logout */}
        <div className="flex items-center gap-4">
          <button
            onClick={handleResetGraph}
            className="bg-[#1E3A8A] text-white px-4 py-2 rounded-lg hover:bg-[#0c1f4b] transition-colors"
          >
            Reset Graph
          </button>

          <button
            onClick={handleSignOut}
            disabled={isLoggingOut}
            className="bg-[#1E3A8A] text-white px-4 py-2 rounded-lg hover:bg-[#0c1f4b] transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
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
      </header>

      {/* Main Area */}
      <div className="flex-1 relative">
        <Outlet />

        {/* Floating Chat Button */}
        <button
          className="
            fixed bottom-8 right-8
            bg-[#1E3A8A] text-white
            w-14 h-14
            rounded-full shadow-lg
            hover:bg-[#14306d]
            transition-colors
            cursor-pointer
            border border-white
            flex items-center justify-center
            text-sm font-medium
          "
          onClick={() => setIsChatOpen(true)}
        >
          Chat
          {unreadCount > 0 && (
            <span className="absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center">
              {unreadCount}
            </span>
          )}
        </button>

        {isChatOpen && (
          <ChatInterface
            onClose={() => setIsChatOpen(false)}
            setUnreadCount={setUnreadCount}
            // No special props => admin is opening from main chat button
          />
        )}
      </div>
    </div>
  );
}