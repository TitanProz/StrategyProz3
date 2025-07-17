import React from 'react';
import { Loader2, ArrowLeft, ArrowRight } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useModuleStore } from '../store/moduleStore';

interface StrategyAnalysisProps {
  isLoading: boolean;
  analysis: any;
  selectedPractice: string | null;
  error?: string | null;
  onReturn: () => void;
}

export function StrategyAnalysis({ isLoading, analysis, selectedPractice, error, onReturn }: StrategyAnalysisProps) {
  const navigate = useNavigate();
  const { modules, currentModule } = useModuleStore();

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
      </div>
    );
  }

  if (!analysis) return null;

  const isLastModule =
    currentModule &&
    modules.findIndex((m) => m.id === currentModule.id) === modules.length - 1;

  const handleNext = () => {
    if (!currentModule) return;
    const currentIndex = modules.findIndex((m) => m.id === currentModule.id);
    if (currentIndex < modules.length - 1) {
      navigate(`/modules/${modules[currentIndex + 1].slug}`);
    }
  };

  return (
    <div className="min-h-[400px] w-full flex flex-col">
      <div className="flex-1 min-h-[400px]">
        {currentModule?.slug === 'strategy-framework' ? (
          <>
            {selectedPractice && (
              <div className="mb-8">
                <h2 className="text-2xl font-bold text-slate-900 mb-6">
                  {selectedPractice}
                </h2>
              </div>
            )}
            <div className="space-y-8">
              <div>
                <h2 className="text-2xl font-bold text-slate-900 mb-6">Value Propositions:</h2>
                <ul className="space-y-4">
                  {analysis.valuePropositions.map((prop: string, index: number) => (
                    <li
                      key={index}
                      className="bg-white p-6 rounded-xl border-2 border-slate-200"
                    >
                      <p className="text-lg text-slate-900">{prop}</p>
                    </li>
                  ))}
                </ul>
              </div>

              <div>
                <h2 className="text-2xl font-bold text-slate-900 mb-6">Target Industries:</h2>
                <ul className="space-y-4">
                  {analysis.targetIndustries.map((industry: string, index: number) => (
                    <li
                      key={index}
                      className="bg-white p-6 rounded-xl border-2 border-slate-200"
                    >
                      <p className="text-lg text-slate-900">{industry}</p>
                    </li>
                  ))}
                </ul>
              </div>

              <div>
                <h2 className="text-2xl font-bold text-slate-900 mb-6">Ideal Clients:</h2>
                <ul className="space-y-4">
                  {analysis.idealClients.map((client: string, index: number) => (
                    <li
                      key={index}
                      className="bg-white p-6 rounded-xl border-2 border-slate-200"
                    >
                      <p className="text-lg text-slate-900">{client}</p>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          </>
        ) : currentModule?.slug === 'service-offering' ? (
          <div>
            <h2 className="text-2xl font-bold text-slate-900 mb-6">Service Tiers</h2>
            {(analysis.serviceTiers || []).map((tier: any, idx: number) => (
              <div
                key={idx}
                className="mb-6 bg-white p-6 rounded-xl border-2 border-slate-200"
              >
                <h3 className="text-xl font-semibold text-slate-900 mb-4">{tier.name}</h3>
                <p className="text-lg text-slate-900 mb-2">
                  <strong>Key Features &amp; Benefits:</strong> {tier.features}
                </p>
                <p className="text-lg text-slate-900 mb-2">
                  <strong>Client Outcomes:</strong> {tier.outcomes}
                </p>
                <p className="text-lg text-slate-900">
                  <strong>Intangible Benefits:</strong> {tier.intangibleBenefits}
                </p>
              </div>
            ))}
          </div>
        ) : null}
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