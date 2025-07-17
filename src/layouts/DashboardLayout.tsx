// src/layouts/DashboardLayout.tsx
import React, { useState } from 'react';
import { Outlet, useNavigate } from 'react-router-dom';
import { Loader2, MessageCircle } from 'lucide-react';
import { useAuthStore } from '../store/authStore';
import { toast } from 'sonner';
import { ChatInterface } from '../components/ChatInterface';
import { ModulesList } from '../components/ModulesList';

export function DashboardLayout() {
  const navigate = useNavigate();
  const { signOut, isAdmin } = useAuthStore();

  /* ────────────────── local state ────────────────── */
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [unreadCount, setUnreadCount] = useState(0);
  const [isLoggingOut, setIsLoggingOut] = useState(false);
  const [isChatOpen, setIsChatOpen] = useState(false);

  const sidebarWidth = sidebarCollapsed ? 'w-20' : 'w-80';
  const contentPad   = sidebarCollapsed ? 'pl-20' : 'pl-80';
  const headerLeft   = sidebarCollapsed ? 'left-20' : 'left-80';

  /* ────────────────── handlers ───────────────────── */
  const handleSignOut = async () => {
    setIsLoggingOut(true);
    await signOut();
    toast.success('Successfully signed out');
    navigate('/');
  };

  /* ────────────────── layout ─────────────────────── */
  return (
    <div className="flex min-h-screen bg-[#E0F2FF]">
      {/* ░░ Sidebar ░░ */}
      <aside
        className={`fixed left-0 top-0 h-screen ${sidebarWidth} bg-[#1E3A8A] shadow-sm z-20 transition-all duration-200`}
      >
        <ModulesList
          collapsed={sidebarCollapsed}
          onToggle={() => setSidebarCollapsed((c) => !c)}
        />
      </aside>

      {/* ░░ Main content ░░ */}
      <div
        className={`flex-1 ${contentPad} flex flex-col min-h-screen bg-[#E0F2FF] transition-all duration-200`}
      >
        {/* Header */}
        <header
          className={`h-20 bg-[#E0F2FF] fixed top-0 right-0 ${headerLeft} z-10 transition-all duration-200`}
        >
          <div className="h-full px-8 flex items-center justify-between">
            <div className="w-48" />

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
          </div>
        </header>

        {/* Routed pages */}
        <main className="flex-1 pt-20 w-full bg-[#E0F2FF]">
          <Outlet />

          {/* Floating chat button */}
          <button
            className="fixed bottom-8 right-8 bg-[#1E3A8A] text-white p-4 rounded-full shadow-lg hover:bg-[#14306d] transition-colors cursor-pointer border border-white"
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
