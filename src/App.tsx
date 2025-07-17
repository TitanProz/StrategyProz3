import React, { useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'sonner';
import { supabase } from './lib/supabase';
import { useAuthStore } from './store/authStore';
import { AuthForm } from './components/AuthForm';
import { DashboardLayout } from './layouts/DashboardLayout';
import ModuleContent from './components/ModuleContent';
import { AdminDashboard } from './components/AdminDashboard';
import { RecoveryForm } from './components/RecoveryForm';
import { ResetPasswordForm } from './components/ResetPasswordForm';
import { AdminLayout } from './layouts/AdminLayout';
import { WaitForApproval } from './components/WaitForApproval';

export default function App() {
  const { user, setUser, isAdmin, isApproved } = useAuthStore();

  useEffect(() => {
    // Attempt to get the current session on first load
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
    });

    // Listen for any auth state changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
    });

    return () => {
      subscription.unsubscribe();
    };
  }, [setUser]);

  // A small layout wrapper for all auth forms (login, register, recover)
  const AuthLayout = ({ children }: { children: React.ReactNode }) => (
    <div className="min-h-screen bg-[#1E3A8A] flex items-center justify-center">
      {children}
    </div>
  );

  // If you run a separate domain for admins:
  const isAdminDomain = window.location.hostname === 'admin.strategyproz.com';

  return (
    <Router>
      <Toaster position="top-right" />

      <Routes>
        {/* Public password-reset routes */}
        <Route path="/reset-password" element={<ResetPasswordForm />} />

        {!user ? (
          // If no user is logged in:
          <>
            <Route
              path="/recover"
              element={
                <AuthLayout>
                  <RecoveryForm />
                </AuthLayout>
              }
            />
            <Route
              path="*"
              element={
                <AuthLayout>
                  <AuthForm />
                </AuthLayout>
              }
            />
          </>
        ) : isAdmin && isAdminDomain ? (
          // Admin domain => show AdminLayout by default
          <>
            <Route path="/" element={<AdminLayout />}>
              <Route index element={<AdminDashboard />} />
            </Route>
            <Route path="*" element={<Navigate to="/" replace />} />
          </>
        ) : !isAdmin && !isApproved ? (
          // Normal domain, but user is NOT approved => they go to /pending
          <>
            <Route path="/pending" element={<WaitForApproval />} />
            <Route path="*" element={<Navigate to="/pending" replace />} />
          </>
        ) : (
          // Normal domain => user is either approved or an admin on same domain
          <>
            <Route path="/" element={<Navigate to="/modules" replace />} />
            <Route path="/modules" element={<DashboardLayout />}>
              <Route index element={<ModuleContent />} />
              <Route path=":moduleId" element={<ModuleContent />} />
            </Route>

            {/* If they want an admin panel on the same domain: */}
            <Route path="/admin" element={<AdminLayout />}>
              <Route index element={<AdminDashboard />} />
            </Route>

            <Route path="*" element={<Navigate to="/modules" replace />} />
          </>
        )}
      </Routes>
    </Router>
  );
}