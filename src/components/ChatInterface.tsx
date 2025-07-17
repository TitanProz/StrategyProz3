import React, { useState, useEffect, useRef } from 'react';
import { createClient } from '@supabase/supabase-js';
import { Send, Trash2, Loader2, ArrowLeft, X } from 'lucide-react';
import { useAuthStore } from '../store/authStore';
import { supabase } from '../lib/supabase';

/* ────────────────────────────────────────────────────────── */
/*  service-role client (admin read / delete helper)          */
/* ────────────────────────────────────────────────────────── */
const serviceRoleSupabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_SERVICE_ROLE_KEY
);

/* ────────────────────────────────────────────────────────── */
/*  Types                                                     */
/* ────────────────────────────────────────────────────────── */
interface Message {
  id: string;
  sender_id: string;
  receiver_id: string;
  content: string;
  created_at: string;
  read: boolean;
}

interface Conversation {
  participantId: string;
  participantEmail: string;
  lastMessage: string;
  lastTimestamp: string | null;
  isPinned: boolean;
  displayOrder: number;
  noMessagesYet?: boolean;
}

interface ChatInterfaceProps {
  onClose: () => void;
  userId?: string | null;
  userEmail?: string | null;
  setUnreadCount?: (count: number | ((c: number) => number)) => void;
  hideReturnButton?: boolean;
}

/* ────────────────────────────────────────────────────────── */
/*  Component                                                 */
/* ────────────────────────────────────────────────────────── */
export function ChatInterface({
  onClose,
  userId,
  userEmail,
  setUnreadCount,
  hideReturnButton = false,
}: ChatInterfaceProps) {
  const { user, isAdmin } = useAuthStore();

  const [loadingConversations, setLoadingConversations] = useState(false);
  const [loadingMessages, setLoadingMessages] = useState(false);
  const [sendingMessage, setSendingMessage] = useState(false);

  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [selectedConversationId, setSelectedConversationId] = useState<string | null>(userId || null);
  const [selectedConversationEmail, setSelectedConversationEmail] = useState<string>(userEmail || '');

  const [messages, setMessages] = useState<Message[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);

  const messagesEndRef = useRef<HTMLDivElement>(null);

  /* Disable background scroll when the chat is open (mobile full-screen) */
  useEffect(() => {
    const original = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = original;
    };
  }, []);

  /* ████████████████████████████████████████████████████████ */
  /*  Helpers                                                 */
  /* ████████████████████████████████████████████████████████ */

  const fetchConversationList = async (silent = false) => {
    if (!user) return;
    if (!silent) setLoadingConversations(true);

    try {
      const { data: msgData, error: msgErr } = await supabase
        .from('messages')
        .select('sender_id, receiver_id, content, created_at')
        .or(`sender_id.eq.${user.id},receiver_id.eq.${user.id}`)
        .order('created_at', { ascending: false });

      if (msgErr) throw msgErr;

      const latest: Record<string, Message | null> = {};
      (msgData || []).forEach((m: any) => {
        const pId = m.sender_id === user.id ? m.receiver_id : m.sender_id;
        if (!latest[pId]) latest[pId] = m;
      });

      const convs: Conversation[] = await Promise.all(
        Object.entries(latest).map(async ([pid, last]) => {
          let email = '(Unknown)';
          try {
            const { data: u } = await serviceRoleSupabase.auth.admin.getUserById(pid);
            if (u?.user?.email) email = u.user.email;
          } catch {/* ignore */}
          return {
            participantId: pid,
            participantEmail: email,
            lastMessage: last?.content ?? '',
            lastTimestamp: last?.created_at ?? null,
            isPinned: false,
            displayOrder: 0,
          };
        })
      );

      convs.sort((a, b) => (b.lastTimestamp || '').localeCompare(a.lastTimestamp || ''));
      setConversations(convs);
    } catch (err) {
      console.error('Conversation list error:', err);
    } finally {
      if (!silent) setLoadingConversations(false);
    }
  };

  const fetchMessages = async (participantId: string, silent = false) => {
    if (!user) return;
    if (!silent) setLoadingMessages(true);

    try {
      const { data: msgs, error } = await supabase
        .from('messages')
        .select('id, sender_id, receiver_id, content, created_at, read')
        .or(
          `and(sender_id.eq.${user.id},receiver_id.eq.${participantId}),and(sender_id.eq.${participantId},receiver_id.eq.${user.id})`
        )
        .order('created_at', { ascending: true });

      if (error) throw error;

      setMessages(msgs || []);

      // mark read
      const unreadIds = (msgs || [])
        .filter((m) => m.receiver_id === user.id && !m.read)
        .map((m) => m.id);
      if (unreadIds.length) {
        await supabase.from('messages').update({ read: true }).in('id', unreadIds);
        if (setUnreadCount) setUnreadCount(0);
      }
    } catch (err) {
      console.error('Message fetch error:', err);
    } finally {
      if (!silent) setLoadingMessages(false);
    }
  };

  const handleRealtimeInsert = (newMsg: any) => {
    if (!user) return;
    const otherId = newMsg.sender_id === user.id ? newMsg.receiver_id : newMsg.sender_id;

    if (otherId === selectedConversationId) {
      setMessages((prev) => [...prev, newMsg]);
      if (newMsg.receiver_id === user.id) {
        supabase.from('messages').update({ read: true }).eq('id', newMsg.id);
      }
    }

    setConversations((prev) => {
      const exists = prev.find((c) => c.participantId === otherId);
      if (exists) {
        const updated = { ...exists, lastMessage: newMsg.content, lastTimestamp: newMsg.created_at };
        return [updated, ...prev.filter((c) => c.participantId !== otherId)];
      }
      return prev;
    });

    if (newMsg.receiver_id === user.id && otherId !== selectedConversationId) {
      if (setUnreadCount) setUnreadCount((c) => (typeof c === 'number' ? c + 1 : 1));
    }
  };

  /* ████████████████████████████████████████████████████████ */
  /*  Effects                                                 */
  /* ████████████████████████████████████████████████████████ */

  useEffect(() => { if (user) fetchConversationList(false); }, [user]);
  useEffect(() => { if (user) { const id = setInterval(() => fetchConversationList(true), 1000); return () => clearInterval(id); } }, [user]);
  useEffect(() => {
    if (!selectedConversationId) return;
    fetchMessages(selectedConversationId, false);
    const id = setInterval(() => fetchMessages(selectedConversationId, true), 1000);
    return () => clearInterval(id);
  }, [selectedConversationId]);

  useEffect(() => {
    const channel = supabase
      .channel('realTimeMessages')
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'messages' }, (p) => handleRealtimeInsert(p.new))
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [selectedConversationId, user]);

  useEffect(() => { messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' }); }, [messages]);

  /* ████████████████████████████████████████████████████████ */
  /*  UI Handlers                                             */
  /* ████████████████████████████████████████████████████████ */
  const handleSelectConversation = (pid: string, pEmail: string) => {
    setSelectedConversationId(pid);
    setSelectedConversationEmail(pEmail);
  };

  const handleSend = async () => {
    if (!newMessage.trim() || !user?.id || !selectedConversationId) return;
    setSendingMessage(true);
    try {
      const { data, error } = await supabase
        .from('messages')
        .insert({
          sender_id: user.id,
          receiver_id: selectedConversationId,
          content: newMessage.trim(),
          read: false,
        })
        .select()
        .single();
      if (error) throw error;
      if (data) {
        setMessages((prev) => [...prev, data]);
        setNewMessage('');
      }
    } catch (err) {
      console.error('Send error:', err);
    } finally {
      setSendingMessage(false);
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const handleClose = () => {
    if (setUnreadCount) setUnreadCount(0);
    onClose();
  };

  /* ────────────────────────────────────────────────────────── */
  /*  Render                                                   */
  /* ────────────────────────────────────────────────────────── */
  return (
    <div
      className={`
        fixed z-50 flex flex-col bg-white shadow-lg
        inset-0 w-full h-full            /* mobile full-screen */
        md:bottom-8 md:right-8
        md:inset-auto md:w-[400px] md:h-[640px]
        border-t border-t-slate-200
        md:rounded-xl
        md:border-l-2 md:border-r-2 md:border-b-2
        md:border-l-[#1E3A8A] md:border-r-[#1E3A8A] md:border-b-[#1E3A8A]
      `}
      style={{ animation: 'fadeIn 0.2s ease-in-out' }}
    >
      {/* HEADER */}
      <div className="flex items-center justify-between border-b border-slate-200 px-4 py-3">
        {(!hideReturnButton && selectedConversationId) ? (
          <button
            onClick={() => setSelectedConversationId(null)}
            className="btn-secondary flex items-center gap-2 px-4 py-2"
          >
            <ArrowLeft className="h-5 w-5" />
            Return
          </button>
        ) : (
          <div className="w-[88px]" />
        )}

        <h3 className="text-lg font-semibold text-black text-center flex-1">Chat</h3>

        <div className="flex items-center gap-2 w-[88px] justify-end">
          <button
            onClick={handleClose}
            className="btn-secondary flex items-center gap-2 px-4 py-2"
            title="Close"
          >
            <X className="h-5 w-5" />
          </button>
        </div>
      </div>

      {/* PARTICIPANT EMAIL (desktop only to save space) */}
      {selectedConversationId && (
        <div className="hidden md:flex border-b border-slate-200 p-3 justify-center">
          <div className="border border-slate-300 px-3 py-1 rounded bg-white text-black text-sm font-medium">
            {selectedConversationEmail}
          </div>
        </div>
      )}

      {/* BODY */}
      <div className="flex-1 bg-[#1E3A8A] flex flex-col overflow-hidden">
        {/* CONVERSATION LIST */}
        {!selectedConversationId ? (
          <div className="flex-1 overflow-y-auto p-4">
            {loadingConversations ? (
              <div className="flex flex-col items-center justify-center h-full">
                <Loader2 className="h-8 w-8 text-white animate-spin" />
                <p className="text-white mt-2">Loading</p>
              </div>
            ) : conversations.length === 0 ? (
              <p className="text-white">
                {isAdmin ? 'Create conversations from the control panel' : 'Waiting for admin'}
              </p>
            ) : (
              <div className="space-y-3">
                {conversations.map((conv) => (
                  <div key={conv.participantId} className="relative p-3 rounded-lg border border-slate-300 bg-white">
                    <div
                      className="cursor-pointer pr-16"
                      onClick={() => handleSelectConversation(conv.participantId, conv.participantEmail)}
                    >
                      <p className="font-medium text-black">{conv.participantEmail}</p>
                      <p className="text-sm text-gray-600 mt-1">
                        {conv.lastMessage.length > 64 ? conv.lastMessage.slice(0, 64) + '…' : conv.lastMessage}
                      </p>
                    </div>
                    {isAdmin && (
                      <div className="absolute right-2 top-1/2 -translate-y-1/2">
                        <button
                          onClick={() => setDeleteConfirmId(conv.participantId)}
                          className="btn-secondary p-2 rounded-lg hover:bg-[#14306d]"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>
        ) : (
          /* MESSAGE LIST */
          <>
            <div className="flex-1 overflow-y-auto p-4">
              {loadingMessages ? (
                <div className="flex flex-col items-center justify-center h-full">
                  <Loader2 className="h-8 w-8 text-white animate-spin" />
                  <p className="text-white mt-2">Loading</p>
                </div>
              ) : (
                messages.map((m) => (
                  <div key={m.id} className={`mb-4 flex ${m.sender_id === user?.id ? 'justify-end' : 'justify-start'}`}>
                    <div className="max-w-[85%] md:max-w-[70%] p-3 rounded-lg bg-white text-black">
                      <p className="mb-1 whitespace-pre-wrap">{m.content}</p>
                      <span className="text-xs opacity-75">{new Date(m.created_at).toLocaleTimeString()}</span>
                    </div>
                  </div>
                ))
              )}
              <div ref={messagesEndRef} />
            </div>

            {/* COMPOSER */}
            <div className="p-4 border-t border-slate-200 flex items-center gap-2">
              <textarea
                className="flex-1 px-2 pt-[12px] pb-[2px] rounded-lg border border-slate-200 resize-none h-12 text-black"
                value={newMessage}
                onChange={(e) => setNewMessage(e.target.value)}
                onKeyPress={handleKeyPress}
                placeholder="Type your message…"
                disabled={sendingMessage}
              />
              <button
                onClick={handleSend}
                disabled={sendingMessage || !newMessage.trim()}
                className="bg-[#1E3A8A] text-white p-2 rounded-lg hover:bg-[#14306d] border border-white disabled:opacity-50"
              >
                {sendingMessage ? <Loader2 className="h-5 w-5 animate-spin" /> : <Send className="h-5 w-5" />}
              </button>
            </div>
          </>
        )}
      </div>

      {/* DELETE CONFIRMATION */}
      {deleteConfirmId && (
        <div className="absolute inset-0 bg-black bg-opacity-50 flex items-center justify-center rounded-none md:rounded-xl">
          <div className="bg-white p-6 rounded-lg shadow-lg max-w-sm mx-4">
            <h3 className="text-lg font-semibold mb-4">Confirm Deletion</h3>
            <p className="text-sm text-slate-700 mb-6">Delete this conversation?</p>
            <div className="flex justify-end gap-3">
              <button onClick={() => setDeleteConfirmId(null)} className="px-4 py-2 text-gray-600 hover:bg-gray-100 rounded">
                Return
              </button>
              <button
                onClick={async () => {
                  await serviceRoleSupabase
                    .from('messages')
                    .delete()
                    .or(
                      `and(sender_id.eq.${user?.id},receiver_id.eq.${deleteConfirmId}),and(sender_id.eq.${deleteConfirmId},receiver_id.eq.${user?.id})`
                    );
                  setConversations((p) => p.filter((c) => c.participantId !== deleteConfirmId));
                  if (selectedConversationId === deleteConfirmId) {
                    setSelectedConversationId(null);
                    setMessages([]);
                  }
                  setDeleteConfirmId(null);
                }}
                className="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
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
