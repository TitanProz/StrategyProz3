// src/components/AIAnalysis.tsx
import React, { useState } from 'react';
import { Loader2, RefreshCw, Check, ArrowRight, ArrowLeft } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useModuleStore } from '../store/moduleStore';

export function AIAnalysis({
  analysis,
  isLoading,
  error,
  onRetry,
  onReturn,
  onSelectPractice,
  onSelectNiche,
}: {
  analysis: any;
  isLoading: boolean;
  error?: string;
  onRetry?: () => void;
  onReturn?: () => void;
  onSelectPractice?: (practice: string) => void;
  onSelectNiche?: (niche: string) => void;
}) {
  const [selectedPracticeIndex, setSelectedPracticeIndex] = useState<
    number | null
  >(null);
  const [selectedNicheIndex, setSelectedNicheIndex] = useState<number | null>(
    null
  );

  const navigate = useNavigate();
  const { modules, currentModule } = useModuleStore();

  const handleContinueToNextModule = () => {
    if (!currentModule) return;
    const currentIndex = modules.findIndex((m) => m.id === currentModule.id);
    if (currentIndex < modules.length - 1) {
      navigate(`/modules/${modules[currentIndex + 1].slug}`);
    }
  };

  /* ─────────────────────────── loaders / errors ────────────────────────── */
  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center space-y-4 min-h-[400px] w-full">
        <Loader2 className="h-12 w-12 text-[#1E3A8A] animate-[smooth-spin_1s_linear_infinite]" />
        <p className="text-lg font-medium text-slate-700">Analyzing</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center space-y-4 min-h-[400px] w-full">
        <div className="bg-red-50 text-red-800 p-4 rounded-xl max-w-md text-center">
          <p className="font-medium mb-2">Analysis Failed</p>
          <p className="text-sm">{error}</p>
        </div>
        {onRetry && (
          <button onClick={onRetry} className="btn-primary flex items-center gap-2">
            <RefreshCw className="h-5 w-5" />
            Try Again
          </button>
        )}
      </div>
    );
  }

  if (!analysis) return null;

  /* ────────────────────── 1) PRACTICE SELECTION ────────────────────────── */
  if (
    Array.isArray(analysis.practices) &&
    Array.isArray(analysis.niches) &&
    analysis.niches.length === 0 &&
    onSelectPractice
  ) {
    return (
      <div className="min-h-[400px] w-full space-y-8">
        <h2 className="text-2xl font-bold text-slate-900 mb-6">
          Based on your responses, choose one consulting practice to pursue:
        </h2>

        <div className="space-y-6">
          {analysis.practices.map((practice: string, idx: number) => (
            <div
              key={idx}
              className={`p-6 rounded-xl bg-white border border-black transition-all cursor-pointer ${
                selectedPracticeIndex === idx
                  ? 'border-[#1E3A8A] bg-[#F0F7FF]'
                  : 'hover:border-[#1E3A8A] hover:bg-[#F0F7FF]'
              }`}
              onClick={() => setSelectedPracticeIndex(idx)}
            >
              <div className="flex items-center justify-between">
                <h3 className="text-xl font-semibold text-slate-900">
                  {practice}
                </h3>
                {selectedPracticeIndex === idx && (
                  <div className="bg-[#1E3A8A] text-white p-2 rounded-full">
                    <Check className="h-5 w-5" />
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>

        <div className="flex justify-between mt-8">
          {onReturn && (
            <button
              onClick={onReturn}
              className="btn-secondary flex items-center justify-center min-w-[160px]"
            >
              <ArrowLeft className="h-5 w-5 mr-2" />
              Return
            </button>
          )}

          <button
            onClick={() => {
              if (selectedPracticeIndex !== null && onSelectPractice) {
                onSelectPractice(analysis.practices[selectedPracticeIndex]);
              }
            }}
            className="btn-primary flex items-center justify-center min-w-[160px]"
          >
            Continue
            <ArrowRight className="h-5 w-5 ml-2" />
          </button>
        </div>
      </div>
    );
  }

  /* ────────────────────── 2) NICHE SELECTION ───────────────────────────── */
  if (
    analysis.selectedPractice &&
    Array.isArray(analysis.niches) &&
    analysis.niches.length > 0
  ) {
    return (
      <div className="min-h-[400px] w-full space-y-8">
        <h2 className="text-2xl font-bold text-slate-900 mb-6">
          Within <span className="font-semibold">{analysis.selectedPractice}</span>, pick a niche:
        </h2>

        <div className="space-y-4">
          {analysis.niches.map((niche: string, idx: number) => (
            <div
              key={idx}
              className={`p-6 rounded-xl bg-white border border-black cursor-pointer transition-all ${
                selectedNicheIndex === idx
                  ? 'border-[#1E3A8A] bg-[#F0F7FF]'
                  : 'hover:border-[#1E3A8A] hover:bg-[#F0F7FF]'
              }`}
              onClick={() => {
                setSelectedNicheIndex(idx);
                if (onSelectNiche) onSelectNiche(niche);
              }}
            >
              <div className="flex items-center justify-between">
                <h3 className="text-xl font-semibold text-slate-900">
                  {niche}
                </h3>
                {selectedNicheIndex === idx && (
                  <div className="bg-[#1E3A8A] text-white p-2 rounded-full">
                    <Check className="h-5 w-5" />
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>

        <div className="flex justify-between mt-8">
          {onReturn && (
            <button
              onClick={onReturn}
              className="btn-secondary flex items-center justify-center min-w-[160px]"
            >
              <ArrowLeft className="h-5 w-5 mr-2" />
              Return
            </button>
          )}

          <button
            onClick={handleContinueToNextModule}
            className="btn-primary flex items-center justify-center min-w-[160px]"
          >
            Continue
            <ArrowRight className="h-5 w-5 ml-2" />
          </button>
        </div>
      </div>
    );
  }

  /* ───────────────────────── 3) FALLBACK  ──────────────────────────────── */
  return (
    <div className="min-h-[400px] w-full space-y-8">
      <h2 className="text-2xl font-bold text-slate-900 mb-6">
        Suggested Consulting Practices &amp; Niches
      </h2>

      {Array.isArray(analysis.practices) && analysis.practices.length > 0 && (
        <>
          <h3 className="text-xl font-semibold text-slate-900">Practices:</h3>
          <ul className="list-disc pl-5 space-y-1">
            {analysis.practices.map((practice: string, idx: number) => (
              <li key={idx} className="text-slate-700">
                {practice}
              </li>
            ))}
          </ul>
        </>
      )}

      {Array.isArray(analysis.niches) && analysis.niches.length > 0 && (
        <>
          <h3 className="text-xl font-semibold text-slate-900 mt-6">Niches:</h3>
          <ul className="list-disc pl-5 space-y-1">
            {analysis.niches.map((niche: string, idx: number) => (
              <li key={idx} className="text-slate-700">
                {niche}
              </li>
            ))}
          </ul>
        </>
      )}

      <div className="flex justify-between mt-8">
        {onReturn && (
          <button
            onClick={onReturn}
            className="btn-secondary flex items-center justify-center min-w-[160px]"
          >
            <ArrowLeft className="h-5 w-5 mr-2" />
            Return
          </button>
        )}

        <button
          onClick={handleContinueToNextModule}
          className="btn-primary flex items-center justify-center min-w-[160px]"
        >
          Continue
          <ArrowRight className="h-5 w-5 ml-2" />
        </button>
      </div>
    </div>
  );
}
