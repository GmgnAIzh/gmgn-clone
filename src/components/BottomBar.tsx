'use client';

import { useTranslations } from 'next-intl';
import { Button } from '@/components/ui/button';
import {
  Wallet,
  Eye,
  TrendingUp,
  Target,
  PiggyBank,
  DollarSign
} from 'lucide-react';

export default function BottomBar() {
  const t = useTranslations();

  const tools = [
    { icon: TrendingUp, label: t('buttons.trending'), active: true },
    { icon: Wallet, label: t('buttons.wallet'), active: false },
    { icon: PiggyBank, label: t('buttons.holding'), active: false },
    { icon: Eye, label: t('buttons.watchlist'), active: false },
    { icon: TrendingUp, label: t('buttons.trending'), active: false },
    { icon: Target, label: t('buttons.tracker'), active: false },
    { icon: DollarSign, label: "PnL", active: false },
  ];

  return (
    <div className="bg-gray-900 border-t border-gray-800 p-4">
      <div className="flex items-center justify-between">
        {/* Left side - Tools */}
        <div className="flex items-center space-x-2">
          {tools.map((tool, index) => {
            const Icon = tool.icon;
            return (
              <Button
                key={index}
                variant={tool.active ? "default" : "ghost"}
                size="sm"
                className={`flex items-center space-x-2 ${
                  tool.active
                    ? "bg-green-600 hover:bg-green-700 text-white"
                    : "text-gray-400 hover:text-white hover:bg-gray-800"
                }`}
              >
                <Icon className="h-4 w-4" />
                <span className="text-sm">{tool.label}</span>
              </Button>
            );
          })}
        </div>

        {/* Right side - Stats */}
        <div className="flex items-center space-x-6 text-sm">
          <div className="flex items-center space-x-2">
            <div className="w-3 h-3 bg-green-500 rounded-full"></div>
            <span className="text-white font-mono">$164.11</span>
          </div>
          <div className="flex items-center space-x-2">
            <div className="w-3 h-3 bg-blue-500 rounded-full"></div>
            <span className="text-white font-mono">$67.4K</span>
          </div>
        </div>
      </div>
    </div>
  );
}
