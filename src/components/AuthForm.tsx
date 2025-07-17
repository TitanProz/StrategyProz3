import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { Mail, Lock, Loader2 } from 'lucide-react';
import { toast } from 'sonner';
import { supabase } from '../lib/supabase';
import { useAuthStore } from '../store/authStore';
import { useModuleStore } from '../store/moduleStore';

export function AuthForm() {
  const [isLogin, setIsLogin] = useState(true);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isAdmin, setIsAdmin] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [isProcessingHash, setIsProcessingHash] = useState(false);

  const setUser = useAuthStore((state) => state.setUser);
  const resetModuleStore = useModuleStore((state) => state.reset);

  const navigate = useNavigate();
  const location = useLocation();

  // Handle magic links/recovery in hash
  useEffect(() => {
    const handleHashParams = async () => {
      if (location.hash) {
        setIsProcessingHash(true);
        try {
          const hashParams = new URLSearchParams(location.hash.substring(1));
          const accessToken = hashParams.get('access_token');
          const refreshToken = hashParams.get('refresh_token');
          const type = hashParams.get('type');

          if (accessToken) {
            if (type === 'recovery') {
              // If it's a recovery link, go to reset-password page
              navigate('/reset-password' + location.hash);
              setIsProcessingHash(false);
              return;
            }
            // Otherwise, try to set the session
            const { data, error } = await supabase.auth.setSession({
              access_token: accessToken,
              refresh_token: refreshToken || '',
            });
            if (error) {
              toast.error('Invalid or expired link. Please try again.');
            } else if (data.session) {
              setUser(data.session.user);
              // Once session is set, we check if user is approved or not
              const userMeta = data.session.user.user_metadata || {};
              const isApproved = userMeta.claims_approved === true;
              if (isApproved) {
                navigate('/modules');
              } else {
                navigate('/pending');
              }
            }
          }
        } catch (error) {
          console.error('Error processing hash:', error);
        } finally {
          setIsProcessingHash(false);
        }
      }
    };
    handleHashParams();
  }, [location.hash, navigate, setUser]);

  const clearUserData = async () => {
    try {
      const { error } = await supabase.rpc('clear_user_data');
      if (error) throw error;
      resetModuleStore();
    } catch (error: any) {
      console.error('Error clearing user data:', error);
      throw error;
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      if (isLogin) {
        // --- LOGIN ---
        const { data, error } = await supabase.auth.signInWithPassword({
          email,
          password,
        });
        if (error) throw error;
        setUser(data.user);

        // Check if the user is approved
        const userMeta = data.user?.user_metadata || {};
        const isApproved = userMeta.claims_approved === true;
        if (isApproved) {
          navigate('/modules');
        } else {
          navigate('/pending');
        }
      } else {
        // --- REGISTER ---
        // For new users: admin = claims_approved true, otherwise claims_approved false
        const { data: { user }, error } = await supabase.auth.signUp({
          email,
          password,
          options: {
            data: {
              claims_admin: isAdmin,
              claims_approved: isAdmin ? true : false,
            },
          },
        });

        if (error) throw error;

        if (user) {
          // (Optional) Auto-verify the email
          const { error: adminError } = await supabase.rpc('admin_verify_email', {
            user_id: user.id,
          });
          if (adminError) {
            console.error('Error auto-verifying email:', adminError);
          }

          await clearUserData();
          setUser(user);

          // Immediately send them to /pending if not admin
          // (Admin will have is_approved = true, so you could also do if not isAdmin => /pending)
          if (!isAdmin) {
            navigate('/pending');
          } else {
            // Admin user is already approved
            navigate('/modules');
          }
        }
      }
    } catch (error: any) {
      toast.error(error.message);
    } finally {
      setIsLoading(false);
    }
  };

  if (isProcessingHash) {
    return (
      <div className="w-full max-w-md p-8 bg-white rounded-xl shadow-lg border border-slate-200 relative">
        <div className="flex flex-col items-center justify-center">
          <Loader2 className="h-8 w-8 animate-[smooth-spin_1s_linear_infinite] text-[#1E3A8A]" />
          <p className="mt-4 text-gray-700">Processing your authentication...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="w-full max-w-md p-8 bg-white rounded-xl shadow-lg border border-slate-200 relative">
      <div className="flex justify-center mb-8">
        <img src="https://storage.googleapis.com/msgsndr/jY21tpLjXFAMvoP23PQ2/media/67fd32fca11941504dc59d68.png" alt="StrategyProz" className="h-16" />
      </div>

      <div className="flex mb-6">
        <button
          onClick={() => setIsLogin(true)}
          className={`auth-tab-btn flex-1 py-2 text-center font-medium border-b transition-colors !text-black ${
            isLogin ? 'border-black' : 'border-transparent hover:text-gray-700'
          }`}
        >
          Login
        </button>
        <button
          onClick={() => setIsLogin(false)}
          className={`auth-tab-btn flex-1 py-2 text-center font-medium border-b transition-colors !text-black ${
            !isLogin ? 'border-black' : 'border-transparent hover:text-gray-700'
          }`}
        >
          Register
        </button>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="relative">
          <Mail className="absolute left-3 top-3 h-5 w-5 text-slate-400" />
          <input
            type="email"
            placeholder="Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="w-full pl-10 pr-4 py-2 rounded-lg"
            required
            disabled={isLoading}
          />
        </div>
        <div className="relative">
          <Lock className="absolute left-3 top-3 h-5 w-5 text-slate-400" />
          <input
            type="password"
            placeholder="Password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="w-full pl-10 pr-4 py-2 rounded-lg"
            required
            disabled={isLoading}
          />
        </div>

        {!isLogin && (
          <div className="flex items-center space-x-2">
            <input
              type="checkbox"
              id="isAdmin"
              checked={isAdmin}
              onChange={(e) => setIsAdmin(e.target.checked)}
              className="rounded border-gray-300 text-[#1E3A8A] focus:ring-[#1E3A8A]"
            />
            <label htmlFor="isAdmin" className="text-sm text-gray-700">
              Register as Admin
            </label>
          </div>
        )}

        <button
          type="submit"
          disabled={isLoading}
          className="w-full bg-[#1E3A8A] text-white py-2.5 rounded-lg transition-colors outline-none disabled:opacity-50 disabled:cursor-not-allowed shadow-sm flex items-center justify-center"
        >
          {isLoading ? (
            <>
              <Loader2 className="h-5 w-5 mr-2 animate-[smooth-spin_1s_linear_infinite]" />
              {isLogin ? 'Logging in' : 'Registering'}
            </>
          ) : isLogin ? (
            'Access'
          ) : (
            'Register'
          )}
        </button>
      </form>

      {isLogin && (
        <div className="absolute bottom-1.5 left-0 right-0 text-center">
          <button
            onClick={() => navigate('/recover')}
            className="auth-recover-btn text-sm !text-black hover:text-gray-800 transition-colors"
          >
            Recover
          </button>
        </div>
      )}
    </div>
  );
}