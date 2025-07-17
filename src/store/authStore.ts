import { create } from 'zustand';
import { supabase } from '../lib/supabase';
import { useModuleStore } from './moduleStore';

interface AuthState {
  user: any | null;
  isAdmin: boolean;
  isApproved: boolean;
  setUser: (user: any) => void;
  signOut: () => Promise<void>;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  isAdmin: false,
  isApproved: false,

  setUser: (user) => {
    // We'll read both claims_admin and claims_approved from user_metadata
    const userMeta = user?.user_metadata || {};
    const adminFlag = userMeta?.claims_admin === true;
    const approvedFlag = userMeta?.claims_approved === true;

    set({
      user,
      isAdmin: adminFlag,
      isApproved: approvedFlag,
    });
  },

  signOut: async () => {
    await supabase.auth.signOut();

    // <-- Ensure we reset module store data on sign-out:
    useModuleStore.getState().reset();

    set({ user: null, isAdmin: false, isApproved: false });
  },
}));