import React from 'react';
import { Loader2, ArrowLeft, ArrowRight } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useModuleStore } from '../store/moduleStore';

interface PositioningAnalysisProps {
  isLoading: boolean;
  analysis: any;
  error?: string | null;
  onReturn: () => void;
}

export function PositioningAnalysis({ isLoading, analysis, error, onReturn }: PositioningAnalysisProps) {
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

  const isLastModule = currentModule && modules.findIndex(m => m.id === currentModule.id) === modules.length - 1;

  return (
    <div className="min-h-[400px] w-full flex flex-col">
      <div className="flex-1 min-h-[400px] space-y-12">
        <div>
          <h2 className="text-2xl font-bold text-slate-900 mb-6">Top Niches</h2>
          {analysis.topNiches && analysis.topNiches.length > 0 ? (
            <div className="space-y-8">
              {analysis.topNiches.map((nicheItem: any, index: number) => (
                <div key={index} className="bg-white p-6 rounded-xl border-2 border-slate-200">
                  <h3 className="text-xl font-semibold text-slate-900 mb-4">{nicheItem.niche}</h3>
                  <p className="text-lg text-slate-700">{nicheItem.positioning}</p>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-slate-700">No niche analysis available.</p>
          )}
        </div>

        <div>
          <h2 className="text-2xl font-bold text-slate-900 mb-6">Risks & Obstacles</h2>
          {analysis.risksObstacles && analysis.risksObstacles.length > 0 ? (
            <div className="bg-white p-6 rounded-xl border-2 border-slate-200">
              <ul className="list-disc pl-5 space-y-2">
                {analysis.risksObstacles.map((risk: string, idx: number) => (
                  <li key={idx} className="text-lg text-slate-700">{risk}</li>
                ))}
              </ul>
            </div>
          ) : (
            <p className="text-slate-700">No risks analysis available.</p>
          )}
        </div>

        <div>
          <h2 className="text-2xl font-bold text-slate-900 mb-6">Strategies</h2>
          {analysis.strategies && analysis.strategies.length > 0 ? (
            <div className="bg-white p-6 rounded-xl border-2 border-slate-200">
              <ul className="list-disc pl-5 space-y-2">
                {analysis.strategies.slice(0, 5).map((strategy: string, idx: number) => (
                  <li key={idx} className="text-lg text-slate-700">{strategy}</li>
                ))}
              </ul>
            </div>
          ) : (
            <p className="text-slate-700">No strategies analysis available.</p>
          )}
        </div>

        <div>
          <h2 className="text-2xl font-bold text-slate-900 mb-6">Opportunity Matrix</h2>
          {analysis.opportunityMatrix && analysis.opportunityMatrix.length > 0 ? (
            <div className="space-y-8">
              {analysis.opportunityMatrix.map((opportunity: any, index: number) => (
                <div key={index} className="bg-white p-6 rounded-xl border-2 border-slate-200">
                  <h3 className="text-xl font-semibold text-slate-900 mb-4">{opportunity.service}</h3>
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
                    <div className="bg-gray-50 p-4 rounded-lg">
                      <p className="font-medium text-slate-900">Client Segment</p>
                      <p className="text-slate-700">{opportunity.segment}</p>
                    </div>
                    <div className="bg-gray-50 p-4 rounded-lg">
                      <p className="font-medium text-slate-900">Demand</p>
                      <p className={`font-medium ${
                        opportunity.demand === 'High' ? 'text-green-600' :
                        opportunity.demand === 'Medium' ? 'text-yellow-600' :
                        'text-red-600'
                      }`}>
                        {opportunity.demand}
                      </p>
                    </div>
                    <div className="bg-gray-50 p-4 rounded-lg">
                      <p className="font-medium text-slate-900">Ease of Entry</p>
                      <p className={`font-medium ${
                        opportunity.easeOfEntry === 'High' ? 'text-green-600' :
                        opportunity.easeOfEntry === 'Medium' ? 'text-yellow-600' :
                        'text-red-600'
                      }`}>
                        {opportunity.easeOfEntry}
                      </p>
                    </div>
                  </div>
                  <div className="bg-gray-50 p-4 rounded-lg mb-6">
                    <p className="font-medium text-slate-900">Profitability</p>
                    <p className={`font-medium ${
                      opportunity.profitability === 'High' ? 'text-green-600' :
                      opportunity.profitability === 'Medium' ? 'text-yellow-600' :
                      'text-red-600'
                    }`}>
                      {opportunity.profitability}
                    </p>
                  </div>
                  <div className="mb-4">
                    <h4 className="text-lg font-medium text-slate-900 mb-2">Risks</h4>
                    <ul className="list-disc pl-5 space-y-1">
                      {opportunity.risks.map((risk: string, idx: number) => (
                        <li key={idx} className="text-slate-700">{risk}</li>
                      ))}
                    </ul>
                  </div>
                  <div>
                    <h4 className="text-lg font-medium text-slate-900 mb-2">Recommended Strategies</h4>
                    <ul className="list-disc pl-5 space-y-1">
                      {opportunity.recommendedStrategies.map((strategy: string, idx: number) => (
                        <li key={idx} className="text-slate-700">{strategy}</li>
                      ))}
                    </ul>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-slate-700">No opportunity matrix available.</p>
          )}
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