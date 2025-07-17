import React from 'react';
import { Loader2, ArrowLeft, ArrowRight } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useModuleStore } from '../store/moduleStore';

interface OpportunityMapAnalysisProps {
  isLoading: boolean;
  analysis: any;
  error?: string | null;
  onReturn: () => void;
}

export function OpportunityMapAnalysis({ isLoading, analysis, error, onReturn }: OpportunityMapAnalysisProps) {
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
          <h2 className="text-2xl font-bold text-slate-900 mb-6">Services Analysis</h2>
          {analysis.opportunityMapServices && analysis.opportunityMapServices.length > 0 ? (
            <div className="space-y-8">
              {analysis.opportunityMapServices.map((service: any, index: number) => (
                <div key={index} className="bg-white p-6 rounded-xl border-2 border-slate-200">
                  <h3 className="text-xl font-semibold text-slate-900 mb-4">{service.serviceName}</h3>
                  <div className="mb-4">
                    <h4 className="text-lg font-medium text-slate-900 mb-2">Top Industries</h4>
                    <ul className="list-disc pl-5 space-y-1">
                      {service.topIndustries.map((industry: string, idx: number) => (
                        <li key={idx} className="text-slate-700">{industry}</li>
                      ))}
                    </ul>
                  </div>
                  <div className="mb-4">
                    <h4 className="text-lg font-medium text-slate-900 mb-2">Why Good Target</h4>
                    <ul className="list-disc pl-5 space-y-1">
                      {service.whyGoodTarget.map((reason: string, idx: number) => (
                        <li key={idx} className="text-slate-700">{reason}</li>
                      ))}
                    </ul>
                  </div>
                  <div>
                    <h4 className="text-lg font-medium text-slate-900 mb-2">Risks</h4>
                    <ul className="list-disc pl-5 space-y-1">
                      {service.risks.map((risk: string, idx: number) => (
                        <li key={idx} className="text-slate-700">{risk}</li>
                      ))}
                    </ul>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-slate-700">No service analysis available.</p>
          )}
        </div>

        <div>
          <h2 className="text-2xl font-bold text-slate-900 mb-6">Industries Analysis</h2>
          {analysis.opportunityMapIndustries && analysis.opportunityMapIndustries.length > 0 ? (
            <div className="space-y-8">
              {analysis.opportunityMapIndustries.map((industry: any, index: number) => (
                <div key={index} className="bg-white p-6 rounded-xl border-2 border-slate-200">
                  <h3 className="text-xl font-semibold text-slate-900 mb-4">{industry.industryName}</h3>
                  <div className="mb-4">
                    <h4 className="text-lg font-medium text-slate-900 mb-2">Services</h4>
                    <ul className="list-disc pl-5 space-y-1">
                      {industry.services.map((service: string, idx: number) => (
                        <li key={idx} className="text-slate-700">{service}</li>
                      ))}
                    </ul>
                  </div>
                  <div className="mb-4">
                    <h4 className="text-lg font-medium text-slate-900 mb-2">Why Service Fits</h4>
                    <ul className="list-disc pl-5 space-y-1">
                      {industry.whyServiceFits.map((reason: string, idx: number) => (
                        <li key={idx} className="text-slate-700">{reason}</li>
                      ))}
                    </ul>
                  </div>
                  <div>
                    <h4 className="text-lg font-medium text-slate-900 mb-2">Risks</h4>
                    <ul className="list-disc pl-5 space-y-1">
                      {industry.risks.map((risk: string, idx: number) => (
                        <li key={idx} className="text-slate-700">{risk}</li>
                      ))}
                    </ul>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-slate-700">No industry analysis available.</p>
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