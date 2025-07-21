/* eslint-disable react-hooks/exhaustive-deps */
import React, { useEffect, useState, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useModuleStore } from '../store/moduleStore';
import {
  ArrowLeft,
  ArrowRight,
  Loader2,
  RefreshCw,
  ChevronDown,
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
/* PDF helper                                                                  */
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

    case 'strategy-framework':
      lines.push('Strategy Framework', '');
      if (analysis.valuePropositions?.length) {
        lines.push(
          'Value Propositions:',
          ...bullet(analysis.valuePropositions, '  '),
          ''
        );
      }
      if (analysis.targetIndustries?.length) {
        lines.push(
          'Target Industries:',
          ...bullet(analysis.targetIndustries, '  '),
          ''
        );
      }
      if (analysis.idealClients?.length) {
        lines.push('Ideal Clients:', ...bullet(analysis.idealClients, '  '));
      }
      break;

    case 'opportunity-map':
      lines.push('Opportunity Map', '');
      (analysis.opportunityMapServices || []).forEach((srv: any) => {
        lines.push(`Service: ${srv.serviceName}`);
        lines.push(...bullet(srv.topIndustries, '  '));
        lines.push('');
      });
      (analysis.opportunityMapIndustries || []).forEach((ind: any) => {
        lines.push(`Industry: ${ind.industryName}`);
        lines.push(...bullet(ind.services, '  '));
        lines.push('');
      });
      break;

    case 'service-offering':
      lines.push('Service Offering', '');
      (analysis.serviceTiers || []).forEach((tier: any) => {
        lines.push(`${tier.name} Tier`);
        lines.push(`  Features: ${tier.features}`);
        lines.push(`  Outcomes: ${tier.outcomes}`);
        lines.push(`  Intangible Benefits: ${tier.intangibleBenefits}`, '');
      });
      break;

    case 'positioning':
      lines.push('Positioning', '');
      (analysis.topNiches || []).forEach((n: any) => {
        lines.push(`${n.niche}`, `  ${n.positioning}`, '');
      });
      lines.push(
        'Risks & Obstacles:',
        ...bullet(analysis.risksObstacles || [], '  '),
        ''
      );
      lines.push('Strategies:', ...bullet(analysis.strategies || [], '  '), '');
      break;

    case 'pricing':
      lines.push('Pricing Strategy', '');
      Object.entries(analysis).forEach(([k, v]) => {
        lines.push(
          `${k[0].toUpperCase() + k.slice(1)}:`,
          `  ${v as string}`,
          ''
        );
      });
      break;

    case 'final-report':
    default:
      lines.push(
        'Consulting Strategy Report',
        '',
        JSON.stringify(analysis, null, 2)
      );
  }
  return lines;
}

/* -------------------------------------------------------------------------- */
/* Final‑report analysis component                                            */
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

  return (
    <div className="min-h-[400px] w-full flex flex-col space-y-8">
      <h2 className="text-2xl font-bold text-slate-900">Executive Summary</h2>
      <div className="bg-white p-6 rounded-xl border-2 border-slate-200 space-y-4">
        <p className="text-lg text-slate-900 whitespace-pre-wrap">
          {analysis.executiveSummary?.overview}
        </p>
        <div>
          <p className="font-medium text-slate-900">Key Strategies</p>
          <ul className="list-disc pl-5 space-y-1">
            {(analysis.executiveSummary?.keyStrategies || []).map(
              (s: string, idx: number) => (
                <li key={idx} className="text-slate-700">
                  {s}
                </li>
              )
            )}
          </ul>
        </div>
        <p className="text-lg text-slate-900">
          <span className="font-medium">Vision: </span>
          {analysis.executiveSummary?.vision}
        </p>
      </div>

      {/* Additional sections can be rendered similarly */}

      <div className="flex justify-start mt-8">
        <button
          onClick={onReturn}
          className="btn-secondary flex items-center justify-center min-w-[160px]"
        >
          <ArrowLeft className="h-5 w-5 mr-2" />
          Return
        </button>
      </div>
    </div>
  );
}

/* -------------------------------------------------------------------------- */
/* Main ModuleContent component                                               */
/* -------------------------------------------------------------------------- */
export default function ModuleContent() {
  const navigate = useNavigate();
  const { moduleId = '' } = useParams();
  const effectiveSlug = moduleId || 'introduction';

  /* ─────────────────────── local state ─────────────────────── */
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
  const [answer, setAnswer] = useState('');
  const [isTransitioning, setIsTransitioning] = useState(false);
  const [direction, setDirection] = useState<'next' | 'prev'>('next');
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [analysis, setAnalysis] = useState<any>(null);
  const [analysisError, setAnalysisError] = useState<string | null>(null);
  const [showLoading, setShowLoading] = useState(false);
  const [isModuleLoading, setIsModuleLoading] = useState(true);

  /* ─────────────────────── refs ─────────────────────── */
  const hasTyped = useRef(false);

  /* ─────────────────────── stores ─────────────────────── */
  const { user } = useAuthStore();
  const {
    currentModule,
    questions,
    responses,
    fetchModuleBySlug,
    fetchResponses,
    saveResponse,
    modules,
    moduleProgress,
    unlockNextModule,
    selectedPractice,
    selectedNiche,
    setSelectedPractice,
    setSelectedNiche,
  } = useModuleStore();

  const currentQuestion = questions[currentQuestionIndex];

  /* -------------------- module loader -------------------- */
  useEffect(() => {
    const load = async () => {
      setIsModuleLoading(true);
      const mod = await fetchModuleBySlug(effectiveSlug);
      if (mod) await fetchResponses(mod.id);
      setIsModuleLoading(false);
    };
    load();
  }, [effectiveSlug, fetchModuleBySlug, fetchResponses]);

  /* -------------------- sync answer -------------------- */
  useEffect(() => {
    if (questions.length) {
      const saved = responses[questions[currentQuestionIndex]?.id] || '';
      setAnswer(saved);
      hasTyped.current = false;
    }
  }, [currentQuestionIndex, questions, responses]);

  /* -------------------- debounce auto‑save -------------------- */
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

  /* -------------------- handlers -------------------- */
  const handleAnswerChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setAnswer(e.target.value);
    hasTyped.current = true;
  };

  const handlePrevious = () => {
    if (isTransitioning) return;
    if (currentQuestionIndex === 0) {
      const idx = modules.findIndex((m) => m.id === currentModule?.id);
      navigate(
        idx > 0 ? `/modules/${modules[idx - 1].slug}` : '/modules/introduction'
      );
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

    /* Save the answer (with error handling) */
    if (answer.trim()) {
      try {
        await saveResponse(currentQuestion.id, answer);
      } catch (err: any) {
        console.error(err);
        toast.error(
          `Failed to save your answer – it will stay only in this session.\n${err?.message || err}`
        );
      }
    }

    /* Last question → analyze */
    if (currentQuestionIndex === questions.length - 1) {
      setShowLoading(true);
      return handleAnalysis();
    }

    /* Otherwise go to next */
    setDirection('next');
    setIsTransitioning(true);
    setTimeout(() => {
      setCurrentQuestionIndex((i) => i + 1);
      setIsTransitioning(false);
    }, 280);
  };

  /* -------------------- analysis -------------------- */
  const handleAnalysis = async () => {
    if (!currentModule) return;
    setIsAnalyzing(true);
    setAnalysisError(null);

    try {
      const result = await analyzeResponses(
        responses,
        selectedPractice ?? undefined,
        currentModule.slug
      );
      setAnalysis(result);

      if (user?.id) {
        const { error } = await supabase
          .from('user_settings')
          .upsert(
            { user_id: user.id, [`analysis_${currentModule.slug}`]: result },
            { onConflict: 'user_id' }
          );
        if (error) console.error('Save analysis error:', error);
      }

      await unlockNextModule(currentModule.id);
    } catch (err: any) {
      setAnalysisError(err.message || String(err));
    } finally {
      setShowLoading(false);
      setIsAnalyzing(false);
    }
  };

  /* -------------------- download PDF -------------------- */
  const downloadPdf = () => {
    if (!analysis || !currentModule) return;
    const doc = new jsPDF();
    const lines = formatAnalysisForPdf(analysis, currentModule.slug);
    doc.setFontSize(10);
    lines.forEach((l, idx) => {
      doc.text(l, 10, 15 + idx * 6);
    });
    doc.save(`${currentModule.slug}-analysis.pdf`);
  };

  /* -------------------- render question card -------------------- */
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
          disabled={
            !answer.trim() && currentQuestionIndex !== questions.length - 1
          }
          className="btn-primary flex items-center justify-center min-w-[140px]"
        >
          Continue
          <ArrowRight className="h-5 w-5 ml-2" />
        </button>
      </div>
    </div>
  );

  /* -------------------- main render -------------------- */
  return (
    <div className="w-full max-w-[1200px] mx-auto px-4 md:px-8 py-12 bg-[#E0F2FF] relative">
      {/* Loading */}
      {isModuleLoading && (
        <div className="flex items-center justify-center min-h-[400px]">
          <Loader2 className="h-12 w-12 text-[#1E3A8A] animate-[smooth-spin_1s_linear_infinite]" />
        </div>
      )}

      {/* Introduction */}
      {!isModuleLoading && effectiveSlug === 'introduction' && (
        <div className="bg-white rounded-xl shadow-lg p-6 w-full flex flex-col items-center space-y-6">
          <h2 className="text-2xl font-bold text-slate-900">
            Welcome to StrategyProz!
          </h2>
          <video
            className="w-full max-w-2xl rounded-lg border"
            controls
            poster="https://storage.googleapis.com/msgsndr/jY21tpLjXFAMvoP23PQ2/media/intro-thumb.png"
          >
            <source
              src="https://storage.googleapis.com/msgsndr/jY21tpLjXFAMvoP23PQ2/media/intro.mp4"
              type="video/mp4"
            />
            Your browser does not support the video tag.
          </video>
        </div>
      )}

      {/* Questionnaire */}
      {!analysis &&
        !isModuleLoading &&
        effectiveSlug !== 'introduction' &&
        currentQuestion &&
        renderQuestionCard()}

      {/* Loading / error */}
      {showLoading && (
        <div className="flex flex-col items-center justify-center space-y-4 min-h-[400px] w-full">
          <Loader2 className="h-12 w-12 text-[#1E3A8A] animate-[smooth-spin_1s_linear_infinite]" />
          <p className="text-lg font-medium text-slate-700">Analyzing</p>
        </div>
      )}
      {analysisError && (
        <div className="flex flex-col items-center justify-center space-y-4 min-h-[400px] w-full">
          <div className="bg-red-50 text-red-800 p-4 rounded-xl max-w-md text-center">
            <p className="font-medium mb-2">Analysis Failed</p>
            <p className="text-sm">{analysisError}</p>
            <button
              onClick={handleAnalysis}
              className="btn-primary flex items-center gap-2 mt-4"
            >
              <RefreshCw className="h-5 w-5" />
              Try Again
            </button>
          </div>
        </div>
      )}

      {/* Analysis views */}
      {analysis && currentModule?.slug === 'capabilities-inventory' && (
        <AIAnalysis
          analysis={analysis}
          isLoading={isAnalyzing}
          error={analysisError || undefined}
          onRetry={handleAnalysis}
          onReturn={() => setAnalysis(null)}
          onSelectPractice={(p) => setSelectedPractice(p)}
          onSelectNiche={(n) => setSelectedNiche(n)}
        />
      )}

      {analysis && currentModule?.slug === 'strategy-framework' && (
        <StrategyAnalysis
          analysis={analysis}
          isLoading={isAnalyzing}
          error={analysisError || undefined}
          selectedPractice={selectedPractice}
          onReturn={() => setAnalysis(null)}
        />
      )}

      {analysis && currentModule?.slug === 'opportunity-map' && (
        <OpportunityMapAnalysis
          analysis={analysis}
          isLoading={isAnalyzing}
          error={analysisError || undefined}
          onReturn={() => setAnalysis(null)}
        />
      )}

      {analysis && currentModule?.slug === 'positioning' && (
        <PositioningAnalysis
          analysis={analysis}
          isLoading={isAnalyzing}
          error={analysisError || undefined}
          onReturn={() => setAnalysis(null)}
        />
      )}

      {analysis && currentModule?.slug === 'pricing' && (
        <PricingAnalysis
          analysis={analysis}
          isLoading={isAnalyzing}
          error={analysisError || undefined}
          onReturn={() => setAnalysis(null)}
        />
      )}

      {analysis && currentModule?.slug === 'final-report' && (
        <FinalReportAnalysis
          analysis={analysis}
          isLoading={isAnalyzing}
          error={analysisError || undefined}
          onReturn={() => setAnalysis(null)}
        />
      )}

      {/* Practice / Niche badge */}
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
              z-10 md:z-50
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
