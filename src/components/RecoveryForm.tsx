import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Mail, Loader2 } from 'lucide-react';
import { toast } from 'sonner';
import { supabase } from '../lib/supabase';

export function RecoveryForm() {
  const [email, setEmail] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      // Get the site URL from environment variables
      const siteUrl = import.meta.env.VITE_SITE_URL || window.location.origin;
      
      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${siteUrl}/reset-password`,
      });

      if (error) throw error;

      setIsSuccess(true);
      toast.success('Recovery email sent! Check your inbox.');
    } catch (error: any) {
      toast.error(error.message || 'An error occurred while sending the recovery email. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="w-full max-w-md p-8 bg-white rounded-xl shadow-lg border border-slate-200">
      <div className="flex justify-center mb-8">
        <img src="https://storage.googleapis.com/msgsndr/jY21tpLjXFAMvoP23PQ2/media/67fd32fca11941504dc59d68.png" alt="StrategyProz" className="h-16" />
      </div>
      
      {isSuccess ? (
        <div className="text-center space-y-4">
          <div className="bg-green-50 text-green-800 p-4 rounded-lg">
            <p className="font-medium">Recovery email sent!</p>
            <p className="text-sm mt-1">Please check your email inbox for instructions to reset your password.</p>
          </div>
          <button
            onClick={() => navigate('/')}
            className="btn-secondary px-4 py-2"
          >
            Return to Login
          </button>
        </div>
      ) : (
        <>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="relative">
              <Mail className="absolute left-3 top-3 h-5 w-5 text-slate-400" />
              <input
                type="email"
                placeholder="Email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full pl-10 pr-4 py-2 rounded-xl"
                required
                disabled={isLoading}
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
                  Sending
                </>
              ) : (
                'Send Recovery Email'
              )}
            </button>
          </form>
          <div className="mt-4 text-center">
            <button
              onClick={() => navigate('/')}
              className="btn-secondary px-4 py-2"
            >
              Return
            </button>
          </div>
        </>
      )}
    </div>
  );
}