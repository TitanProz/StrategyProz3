import React, { useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { useAuthStore } from '../store/authStore';
import { useNavigate } from 'react-router-dom';

export function WaitForApproval() {
  const navigate = useNavigate();
  const { user, setUser, isApproved } = useAuthStore();

  useEffect(() => {
    // Poll every 1 second to see if the user is approved
    const intervalId = setInterval(async () => {
      // If the store already says "approved," we can stop polling.
      if (isApproved) {
        clearInterval(intervalId);
        navigate('/modules');
        return;
      }

      // Otherwise, fetch the fresh user object from Supabase
      const {
        data: { user: freshUser },
        error,
      } = await supabase.auth.getUser();

      if (error) {
        console.error('Error refreshing user:', error);
        return; // keep polling
      }
      if (!freshUser) return; // user might be logged out

      // Update the store with the fresh user
      setUser(freshUser);

      // If newly updated user metadata is now approved => done
      if (freshUser?.user_metadata?.claims_approved) {
        clearInterval(intervalId);
        navigate('/modules');
      }
    }, 1000);

    return () => clearInterval(intervalId);
  }, [isApproved, navigate, setUser]);

  return (
    <div className="min-h-screen w-full flex items-center justify-center bg-[#1E3A8A]">
      <div className="bg-white p-8 rounded-xl shadow-lg text-center max-w-md">
        <h1 className="text-2xl font-bold mb-4 text-black">
          Successfully Registered
        </h1>
        <p className="text-gray-700">
          Waiting for approval, refresh later
        </p>
      </div>
    </div>
  );
}