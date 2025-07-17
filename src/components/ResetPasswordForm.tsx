import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Lock, Loader2 } from 'lucide-react';
import { toast } from 'sonner';
import { supabase } from '../lib/supabase';

export function ResetPasswordForm() {
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isTokenValidating, setIsTokenValidating] = useState(true);
  const [isTokenValid, setIsTokenValid] = useState(false);
  const navigate = useNavigate();

  // Parse query parameters from the URL
  useEffect(() => {
    const validateToken = async () => {
      try {
        // Get hash parameters if they exist
        if (window.location.hash) {
          const hashParams = new URLSearchParams(window.location.hash.substring(1));
          const accessToken = hashParams.get('access_token');
          const type = hashParams.get('type');
          const refreshToken = hashParams.get('refresh_token');

          if (accessToken && type === 'recovery') {
            // Verify the token by setting the session
            const { data, error } = await supabase.auth.setSession({
              access_token: accessToken,
              refresh_token: refreshToken || '',
            });

            if (error) {
              console.error('Error validating recovery token:', error);
              toast.error('Invalid or expired recovery link. Please request a new one.');
              setIsTokenValid(false);
            } else {
              // Successfully verified token
              setIsTokenValid(true);
              
              // Clean up the URL
              window.history.replaceState({}, document.title, '/reset-password');
            }
          } else {
            // No valid recovery parameters in hash
            checkExistingSession();
          }
        } else {
          // No hash parameters, check if there's an existing session
          checkExistingSession();
        }
      } catch (err) {
        console.error('Token validation error:', err);
        toast.error('An error occurred validating your recovery link.');
        setIsTokenValid(false);
      } finally {
        setIsTokenValidating(false);
      }
    };

    const checkExistingSession = async () => {
      const { data } = await supabase.auth.getSession();
      if (data.session) {
        setIsTokenValid(true);
      } else {
        toast.error('No valid recovery information found. Please request a new password reset link.');
        setIsTokenValid(false);
      }
    };

    validateToken();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (newPassword !== confirmPassword) {
      toast.error('Passwords do not match');
      return;
    }
    
    if (newPassword.length < 6) {
      toast.error('Password must be at least 6 characters');
      return;
    }

    setIsLoading(true);

    try {
      // Update the user's password
      const { error } = await supabase.auth.updateUser({
        password: newPassword,
      });

      if (error) throw error;

      toast.success('Password updated successfully');
      
      // Redirect to login page
      setTimeout(() => navigate('/'), 1500);
    } catch (error: any) {
      toast.error(error.message || 'An error occurred while updating the password. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  if (isTokenValidating) {
    return (
      <div className="w-full max-w-md p-8 bg-white rounded-xl shadow-lg border border-slate-200">
        <div className="flex flex-col items-center justify-center">
          <Loader2 className="h-8 w-8 animate-[smooth-spin_1s_linear_infinite] text-[#1E3A8A]" />
          <p className="mt-4 text-gray-700">Validating your recovery link...</p>
        </div>
      </div>
    );
  }

  if (!isTokenValid) {
    return (
      <div className="w-full max-w-md p-8 bg-white rounded-xl shadow-lg border border-slate-200">
        <div className="flex flex-col items-center justify-center">
          <p className="text-red-600 font-medium">Invalid or expired recovery link.</p>
          <button
            onClick={() => navigate('/recover')}
            className="mt-4 bg-[#1E3A8A] text-white px-4 py-2 rounded-lg hover:bg-[#0c1f4b] transition-colors"
          >
            Request New Link
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="w-full max-w-md p-8 bg-white rounded-xl shadow-lg border border-slate-200">
      <div className="flex justify-center mb-8">
        <img src="https://storage.googleapis.com/msgsndr/jY21tpLjXFAMvoP23PQ2/media/67fd32fca11941504dc59d68.png" alt="StrategyProz" className="h-16" />
      </div>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="relative">
          <Lock className="absolute left-3 top-3 h-5 w-5 text-slate-400" />
          <input
            type="password"
            placeholder="New Password"
            value={newPassword}
            onChange={(e) => setNewPassword(e.target.value)}
            className="w-full pl-10 pr-4 py-2 rounded-xl"
            required
            disabled={isLoading}
            minLength={6}
          />
        </div>
        <div className="relative">
          <Lock className="absolute left-3 top-3 h-5 w-5 text-slate-400" />
          <input
            type="password"
            placeholder="Confirm Password"
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            className="w-full pl-10 pr-4 py-2 rounded-xl"
            required
            disabled={isLoading}
            minLength={6}
          />
        </div>
        <button
          type="submit"
          disabled={isLoading}
          className="w-full bg-[#1E3A8A] text-white py-2.5 rounded-xl transition-colors outline-none disabled:opacity-50 disabled:cursor-not-allowed shadow-sm flex items-center justify-center"
        >
          {isLoading ? (
            <>
              <Loader2 className="h-5 w-5 mr-2 animate-[smooth-spin_1s_linear_infinite]" />
              Updating
            </>
          ) : (
            'Set New Password'
          )}
        </button>
      </form>
    </div>
  );
}