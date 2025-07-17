// src/components/ModuleContent.tsx
/* eslint-disable react-hooks/exhaustive-deps */
import React, { useEffect, useState, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useModuleStore } from '../store/moduleStore';
import {
  ArrowLeft,
  ArrowRight,
  Loader2,
  ChevronDown,
  RefreshCw,
} from 'lucide-react';
import { toast } from 'sonner';
import { analyzeResponses } from '../lib/openai';
import { AIAnalysis } from './AIAnalysis';
import { StrategyAnalysis } from './StrategyAnalysis';
import { PricingAnalysis } from './PricingAnalysis';
import { OpportunityMapAnalysis } from './OpportunityMapAnalysis';
import { PositioningAnalysis } from './PositioningAnalysis';
import { supabase } from '../lib/supabase';
import { useAuthStore } from '../store/authStore';
import { saveAs } from 'file-saver';
import { jsPDF } from 'jspdf';

/* -------------------------------------------------------------------------- */
/* PDF helper (unchanged)                                                     */
/* -------------------------------------------------------------------------- */
function formatAnalysisForPdf(analysis: any, moduleSlug: string): string[] {
  const lines: string[] = [];
  const bullet = (arr: string[], indent = '') =>
    arr.map((s) => `${indent}• ${s}`);

  switch (moduleSlug) {
    case 'capabilities-inventory':
      lines.push('Capabilities Inventory', '');
      if (analysis.practices?.length) {
        lines.push('Practices:', ...bullet(analysis.practices, '  '));
      }
      if (analysis.niches?.length) {
        lines.push('', 'Niches:', ...bullet(analysis.niches, '  '));
      }
      break;
    /* … other cases unchanged … */
    default:
      lines.push('Consulting Strategy', '', JSON.stringify(analysis, null, 2));
  }
  return lines;
}

/* -------------------------------------------------------------------------- */
/* Final-report analysis component (unchanged)                                */
/* -------------------------------------------------------------------------- */
function FinalReportAnalysis({
  isLoading,
  analysis,
  error,
  onReturn,
}: {
  isLoading: boolean;
  analysis: any;
  error?: string | null;
  onReturn: () => void;
}) {
  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center space-y-4 min-h-[400px] w-full">
        <Loader2 className="h-12 w-12 text-[#1E3A8A] animate-[smooth-spin_1s_linear_infinite]" />
        <p className="text-lg font-medium text-slate-700">Creating</p>
      </div>
    );
  }
  if (error)
    return (
      <div className="flex flex-col items-center justify-center space-y-4 min-h-[400px] w-full">
        <div className="bg-red-50 text-red-800 p-4 rounded-xl max-w-md text-center">
          <p className="font-medium mb-2">Analysis Failed</p>
          <p className="text-sm">{error}</p>
        </div>
      </div>
    );
  if (!analysis)
    return (
      <div className="flex flex-col items-center justify-center space-y-4 min-h-[400px] w-full">
        <p className="text-slate-700">No final report data was found.</p>
      </div>
    );

  /* …rest of FinalReportAnalysis unchanged… */
  return (
    <div className="min-h-[400px] w-full flex flex-col">
      {/* existing JSX */}
    </div>
  );
}

/* -------------------------------------------------------------------------- */
/* Main ModuleContent component                                               */
/* -------------------------------------------------------------------------- */
export default function ModuleContent() {
  const navigate = useNavigate();
  const { moduleId } = useParams();

  /* ──────────────── local state ──────────────── */
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
  const [answer, setAnswer] = useState('');
  const [progress, setProgress] = useState(0);
  const [displayProgress, setDisplayProgress] = useState(0);
  const [isTransitioning, setIsTransitioning] = useState(false);
  const [direction, setDirection] = useState<'next' | 'prev'>('next');
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [analysis, setAnalysis] = useState<any>(null);
  const [analysisError, setAnalysisError] = useState<string | null>(null);
  const [showLoading, setShowLoading] = useState(false);
  const [showGenerateButton, setShowGenerateButton] = useState(false);
  const [showDownloadOptions, setShowDownloadOptions] = useState(false);
  const [isModuleLoading, setIsModuleLoading] = useState(true);
  const [noQuestionsFound, setNoQuestionsFound] = useState(false);
  const [retryCount, setRetryCount] = useState(0);

  /* ──────────────── refs ──────────────── */
  const prevAnswer = useRef('');
  const hasTyped = useRef(false);
  const dropdownRef = useRef<HTMLDivElement | null>(null);

  /* ──────────────── stores ──────────────── */
  const { user } = useAuthStore();
  const {
    currentModule,
    questions,
    responses,
    fetchModuleBySlug,
    fetchResponses,
    saveResponse,
    updateProgress,
    modules,
    moduleProgress,
    unlockNextModule,
    selectedPractice,
    selectedNiche,
    setSelectedPractice,
    setSelectedNiche,
    fetchQuestions,
    allQuestions,
    fetchAllQuestions,
  } = useModuleStore();

  const currentQuestion = questions[currentQuestionIndex];

  /* ---------------- effect: load module ---------------- */
  useEffect(() => {
    let ignore = false;

    const load = async () => {
      setIsModuleLoading(true);
      const mod = await fetchModuleBySlug(moduleId || '');
      if (!mod) {
        setNoQuestionsFound(true);
        setIsModuleLoading(false);
        return;
      }

      await fetchResponses(mod.id);
      setIsModuleLoading(false);
    };

    load();
    return () => {
      ignore = true;
    };
  }, [moduleId]);

  /* ---------------- effect: keep answer sync ---------------- */
  useEffect(() => {
    if (questions.length) {
      const saved = responses[questions[currentQuestionIndex]?.id] || '';
      setAnswer(saved);
      prevAnswer.current = saved;
      hasTyped.current = false;
    }
  }, [currentQuestionIndex, questions, responses]);

  /* ---------------- auto-save debounce -------------------- */
  useEffect(() => {
    if (!currentQuestion || !hasTyped.current) return;
    const t = setTimeout(
      () =>
        answer.trim() &&
        saveResponse(currentQuestion.id, answer).catch(() => {}),
      1000
    );
    return () => clearTimeout(t);
  }, [answer, currentQuestion, saveResponse]);

  /* ---------------- handlers ------------------------------ */
  const handleAnswerChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setAnswer(e.target.value);
    hasTyped.current = true;
  };

  const handlePrevious = () => {
    if (isTransitioning) return;
    if (currentQuestionIndex === 0) {
      const idx = modules.findIndex((m) => m.id === currentModule?.id);
      navigate(idx > 0 ? `/modules/${modules[idx - 1].slug}` : '/modules');
      return;
    }
    setDirection('prev');
    setIsTransitioning(true);
    setTimeout(() => {
      setCurrentQuestionIndex((i) => i - 1);
      setIsTransitioning(false);
    }, 280);
  };

  const handleNext = async () => {
    if (isTransitioning || !currentQuestion) return;
    if (answer.trim()) await saveResponse(currentQuestion.id, answer);
    if (currentQuestionIndex === questions.length - 1) {
      setShowLoading(true);
      return handleAnalysis();
    }
    setDirection('next');
    setIsTransitioning(true);
    setTimeout(() => {
      setCurrentQuestionIndex((i) => i + 1);
      setIsTransitioning(false);
    }, 280);
  };

  /* ---------------- question card renderer ---------------- */
  const renderQuestionCard = () => (
    <div className="bg-white rounded-xl shadow-lg p-6 md:min-h-[496px] w-full md:min-w-[920px] flex flex-col">
      <div className="text-xs text-slate-500 mb-2">
        {currentQuestionIndex + 1}/{questions.length}
      </div>
      <h2 className="text-2xl font-semibold text-slate-900 mb-6">
        {currentQuestion.content}
      </h2>
      <textarea
        value={answer}
        onChange={handleAnswerChange}
        className="w-full min-h-[320px] p-6 bg-white text-slate-900 rounded-xl resize-none focus:border-black transition-colors text-lg leading-relaxed flex-grow"
        placeholder="Share your thoughts…"
      />
      <div className="flex justify-between mt-6">
        <button
          onClick={handlePrevious}
          className="btn-secondary flex items-center justify-center min-w-[140px]"
        >
          <ArrowLeft className="h-5 w-5 mr-2" />
          Return
        </button>
        <button
          onClick={handleNext}
          disabled={!answer.trim()}
          className="btn-primary flex items-center justify-center min-w-[140px]"
        >
          Continue
          <ArrowRight className="h-5 w-5 ml-2" />
        </button>
      </div>
    </div>
  );

  /* ---------------- top-level return --------------------- */
  return (
    <div className="w-full max-w-[1200px] mx-auto px-4 md:px-8 py-12 bg-[#E0F2FF] relative">
      {/* … existing intro / analysis / download UI (unchanged) … */}

      {!analysis && !isModuleLoading && currentQuestion && renderQuestionCard()}

      {/* ──────────────────────────────────────────────────────────────── */}
      {/* Practice / Niche badge  – SMALLER & LOWER ON MOBILE            */}
      {/* ──────────────────────────────────────────────────────────────── */}
      {(() => {
        const sf = modules.find((m) => m.slug === 'strategy-framework');
        const unlocked = sf ? !!moduleProgress[sf.id] : false;
        if (!unlocked || (!selectedPractice && !selectedNiche)) return null;

        return (
          <div
            className="
              fixed bottom-2 md:bottom-4 left-2 md:left-4
              bg-white text-black rounded-xl shadow-lg
              p-1 md:p-4
              transform scale-50 md:scale-100 origin-bottom-left
              z-10 md:z-50      /* ↓ lower z on mobile so chat/copy beat it */
              pointer-events-none
            "
          >
            {selectedPractice && (
              <p className="text-xs md:text-sm font-medium">
                Practice:&nbsp;{selectedPractice}
              </p>
            )}
            {selectedNiche && (
              <p className="text-xs md:text-sm font-medium">
                Niche:&nbsp;{selectedNiche}
              </p>
            )}
          </div>
        );
      })()}
    </div>
  );
}
