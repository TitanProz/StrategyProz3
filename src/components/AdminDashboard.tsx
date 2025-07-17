import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  MessageCircle,
  Eye,
  Trash,
  ArrowLeft,
  ChevronDown,
  CheckCircle,
} from 'lucide-react';
import { toast } from 'sonner';
import { ChatInterface } from './ChatInterface';
import { useAuthStore } from '../store/authStore';
import { createClient } from '@supabase/supabase-js';
import { UserGrowthChart } from './UserGrowthChart';

/* ────────────────────────────────────────────────────────── */
/*  Supabase: client with service-role key                    */
/* ────────────────────────────────────────────────────────── */
const serviceRoleSupabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_SERVICE_ROLE_KEY
);

/* ────────────────────────────────────────────────────────── */
/*  Types                                                    */
/* ────────────────────────────────────────────────────────── */
interface UserRecord {
  id: string;
  email: string;
  created_at: string;
  last_sign_in_at: string | null;
  is_admin: boolean;
  is_approved: boolean;
}

interface ChartDataPoint {
  date: string;
  user_count: number;
}

/* ────────────────────────────────────────────────────────── */
/*  Helper: pretty-print final-report JSON                    */
/* ────────────────────────────────────────────────────────── */
function FinalReportDisplay({ report }: { report: any }) {
  if (!report || Object.keys(report).length === 0) {
    return (
      <p className="text-slate-400 italic">(No final report generated yet)</p>
    );
  }

  return (
    <div className="space-y-8 text-slate-800 text-sm leading-6">
      {/* EXECUTIVE SUMMARY */}
      {report.executiveSummary && (
        <div>
          <h3 className="text-xl font-semibold text-black mb-4">
            Executive Summary
          </h3>
          <p>
            <strong>Overview:</strong>{' '}
            {report.executiveSummary.overview || 'N/A'}
          </p>
          {Array.isArray(report.executiveSummary.keyStrategies) &&
            report.executiveSummary.keyStrategies.length > 0 && (
              <>
                <p className="mt-2 font-medium">Key Strategies:</p>
                <ul className="list-disc pl-5">
                  {report.executiveSummary.keyStrategies.map(
                    (strat: string, idx: number) => <li key={idx}>{strat}</li>
                  )}
                </ul>
              </>
            )}
          <p className="mt-2">
            <strong>Vision:</strong>{' '}
            {report.executiveSummary.vision || 'N/A'}
          </p>
        </div>
      )}

      {/* MARKET ANALYSIS */}
      {report.marketAnalysis && (
        <div>
          <h3 className="text-xl font-semibold text-black mb-4">
            Market Analysis
          </h3>
          <p>
            <strong>Target Market:</strong>{' '}
            {report.marketAnalysis.targetMarket || 'N/A'}
          </p>
          <p className="mt-2">
            <strong>Competitive Landscape:</strong>{' '}
            {report.marketAnalysis.competitiveLandscape || 'N/A'}
          </p>
          {Array.isArray(report.marketAnalysis.opportunities) &&
            report.marketAnalysis.opportunities.length > 0 && (
              <>
                <p className="mt-2 font-medium">Opportunities:</p>
                <ul className="list-disc pl-5">
                  {report.marketAnalysis.opportunities.map(
                    (opp: string, idx: number) => <li key={idx}>{opp}</li>
                  )}
                </ul>
              </>
            )}
          {Array.isArray(report.marketAnalysis.threats) &&
            report.marketAnalysis.threats.length > 0 && (
              <>
                <p className="mt-2 font-medium">Threats:</p>
                <ul className="list-disc pl-5">
                  {report.marketAnalysis.threats.map(
                    (thr: string, idx: number) => <li key={idx}>{thr}</li>
                  )}
                </ul>
              </>
            )}
        </div>
      )}

      {/* SERVICE STRATEGY */}
      {report.serviceStrategy && (
        <div>
          <h3 className="text-xl font-semibold text-black mb-4">
            Service Strategy
          </h3>
          {Array.isArray(report.serviceStrategy.coreServices) &&
            report.serviceStrategy.coreServices.length > 0 && (
              <>
                <p className="font-medium">Core Services:</p>
                <ul className="list-disc pl-5">
                  {report.serviceStrategy.coreServices.map(
                    (srv: string, idx: number) => <li key={idx}>{srv}</li>
                  )}
                </ul>
              </>
            )}
          <p className="mt-2">
            <strong>Value Proposition:</strong>{' '}
            {report.serviceStrategy.valueProposition || 'N/A'}
          </p>
          <p className="mt-2">
            <strong>Delivery Model:</strong>{' '}
            {report.serviceStrategy.deliveryModel || 'N/A'}
          </p>
          {Array.isArray(report.serviceStrategy.differentiators) &&
            report.serviceStrategy.differentiators.length > 0 && (
              <>
                <p className="mt-2 font-medium">Differentiators:</p>
                <ul className="list-disc pl-5">
                  {report.serviceStrategy.differentiators.map(
                    (diff: string, idx: number) => <li key={idx}>{diff}</li>
                  )}
                </ul>
              </>
            )}
        </div>
      )}
    </div>
  );
}

/* ────────────────────────────────────────────────────────── */
/*  AdminDashboard component                                  */
/* ────────────────────────────────────────────────────────── */
export function AdminDashboard() {
  const navigate = useNavigate();
  const { user, isAdmin } = useAuthStore();

  const [users, setUsers] = useState<UserRecord[]>([]);
  const [chartData, setChartData] = useState<ChartDataPoint[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const [isDemoChart, setIsDemoChart] = useState(false);

  /* chat popup */
  const [isChatOpen, setIsChatOpen] = useState(false);
  const [chatUserId, setChatUserId] = useState<string | null>(null);
  const [chatUserEmail, setChatUserEmail] = useState<string | null>(null);

  /* unread badge per user */
  const [unreadCount, setUnreadCount] = useState<Record<string, number>>({});

  /* single-user view */
  const [viewingUserId, setViewingUserId] = useState<string | null>(null);
  const [viewingUserModules, setViewingUserModules] = useState<any[]>([]);
  const [viewingUserQuestions, setViewingUserQuestions] =
    useState<Record<string, any[]>>({});
  const [viewingUserResponses, setViewingUserResponses] =
    useState<Record<string, string>>({});
  const [viewingUserFinalReport, setViewingUserFinalReport] = useState<any>(null);
  const [openModuleId, setOpenModuleId] = useState<string | null>(null);

  /* delete confirmation */
  const [deleteConfirmActive, setDeleteConfirmActive] =
    useState<string | null>(null);

  /* ────────────────────────────────────────────────────────── */
  /*  Initial load + unread polling                             */
  /* ────────────────────────────────────────────────────────── */
  useEffect(() => {
    if (!isAdmin) {
      navigate('/modules');
      return;
    }

    fetchData();
    fetchUnreadCounts();

    const interval = window.setInterval(() => {
      fetchUnreadCounts();
    }, 1000);

    return () => clearInterval(interval);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isAdmin, navigate]);

  /* unread helper */
  const fetchUnreadCounts = async () => {
    if (!user?.id) return;
    try {
      const { data, error } = await serviceRoleSupabase
        .from('messages')
        .select('sender_id, receiver_id, read')
        .eq('read', false)
        .eq('receiver_id', user.id);

      if (error) throw error;

      const counts = (data || []).reduce((acc: Record<string, number>, m) => {
        if (m.sender_id) {
          acc[m.sender_id] = (acc[m.sender_id] || 0) + 1;
        }
        return acc;
      }, {});
      setUnreadCount(counts);
    } catch (e) {
      console.error('Unread count error:', e);
    }
  };

  /* data + chart */
  const fetchData = async () => {
    try {
      setIsLoading(true);

      const { data, error } = await serviceRoleSupabase.auth.admin.listUsers();
      if (error) throw error;

      const allUsers = data.users.map((u: any) => ({
        id: u.id,
        email: u.email,
        created_at: u.created_at,
        last_sign_in_at: u.last_sign_in_at ?? null,
        is_admin: !!u.user_metadata?.claims_admin,
        is_approved: !!u.user_metadata?.claims_approved,
      })) as UserRecord[];

      allUsers.sort(
        (a, b) =>
          new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
      );
      setUsers(allUsers);

      const normalUsers = allUsers.filter((u) => !u.is_admin);
      const real = buildRealGrowth(normalUsers);
      setChartData(ensureAtLeastTwoPoints(real));
      setIsDemoChart(false);
    } catch (err: any) {
      toast.error('Failed to load data: ' + err.message);
    } finally {
      setIsLoading(false);
    }
  };

  const buildRealGrowth = (list: UserRecord[]) => {
    if (!list.length) return [];
    const dayMap: Record<string, number> = {};
    list.forEach((u) => {
      const d = new Date(u.created_at).toISOString().split('T')[0];
      dayMap[d] = (dayMap[d] || 0) + 1;
    });
    const sorted = Object.keys(dayMap).sort();
    let total = 0;
    return sorted.map((d) => {
      total += dayMap[d];
      return { date: d, user_count: total };
    });
  };

  const ensureAtLeastTwoPoints = (data: ChartDataPoint[]) =>
    data.length === 1
      ? [
          data[0],
          {
            date: new Date(
              new Date(data[0].date).getTime() + 86400000
            ).toISOString().split('T')[0],
            user_count: data[0].user_count,
          },
        ]
      : data;

  /* ────────────────────────────────────────────────────────── */
  /*  View / chat / approve handlers                            */
  /* ────────────────────────────────────────────────────────── */
  const handleChat = (id: string, email: string) => {
    setChatUserId(id);
    setChatUserEmail(email);
    setIsChatOpen(true);
  };

  const toggleModule = (mId: string) =>
    setOpenModuleId((prev) => (prev === mId ? null : mId));

  /* view user (unchanged from earlier full file) */
  const handleView = async (uid: string) => {
    setViewingUserId(uid);
    window.scrollTo(0, 0);
    setIsLoading(true);

    try {
      const { data: mods } = await serviceRoleSupabase
        .from('modules')
        .select('*')
        .order('order');
      const { data: qs } = await serviceRoleSupabase
        .from('questions')
        .select('*')
        .order('order');
      const { data: rs } = await serviceRoleSupabase
        .from('user_responses')
        .select('question_id, content')
        .eq('user_id', uid)
        .order('updated_at', { ascending: false });

      /* bucket qs */
      const byMod: Record<string, any[]> = {};
      (qs || []).forEach((q: any) => {
        const mid = q.module_id.toString();
        if (!byMod[mid]) byMod[mid] = [];
        byMod[mid].push(q);
      });

      const respMap: Record<string, string> = {};
      (rs || []).forEach((r) => {
        respMap[r.question_id.toString()] = r.content;
      });

      /* final report */
      let rpt: any = null;
      const { data: settings } = await serviceRoleSupabase
        .from('user_settings')
        .select('final_report')
        .eq('user_id', uid)
        .maybeSingle();
      if (settings?.final_report) {
        try {
          rpt =
            typeof settings.final_report === 'string'
              ? JSON.parse(settings.final_report)
              : settings.final_report;
        } catch {/* ignore */}
      }

      setViewingUserModules(mods || []);
      setViewingUserQuestions(byMod);
      setViewingUserResponses(respMap);
      setViewingUserFinalReport(rpt);
      setOpenModuleId(null);
    } catch (e: any) {
      toast.error('Failed to load user data: ' + e.message);
    } finally {
      setIsLoading(false);
    }
  };

  const handleApproveUser = async (usr: UserRecord) => {
    try {
      await serviceRoleSupabase.auth.admin.updateUserById(usr.id, {
        user_metadata: { claims_approved: true },
      });
      toast.success(`User ${usr.email} is now approved!`);
      setUsers((prev) =>
        prev.map((u) => (u.id === usr.id ? { ...u, is_approved: true } : u))
      );
    } catch (e: any) {
      toast.error('Error approving user: ' + e.message);
    }
  };

  /* ────────────────────────────────────────────────────────── */
  /*  Delete user – **fixed** to use updateUserById             */
  /* ────────────────────────────────────────────────────────── */
  const handleDelete = async (uid: string) => {
    try {
      const target = users.find((u) => u.id === uid);

      /* 1) if target is admin, first strip admin flag */
      if (target?.is_admin) {
        await serviceRoleSupabase.auth.admin.updateUserById(uid, {
          user_metadata: { claims_admin: false },
        });
      }

      /* 2) purge row-level data */
      await serviceRoleSupabase.from('user_responses').delete().eq('user_id', uid);
      await serviceRoleSupabase.from('user_settings').delete().eq('user_id', uid);
      await serviceRoleSupabase
        .from('messages')
        .delete()
        .or(`sender_id.eq.${uid},receiver_id.eq.${uid}`);
      await serviceRoleSupabase.from('module_progress').delete().eq('user_id', uid);
      await serviceRoleSupabase.from('completed_modules').delete().eq('user_id', uid);

      /* 3) finally remove auth user */
      const { error } = await serviceRoleSupabase.auth.admin.deleteUser(uid);
      if (error) throw error;

      toast.success('User deleted successfully');
      setUsers((prev) => prev.filter((u) => u.id !== uid));
      setViewingUserId(null);
    } catch (e: any) {
      toast.error('Failed to delete user: ' + e.message);
    }
  };

  const confirmDelete = async () => {
    if (!deleteConfirmActive) return;
    await handleDelete(deleteConfirmActive);
    setDeleteConfirmActive(null);
  };

  const handleReturnToList = () => {
    setViewingUserId(null);
    setViewingUserModules([]);
    setViewingUserQuestions({});
    setViewingUserResponses({});
    setViewingUserFinalReport(null);
    setOpenModuleId(null);
  };

  /* ────────────────────────────────────────────────────────── */
  /*  Loading spinner                                           */
  /* ────────────────────────────────────────────────────────── */
  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-screen bg-[#1E3A8A]">
        <div className="animate-spin rounded-full h-32 w-32 border-t-2 border-b-2 border-white" />
      </div>
    );
  }

  /* ────────────────────────────────────────────────────────── */
  /*  Single-user view                                          */
  /* ────────────────────────────────────────────────────────── */
  if (viewingUserId) {
    return (
      <div className="p-8 bg-[#1E3A8A] min-h-screen">
        <button
          onClick={handleReturnToList}
          className="btn-secondary mb-6 flex items-center gap-2"
        >
          <ArrowLeft className="h-5 w-5" />
          Return to User List
        </button>

        <div className="bg-white rounded-xl shadow-sm border p-4">
          <h1 className="text-2xl font-bold mb-8 text-black">
            User Modules &amp; Answers
          </h1>

          <div className="space-y-4">
            {viewingUserModules
              .filter((m) => m.slug !== 'final-report')
              .map((mod) => {
                const mId = mod.id.toString();
                return (
                  <div
                    key={mod.id}
                    className="bg-white rounded-xl shadow-sm border p-4"
                  >
                    <div
                      className="flex items-center cursor-pointer gap-2"
                      onClick={() => toggleModule(mId)}
                    >
                      <h2 className="text-xl font-semibold text-black">
                        {mod.title}
                      </h2>
                      <ChevronDown
                        className={`h-5 w-5 transition-transform ${
                          openModuleId === mId ? 'rotate-180' : ''
                        }`}
                      />
                    </div>
                    {openModuleId === mId && (
                      <div className="mt-4 space-y-4">
                        {(viewingUserQuestions[mId] || []).map((q) => {
                          const ans =
                            viewingUserResponses[q.id.toString()] ||
                            '(no answer)';
                          return (
                            <div
                              key={q.id}
                              className="bg-gray-100 p-4 rounded-lg"
                            >
                              <p className="text-black font-medium mb-2">
                                {q.content}
                              </p>
                              <p className="text-slate-700 whitespace-pre-wrap">
                                {ans}
                              </p>
                            </div>
                          );
                        })}
                      </div>
                    )}
                  </div>
                );
              })}

            {/* final report */}
            <div className="bg-white rounded-xl shadow-sm border p-4">
              <div
                className="flex items-center cursor-pointer gap-2"
                onClick={() => toggleModule('final-report')}
              >
                <h2 className="text-xl font-semibold text-black">
                  Final Report
                </h2>
                <ChevronDown
                  className={`h-5 w-5 transition-transform ${
                    openModuleId === 'final-report' ? 'rotate-180' : ''
                  }`}
                />
              </div>
              {openModuleId === 'final-report' && (
                <div className="mt-4">
                  <FinalReportDisplay report={viewingUserFinalReport} />
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    );
  }

  /* ────────────────────────────────────────────────────────── */
  /*  Main dashboard                                            */
  /* ────────────────────────────────────────────────────────── */
  return (
    <div className="p-8 bg-[#1E3A8A] min-h-screen text-white">
      {/* chart */}
      <div className="mb-8 bg-white p-6 rounded-xl shadow-sm">
        <h2 className="text-xl font-semibold mb-4 text-black">
          Total Registered
        </h2>
        {chartData.length === 0 ? (
          <p className="text-black">No user sign-ups yet.</p>
        ) : (
          <UserGrowthChart
            data={chartData.map((d) => ({ day: d.date, count: d.user_count }))}
            bwMode={isDemoChart}
          />
        )}
      </div>

      {/* user list */}
      <div className="space-y-4">
        {users.map((usr) => (
          <div
            key={usr.id}
            className="bg-white p-6 rounded-xl shadow-sm text-black"
          >
            <div className="flex flex-col gap-1 md:flex-row md:items-center md:justify-between">
              <div>
                <div className="flex items-center gap-2 mb-1">
                  {usr.is_admin && (
                    <span className="inline-block px-2 py-1 text-xs font-medium bg-[#1E3A8A] text-white rounded">
                      Admin
                    </span>
                  )}
                  <h3 className="text-lg font-medium">{usr.email}</h3>
                </div>
                <p className="text-sm text-gray-500">
                  Joined: {new Date(usr.created_at).toLocaleString()}
                </p>
                <p className="text-sm text-gray-500">
                  Last active:{' '}
                  {usr.last_sign_in_at
                    ? new Date(usr.last_sign_in_at).toLocaleString()
                    : 'N/A'}
                </p>
                {!usr.is_approved && (
                  <p className="text-sm text-red-600 mt-1">Not approved yet</p>
                )}
              </div>

              <div className="flex gap-3 mt-3 md:mt-0">
                {!usr.is_approved && (
                  <button
                    onClick={() => handleApproveUser(usr)}
                    className="btn-secondary p-2 rounded-lg hover:bg-[#14306d]"
                    title="Approve User"
                  >
                    <CheckCircle className="h-5 w-5" />
                  </button>
                )}

                <button
                  onClick={() => handleChat(usr.id, usr.email)}
                  className="btn-secondary p-2 rounded-lg relative hover:bg-[#14306d]"
                  title="Message"
                >
                  <MessageCircle className="h-5 w-5" />
                  {unreadCount[usr.id] > 0 && (
                    <span className="absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center">
                      {unreadCount[usr.id]}
                    </span>
                  )}
                </button>

                <button
                  onClick={() => handleView(usr.id)}
                  className="btn-secondary p-2 rounded-lg hover:bg-[#14306d]"
                  title="View"
                >
                  <Eye className="h-5 w-5" />
                </button>

                <button
                  onClick={() => setDeleteConfirmActive(usr.id)}
                  className="btn-secondary p-2 rounded-lg hover:bg-[#14306d]"
                  title="Delete"
                >
                  <Trash className="h-5 w-5" />
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* chat popup */}
      {isChatOpen && (
        <ChatInterface
          onClose={() => {
            setIsChatOpen(false);
            setChatUserId(null);
            setChatUserEmail(null);
            fetchUnreadCounts();
          }}
          userId={chatUserId}
          userEmail={chatUserEmail}
          hideReturnButton
        />
      )}

      {/* delete confirmation */}
      {deleteConfirmActive && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
          <div className="bg-white p-6 rounded-xl shadow-lg w-full max-w-sm text-black">
            <h2 className="text-xl font-semibold mb-4 text-center">
              Confirm Deletion
            </h2>
            <p className="mb-6 text-center">
              Are you sure you want to delete this user?
            </p>
            <div className="flex justify-center gap-3">
              <button
                className="btn-secondary px-4 py-2"
                onClick={() => setDeleteConfirmActive(null)}
              >
                Return
              </button>
              <button
                className="btn-primary px-4 py-2"
                onClick={confirmDelete}
              >
                Continue
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
