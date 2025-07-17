import React from 'react';
import { Loader2, ArrowLeft, ArrowRight } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useModuleStore } from '../store/moduleStore';

interface PricingAnalysisProps {
  isLoading: boolean;
  analysis: any;
  error?: string | null;
  onReturn: () => void;
}

export function PricingAnalysis({ isLoading, analysis, error, onReturn }: PricingAnalysisProps) {
  const navigate = useNavigate();
  const { modules, currentModule } = useModuleStore();

  const handleNext = () => {
    if (!currentModule) return;
    const currentIndex = modules.findIndex(m => m.id === currentModule.id);
    if (currentIndex < modules.length - 1) {
      navigate(`/modules/${modules[currentIndex + 1].slug}`);
    }
  };

  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center space-y-4 min-h-[400px] w-full">
        <Loader2 className="h-12 w-12 text-[#1E3A8A] animate-[smooth-spin_1s_linear_infinite]" />
        <p className="text-lg font-medium text-slate-700">Analyzing your pricing strategy...</p>
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
      </div>
    );
  }

  if (!analysis) return null;

  const isLastModule = currentModule && modules.findIndex(m => m.id === currentModule.id) === modules.length - 1;

  return (
    <div className="min-h-[400px] w-full flex flex-col">
      <div className="flex-1 min-h-[400px] space-y-8 overflow-y-auto">
        <div>
          <h2 className="text-2xl font-bold text-slate-900 mb-6">1. Market Rates</h2>
          <div className="bg-white p-6 rounded-xl border-2 border-slate-200">
            <p className="text-lg text-slate-900">{analysis.marketRates}</p>
          </div>
        </div>

        <div>
          <h2 className="text-2xl font-bold text-slate-900 mb-6">2. Pricing Justification & ROI</h2>
          <div className="bg-white p-6 rounded-xl border-2 border-slate-200">
            <p className="text-lg text-slate-900">{analysis.justification}</p>
          </div>
        </div>

        <div>
          <h2 className="text-2xl font-bold text-slate-900 mb-6">3. Transformational Benefits</h2>
          <div className="bg-white p-6 rounded-xl border-2 border-slate-200">
            <p className="text-lg text-slate-900">{analysis.benefits}</p>
          </div>
        </div>

        <div>
          <h2 className="text-2xl font-bold text-slate-900 mb-6">4. Revenue Targets</h2>
          <div className="bg-white p-6 rounded-xl border-2 border-slate-200">
            <p className="text-lg text-slate-900">{analysis.revenueTargets}</p>
          </div>
        </div>

        <div>
          <h2 className="text-2xl font-bold text-slate-900 mb-6">5. Constraints & Cost Structures</h2>
          <div className="bg-white p-6 rounded-xl border-2 border-slate-200">
            <p className="text-lg text-slate-900">{analysis.constraints}</p>
          </div>
        </div>

        <div>
          <h2 className="text-2xl font-bold text-slate-900 mb-6">6. Pricing Milestones</h2>
          <div className="bg-white p-6 rounded-xl border-2 border-slate-200">
            <p className="text-lg text-slate-900">{analysis.milestones}</p>
          </div>
        </div>

        <div>
          <h2 className="text-2xl font-bold text-slate-900 mb-6">7. Performance Tracking</h2>
          <div className="bg-white p-6 rounded-xl border-2 border-slate-200">
            <p className="text-lg text-slate-900">{analysis.tracking}</p>
          </div>
        </div>
      </div>

      <div className="flex justify-between mt-8">
        <button onClick={onReturn} className="btn-secondary flex items-center justify-center min-w-[160px]">
          <ArrowLeft className="h-5 w-5 mr-2" />
          Return
        </button>
        {!isLastModule && (
          <button onClick={handleNext} className="btn-primary flex items-center justify-center min-w-[160px]">
            Continue
            <ArrowRight className="h-5 w-5 ml-2" />
          </button>
        )}
      </div>
    </div>
  );
}