import React, { useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import {
  ClipboardList,
  Target,
  Map as MapIcon,
  FileStack,
  Grid,
  DollarSign,
  FileText,
  Lock,
  ChevronLeft,
  ChevronRight,
} from 'lucide-react';
import { useModuleStore } from '../store/moduleStore';

interface ModulesListProps {
  collapsed?: boolean;
  onToggle?: () => void;
}

const moduleIcons = {
  'capabilities-inventory': ClipboardList,
  'strategy-framework': Target,
  'opportunity-map': MapIcon,
  'service-offering': FileStack,
  positioning: Grid,
  pricing: DollarSign,
  'final-report': FileText,
};

export function ModulesList({ collapsed = false, onToggle }: ModulesListProps) {
  const navigate = useNavigate();
  const location = useLocation();
  const { modules, fetchModules, moduleProgress, completedModules } =
    useModuleStore();

  /* One‑time   */
  useEffect(() => {
    fetchModules();
  }, [fetchModules]);

  /* Helpers */
  const isModuleUnlocked = (m: any) =>
    m.slug === 'capabilities-inventory' ||
    m.order === 0 ||
    moduleProgress[m.id] ||
    completedModules.includes(m.id);

  const isCurrentModule = (slug: string) =>
    location.pathname === `/modules/${slug}`;

  /* ------------------------------------------------------------------ */
  /*                               JSX                                  */
  /* ------------------------------------------------------------------ */
  return (
    <div className="h-full bg-[#1E3A8A]">
      {/* Logo + collapse‑toggle */}
      <div className="h-20 flex items-center bg-[#1E3A8A] px-4">
        {!collapsed && (
          <img
            src="https://storage.googleapis.com/msgsndr/jY21tpLjXFAMvoP23PQ2/media/67fd379fa119418af4c5a319.png"
            alt="StrategyProz"
            className="h-12"
          />
        )}

        {onToggle && (
          <button
            onClick={onToggle}
            aria-label="Toggle sidebar"
            className={`text-white p-2 rounded hover:bg-white hover:bg-opacity-20 transition-colors
              ${collapsed ? 'ml-0' : 'ml-auto md:hidden'}
            `}
          >
            {collapsed ? (
              <ChevronRight className="h-5 w-5" />
            ) : (
              <ChevronLeft className="h-5 w-5" />
            )}
          </button>
        )}
      </div>

      {/* Scrollable list */}
      <nav className="p-4 md:p-6 overflow-y-auto h-[calc(100vh-5rem)]">
        {/* Introduction */}
        <button
          onClick={() => navigate('/modules/introduction')}
          className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl text-left transition-colors mb-4 module-hover ${
            location.pathname === '/modules/introduction'
              ? 'bg-white bg-opacity-20 text-white shadow-sm'
              : 'text-white'
          }`}
          title="Introduction"
        >
          <FileText className="h-5 w-5 shrink-0" />
          {!collapsed && <span className="font-medium">Introduction</span>}
        </button>

        {/* Other modules */}
        <div className="space-y-3">
          {modules.map((mod) => {
            const Icon =
              moduleIcons[mod.slug as keyof typeof moduleIcons] || FileText;
            const unlocked = isModuleUnlocked(mod);
            const active = isCurrentModule(mod.slug);
            const showLock = !unlocked && !active;

            return (
              <button
                key={mod.id}
                disabled={!unlocked && !active}
                onClick={() =>
                  (unlocked || active) && navigate(`/modules/${mod.slug}`)
                }
                className={`
                  w-full flex items-center gap-3 px-4 py-3 rounded-xl text-left transition-colors module-hover
                  ${
                    active
                      ? 'bg-white bg-opacity-20 text-white shadow-sm'
                      : unlocked
                      ? 'text-white'
                      : 'text-white opacity-50 cursor-not-allowed'
                  }
                `}
                title={mod.title}
              >
                <Icon className="h-5 w-5 shrink-0" />
                <div className="flex-1 min-w-0 flex items-center justify-between gap-2">
                  {!collapsed && (
                    <span className="font-medium truncate">{mod.title}</span>
                  )}
                  {showLock && !collapsed && (
                    <Lock className="h-4 w-4 shrink-0" />
                  )}
                </div>
              </button>
            );
          })}
        </div>
      </nav>
    </div>
  );
}
