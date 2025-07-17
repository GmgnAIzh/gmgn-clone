'use client';

import { useTranslations } from 'next-intl';
import { Button } from '@/components/ui/button';
import { TrendingUp, TrendingDown, Star, Filter, Eye } from 'lucide-react';
import { useSound } from '@/context/SoundContext';

interface Token {
  name: string;
  symbol: string;
  price: string;
  change: number;
  volume: string;
  marketCap: string;
  holders: number;
  image: string;
}

const mockTokens: Token[] = [
  {
    name: "BULLEON",
    symbol: "BULLEON",
    price: "$0.0054",
    change: 5.5,
    volume: "$1.2M",
    marketCap: "$6.1K",
    holders: 29,
    image: "🟡"
  },
  {
    name: "SUPREMEME",
    symbol: "SUPREMEME",
    price: "$0.0061",
    change: -2.3,
    volume: "$37.08",
    marketCap: "$48.1K",
    holders: 74,
    image: "🔴"
  },
  {
    name: "ATOM-AI",
    symbol: "ATOM-AI",
    price: "$0.083",
    change: 12.8,
    volume: "$131.3K",
    marketCap: "$138.5K",
    holders: 186,
    image: "🟢"
  },
  {
    name: "CHARLIE",
    symbol: "CHARLIE",
    price: "$0.71",
    change: 8.2,
    volume: "$220.4K",
    marketCap: "$56.8K",
    holders: 447,
    image: "🟠"
  },
  {
    name: "DUM",
    symbol: "DUM",
    price: "$0.0010",
    change: -1.2,
    volume: "$273.6",
    marketCap: "$4.8K",
    holders: 140,
    image: "🟤"
  },
];

export default function TokenList() {
  const t = useTranslations();
  const { playClick, playHover } = useSound();

  return (
    <div className="flex-1 p-6">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center space-x-4">
          <h1 className="text-2xl font-bold text-white flex items-center">
            <Star className="mr-2 h-6 w-6 text-yellow-500" />
            {t('nav.trenches')}
          </h1>
          <Button
            variant="ghost"
            size="sm"
            className="text-gray-400 hover:text-white"
            onMouseEnter={playHover}
            onClick={playClick}
          >
            <Filter className="mr-2 h-4 w-4" />
            {t('buttons.filter')}
          </Button>
          <Button
            variant="ghost"
            size="sm"
            className="text-gray-400 hover:text-white"
            onMouseEnter={playHover}
            onClick={playClick}
          >
            <Eye className="mr-2 h-4 w-4" />
            {t('buttons.customize')}
          </Button>
        </div>

        <div className="text-sm text-gray-400">
          SOL Chain
        </div>
      </div>

      {/* Token Table */}
      <div className="bg-gray-900 rounded-lg overflow-hidden">
        {/* Table Header */}
        <div className="grid grid-cols-7 gap-4 p-4 bg-gray-800 text-gray-300 text-sm font-medium">
          <div>{t('table.token')}</div>
          <div>{t('table.price')}</div>
          <div>{t('table.change')}</div>
          <div>{t('table.volume')}</div>
          <div>{t('table.marketCap')}</div>
          <div>{t('table.holders')}</div>
          <div>Actions</div>
        </div>

        {/* Token Rows */}
        {mockTokens.map((token, index) => (
          <div
            key={index}
            className="grid grid-cols-7 gap-4 p-4 border-b border-gray-800 hover:bg-gray-800 transition-colors cursor-pointer"
            onMouseEnter={playHover}
            onClick={playClick}
          >
            {/* Token */}
            <div className="flex items-center space-x-3">
              <div className="w-8 h-8 rounded-full bg-gray-700 flex items-center justify-center text-sm">
                {token.image}
              </div>
              <div>
                <div className="text-white font-medium">{token.symbol}</div>
                <div className="text-gray-400 text-sm">{token.name}</div>
              </div>
            </div>

            {/* Price */}
            <div className="text-white font-mono">{token.price}</div>

            {/* Change */}
            <div className={`flex items-center ${token.change >= 0 ? 'text-green-400' : 'text-red-400'}`}>
              {token.change >= 0 ? (
                <TrendingUp className="mr-1 h-4 w-4" />
              ) : (
                <TrendingDown className="mr-1 h-4 w-4" />
              )}
              {Math.abs(token.change)}%
            </div>

            {/* Volume */}
            <div className="text-gray-300 font-mono">{token.volume}</div>

            {/* Market Cap */}
            <div className="text-gray-300 font-mono">{token.marketCap}</div>

            {/* Holders */}
            <div className="text-gray-300">{token.holders}</div>

            {/* Actions */}
            <div className="flex space-x-2">
              <Button
                size="sm"
                className="bg-green-600 hover:bg-green-700 text-white text-xs"
                onMouseEnter={playHover}
                onClick={(e) => {
                  e.stopPropagation();
                  playClick();
                }}
              >
                Buy
              </Button>
              <Button
                size="sm"
                variant="outline"
                className="border-gray-600 text-gray-300 hover:text-white hover:bg-gray-700 text-xs"
                onMouseEnter={playHover}
                onClick={(e) => {
                  e.stopPropagation();
                  playClick();
                }}
              >
                Track
              </Button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
