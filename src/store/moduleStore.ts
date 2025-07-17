import { create } from 'zustand';
import { supabase } from '../lib/supabase';
import { createClient } from '@supabase/supabase-js';
import type { Module, Question, ModuleProgress } from '../types/database';
import { useAuthStore } from './authStore';
import { persist } from 'zustand/middleware';

// Service role client to read modules & questions without RLS blocking us
const serviceRoleSupabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_SERVICE_ROLE_KEY
);

interface ModuleState {
  modules: Module[];
  currentModule: Module | null;
  questions: Question[];
  allQuestions: Record<string, Question[]>;
  currentQuestion: Question | null;
  responses: Record<string, string>;
  moduleProgress: Record<string, ModuleProgress>;
  completedModules: string[];
  selectedPractice: string | null;
  selectedNiche: string | null;
  isLoading: boolean;
  error: string | null;
  fetchModules: () => Promise<void>;
  fetchModuleBySlug: (slug: string) => Promise<Module | null>;
  fetchAllQuestions: () => Promise<void>;
  fetchQuestions: (moduleId: string) => Promise<Question[]>;
  fetchResponses: (moduleId: string) => Promise<Record<string, string>>;
  saveResponse: (questionId: string, content: string) => Promise<void>;
  updateProgress: (moduleId: string, questionId: string | null, completed?: boolean) => Promise<void>;
  unlockNextModule: (moduleId: string) => Promise<void>;
  setSelectedPractice: (practice: string | null) => Promise<void>;
  setSelectedNiche: (niche: string | null) => Promise<void>;
  reset: () => void;
  fetchProgress: () => Promise<void>;

  /*********************************************
   * NEW COPY FEATURE: Single-Response Fetcher
   *********************************************/
  fetchSingleResponse: (questionId: string) => Promise<string>;
}

export const useModuleStore = create<ModuleState>()(
  persist(
    (set, get) => ({
      modules: [],
      currentModule: null,
      questions: [],
      allQuestions: {},
      currentQuestion: null,
      responses: {},
      moduleProgress: {},
      completedModules: [],
      selectedPractice: null,
      selectedNiche: null,
      isLoading: false,
      error: null,

      // ----------------------------------
      // FETCH ALL MODULES
      // ----------------------------------
      fetchModules: async () => {
        try {
          set({ isLoading: true, error: null });

          // Try with the regular client
          let moduleData = await supabase
            .from('modules')
            .select('*')
            .order('order');
          // If that fails, fallback to service role
          if (moduleData.error) {
            moduleData = await serviceRoleSupabase
              .from('modules')
              .select('*')
              .order('order');
            if (moduleData.error) throw moduleData.error;
          }

          set({ modules: moduleData.data || [] });

          // Pre-fetch all questions & user progress
          await get().fetchAllQuestions();
          await get().fetchProgress();

          // If user is logged in, check if they previously selected a practice/niche
          const { user } = useAuthStore.getState();
          if (user?.id) {
            const { data: settings } = await supabase
              .from('user_settings')
              .select('selected_practice, selected_niche')
              .eq('user_id', user.id)
              .maybeSingle();
            if (settings?.selected_practice) {
              set({ selectedPractice: settings.selected_practice });
            }
            if (settings?.selected_niche) {
              set({ selectedNiche: settings.selected_niche });
            }
          }

          // Unlock introduction module (order=0) in local state
          const introModule = moduleData.data?.find((m) => m.order === 0);
          if (introModule) {
            set((state) => ({
              moduleProgress: {
                ...state.moduleProgress,
                [introModule.id]: {
                  module_id: introModule.id,
                  completed: false,
                  current_question: null,
                },
              },
            }));
          }

          // Also unlock Capabilities Inventory (if present)
          const capabilitiesModule = moduleData.data?.find(
            (m) => m.slug === 'capabilities-inventory'
          );
          if (capabilitiesModule) {
            set((state) => ({
              moduleProgress: {
                ...state.moduleProgress,
                [capabilitiesModule.id]: {
                  module_id: capabilitiesModule.id,
                  completed: false,
                  current_question: null,
                },
              },
            }));
          }
        } catch (error: any) {
          set({ error: error.message });
        } finally {
          set({ isLoading: false });
        }
      },

      // ----------------------------------
      // UPDATED FOR COPY FEATURE
      // ----------------------------------
      fetchAllQuestions: async () => {
        try {
          set({ isLoading: true, error: null });
          const { data, error } = await supabase
            .from('questions')
            .select('*')
            .order('order');
          if (error) throw error;

          // Bucket questions by module_id
          const bucketed: Record<string, Question[]> = {};
          (data || []).forEach((q: Question) => {
            if (!bucketed[q.module_id]) {
              bucketed[q.module_id] = [];
            }
            bucketed[q.module_id].push(q);
          });

          set((state) => ({
            questions: data || [],
            allQuestions: {
              ...state.allQuestions,
              ...bucketed,
            },
            isLoading: false,
          }));
        } catch (err: any) {
          console.error('Error fetching all questions:', err);
          set({ error: err.message, isLoading: false });
        }
      },

      // ----------------------------------
      // FETCH MODULE BY SLUG
      // ----------------------------------
      fetchModuleBySlug: async (slug: string) => {
        try {
          set({ isLoading: true, error: null });

          // Try with the regular client
          let moduleData = await supabase
            .from('modules')
            .select('*')
            .eq('slug', slug)
            .single();
          // Fallback to service role
          if (moduleData.error) {
            moduleData = await serviceRoleSupabase
              .from('modules')
              .select('*')
              .eq('slug', slug)
              .single();
            if (moduleData.error) throw moduleData.error;
          }

          const foundModule = moduleData.data;
          if (!foundModule) {
            set({ isLoading: false });
            return null;
          }

          // Unlock introduction if this is the intro module
          if (foundModule.order === 0) {
            set((state) => ({
              moduleProgress: {
                ...state.moduleProgress,
                [foundModule.id]: {
                  module_id: foundModule.id,
                  completed: false,
                  current_question: null,
                },
              },
            }));
          }

          // Unlock Capabilities Inventory if it's that module
          if (foundModule.slug === 'capabilities-inventory') {
            set((state) => ({
              moduleProgress: {
                ...state.moduleProgress,
                [foundModule.id]: {
                  module_id: foundModule.id,
                  completed: false,
                  current_question: null,
                },
              },
            }));
          }

          const modId = foundModule.id;
          const cachedQuestions = get().allQuestions[modId] || [];
          if (cachedQuestions.length > 0) {
            set({
              currentModule: foundModule,
              questions: cachedQuestions,
              currentQuestion: cachedQuestions[0] || null,
              isLoading: false,
            });
            return foundModule;
          }

          // If not cached, fetch them now
          const moduleQuestions = await get().fetchQuestions(modId);
          set({
            currentModule: foundModule,
            questions: moduleQuestions,
            currentQuestion: moduleQuestions[0] || null,
            isLoading: false,
          });
          return foundModule;
        } catch (error: any) {
          set({ error: error.message, isLoading: false });
          return null;
        }
      },

      // ----------------------------------
      // FETCH QUESTIONS FOR A MODULE
      // ----------------------------------
      fetchQuestions: async (moduleId: string) => {
        try {
          set({ isLoading: true });

          // If we have cached questions, use them
          if (get().allQuestions[moduleId]?.length) {
            const cached = get().allQuestions[moduleId];
            set({
              questions: cached,
              currentQuestion: cached[0] || null,
              isLoading: false,
            });
            return cached;
          }

          // Otherwise fetch from DB
          let questionData = await supabase
            .from('questions')
            .select('*')
            .eq('module_id', moduleId)
            .order('order');
          if (questionData.error) {
            questionData = await serviceRoleSupabase
              .from('questions')
              .select('*')
              .eq('module_id', moduleId)
              .order('order');
            if (questionData.error) throw questionData.error;
          }
          const qList = questionData.data || [];

          // Store in the allQuestions cache
          set((state) => ({
            questions: qList,
            currentQuestion: qList[0] || null,
            allQuestions: { ...state.allQuestions, [moduleId]: qList },
            isLoading: false,
          }));
          return qList;
        } catch (error: any) {
          set({ error: error.message, isLoading: false });
          return [];
        }
      },

      // ----------------------------------
      // FETCH RESPONSES FOR A MODULE
      // ----------------------------------
      fetchResponses: async (moduleId: string) => {
        try {
          const { user } = useAuthStore.getState();
          if (!user?.id) return get().responses; // Not logged in

          // Get the module's questions
          const moduleQuestions = get().allQuestions[moduleId] || [];
          const questionIds = moduleQuestions.map((q) => q.id);

          // Pull from user_responses
          const { data: respData, error } = await supabase
            .from('user_responses')
            .select('question_id, content')
            .eq('user_id', user.id)
            .in('question_id', questionIds)
            .order('updated_at', { ascending: true });

          if (error) throw error;

          const updatedMap: Record<string, string> = {};
          (respData || []).forEach((r) => {
            updatedMap[r.question_id] = r.content;
          });

          set((state) => ({
            responses: { ...state.responses, ...updatedMap },
          }));
          return updatedMap;
        } catch (error: any) {
          set({ error: error.message });
          return {};
        }
      },

      // ----------------------------------
      // SAVE A SINGLE RESPONSE
      // ----------------------------------
      saveResponse: async (questionId: string, content: string) => {
        try {
          const { user } = useAuthStore.getState();
          if (!user?.id) return; // Not logged in at all

          // Update local store immediately
          set((state) => ({
            responses: {
              ...state.responses,
              [questionId]: content,
            },
          }));

          // Check if a row already exists
          const { data: existing, error: selectError } = await supabase
            .from('user_responses')
            .select('id')
            .eq('user_id', user.id)
            .eq('question_id', questionId)
            .maybeSingle();
          if (selectError) throw selectError;

          if (existing) {
            // Update if found
            const { error: updateError } = await supabase
              .from('user_responses')
              .update({ content })
              .eq('id', existing.id);
            if (updateError) throw updateError;
          } else {
            // Insert if not found
            const { error: insertError } = await supabase
              .from('user_responses')
              .insert({
                user_id: user.id,
                question_id: questionId,
                content,
              });
            if (insertError) throw insertError;
          }
        } catch (error: any) {
          set({ error: error.message });
          throw error;
        }
      },

      // ----------------------------------
      // UPDATE PROGRESS
      // ----------------------------------
      updateProgress: async (moduleId: string, questionId: string | null, completed = false) => {
        try {
          set({ isLoading: true, error: null });
          const { user } = useAuthStore.getState();
          if (!user?.id) return;

          // Check existing progress
          const { data: existing, error: checkError } = await supabase
            .from('module_progress')
            .select('*')
            .eq('module_id', moduleId)
            .eq('user_id', user.id)
            .maybeSingle();
          if (checkError) throw checkError;

          if (existing) {
            // Update row
            const { error: updErr } = await supabase
              .from('module_progress')
              .update({
                current_question: questionId,
                completed,
                updated_at: new Date().toISOString(),
              })
              .eq('id', existing.id);
            if (updErr) throw updErr;
          } else {
            // Insert row
            const { error: insErr } = await supabase
              .from('module_progress')
              .insert([
                {
                  module_id: moduleId,
                  user_id: user.id,
                  current_question: questionId,
                  completed,
                },
              ]);
            if (insErr) throw insErr;
          }

          // Update local state
          set((state) => {
            const finishedModules = completed
              ? [...state.completedModules, moduleId]
              : state.completedModules;
            return {
              moduleProgress: {
                ...state.moduleProgress,
                [moduleId]: {
                  module_id: moduleId,
                  completed,
                  current_question: questionId,
                },
              },
              completedModules: [...new Set(finishedModules)],
            };
          });

          // If completed, also mark in completed_modules
          if (completed) {
            try {
              const { error: upsertErr } = await supabase
                .from('completed_modules')
                .upsert(
                  { user_id: user.id, module_id: moduleId },
                  { onConflict: 'user_id,module_id' }
                );
              if (upsertErr) throw upsertErr;
            } catch (e) {
              // Not critical, log and continue
              console.error('Error saving completed module:', e);
            }
          }
        } catch (error: any) {
          set({ error: error.message });
        } finally {
          set({ isLoading: false });
        }
      },

      // ----------------------------------
      // UNLOCK THE NEXT MODULE
      // ----------------------------------
      unlockNextModule: async (moduleId: string) => {
        const { user } = useAuthStore.getState();
        if (!user) return;

        const current = get().modules.find((m) => m.id === moduleId);
        if (!current) return;

        const next = get().modules.find((m) => m.order === current.order + 1);
        if (!next) return;

        const nextQs = get().allQuestions[next.id] || [];
        const firstQ = nextQs[0] || null;

        // Update local state to show it's "unlocked"
        set((state) => ({
          moduleProgress: {
            ...state.moduleProgress,
            [next.id]: {
              module_id: next.id,
              // preserve completed if it was already set
              completed: state.moduleProgress[next.id]?.completed || false,
              current_question:
                state.moduleProgress[next.id]?.current_question ??
                (firstQ ? firstQ.id : null),
            },
          },
        }));

        try {
          // Check if there's already a row in Supabase
          const { data: existing, error: selErr } = await supabase
            .from('module_progress')
            .select('*')
            .eq('module_id', next.id)
            .eq('user_id', user.id)
            .maybeSingle();
          if (selErr) throw selErr;

          if (!existing) {
            // Insert a new row marking it unlocked (completed=false)
            const { error: insErr } = await supabase
              .from('module_progress')
              .insert([
                {
                  module_id: next.id,
                  user_id: user.id,
                  current_question: firstQ ? firstQ.id : null,
                  completed: false,
                },
              ]);
            if (insErr) throw insErr;
          }
        } catch (e) {
          console.error('Error unlocking next module in supabase:', e);
        }
      },

      // ----------------------------------
      // SET SELECTED PRACTICE
      // ----------------------------------
      setSelectedPractice: async (practice) => {
        set({ selectedPractice: practice });
        const { user } = useAuthStore.getState();
        if (user?.id && practice) {
          try {
            const { error } = await supabase
              .from('user_settings')
              .upsert(
                { user_id: user.id, selected_practice: practice },
                { onConflict: 'user_id' }
              );
            if (error) throw error;
          } catch (err) {
            console.error('Error saving selected practice:', err);
          }
        }
      },

      // ----------------------------------
      // SET SELECTED NICHE
      // ----------------------------------
      setSelectedNiche: async (niche) => {
        set({ selectedNiche: niche });
        const { user } = useAuthStore.getState();
        if (user?.id && niche) {
          try {
            const { error } = await supabase
              .from('user_settings')
              .upsert(
                { user_id: user.id, selected_niche: niche },
                { onConflict: 'user_id' }
              );
            if (error) throw error;
          } catch (err) {
            console.error('Error saving selected niche:', err);
          }
        }
      },

      // ----------------------------------
      // RESET STORE
      // ----------------------------------
      reset: () => {
        set({
          selectedPractice: null,
          selectedNiche: null,
          currentModule: null,
          questions: [],
          responses: {},
          error: null,
          moduleProgress: {},
          completedModules: [],
        });
      },

      // ----------------------------------
      // FETCH MODULE PROGRESS
      // ----------------------------------
      fetchProgress: async () => {
        try {
          const { user } = useAuthStore.getState();
          if (!user?.id) return;

          const { data, error } = await supabase
            .from('module_progress')
            .select('module_id, completed, current_question')
            .eq('user_id', user.id);
          if (error) throw error;

          const progressMap = (data || []).reduce((acc: Record<string, ModuleProgress>, item) => {
            acc[item.module_id] = item;
            return acc;
          }, {});

          // Grab completed modules
          const { data: completedData, error: compErr } = await supabase
            .from('completed_modules')
            .select('module_id')
            .eq('user_id', user.id);
          if (compErr) throw compErr;
          const completedIds = (completedData || []).map((c) => c.module_id);

          // Mark them as completed
          completedIds.forEach((mId) => {
            if (!progressMap[mId]) {
              progressMap[mId] = {
                module_id: mId,
                completed: true,
                current_question: null,
              };
            } else {
              progressMap[mId].completed = true;
            }
          });

          set({ completedModules: completedIds });

          // Unlock the intro module if it exists
          const introMod = get().modules.find((m) => m.order === 0);
          if (introMod && !progressMap[introMod.id]) {
            progressMap[introMod.id] = {
              module_id: introMod.id,
              completed: false,
              current_question: null,
            };
          }

          // Unlock Capabilities module
          const capMod = get().modules.find((m) => m.slug === 'capabilities-inventory');
          if (capMod && !progressMap[capMod.id]) {
            progressMap[capMod.id] = {
              module_id: capMod.id,
              completed: false,
              current_question: null,
            };
          }

          set({ moduleProgress: progressMap });
        } catch (error: any) {
          set({ error: error.message });
        }
      },

      // ----------------------------------
      // NEW COPY FEATURE METHOD
      // ----------------------------------
      fetchSingleResponse: async (questionId: string) => {
        try {
          const { user } = useAuthStore.getState();
          if (!user) return '';

          const { data, error } = await supabase
            .from('user_responses')
            .select('content')
            .eq('user_id', user.id)
            .eq('question_id', questionId)
            .maybeSingle();
          if (error) throw error;

          const newAnswer = data?.content ?? '';
          set((state) => ({
            responses: {
              ...state.responses,
              [questionId]: newAnswer,
            },
          }));

          return newAnswer;
        } catch (err: any) {
          console.error('Error fetching single response:', err);
          return '';
        }
      },
    }),
    {
      name: 'module-storage',
      partialize: (state) => ({
        selectedPractice: state.selectedPractice,
        selectedNiche: state.selectedNiche,
        completedModules: state.completedModules,
      }),
    }
  )
);