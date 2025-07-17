'use client';

import { useEffect, useState } from 'react';
import { cryptoAPI, CryptoPair } from '@/lib/cryptoAPI';
import { TrendingUp, TrendingDown } from 'lucide-react';

export default function CryptoGrid() {
  const [cryptoList, setCryptoList] = useState<CryptoPair[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    const loadCryptoData = async () => {
      try {
        const data = await cryptoAPI.getTopCryptos(12);
        setCryptoList(data);
      } catch (error) {
        console.error('Failed to load crypto data:', error);
      } finally {
        setIsLoading(false);
      }
    };

    loadCryptoData();

    // 每30秒更新一次数据
    const interval = setInterval(loadCryptoData, 30000);
    return () => clearInterval(interval);
  }, []);

  const formatPrice = (price: number): string => {
    if (price >= 1) {
      return `$${price.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
    } else {
      return `$${price.toFixed(6)}`;
    }
  };

  const formatMarketCap = (marketCap: number): string => {
    if (marketCap >= 1e12) {
      return `$${(marketCap / 1e12).toFixed(2)}T`;
    } else if (marketCap >= 1e9) {
      return `$${(marketCap / 1e9).toFixed(2)}B`;
    } else if (marketCap >= 1e6) {
      return `$${(marketCap / 1e6).toFixed(2)}M`;
    } else {
      return `$${marketCap.toFixed(0)}`;
    }
  };

  const formatVolume = (volume: number): string => {
    if (volume >= 1e9) {
      return `$${(volume / 1e9).toFixed(2)}B`;
    } else if (volume >= 1e6) {
      return `$${(volume / 1e6).toFixed(2)}M`;
    } else if (volume >= 1e3) {
      return `$${(volume / 1e3).toFixed(2)}K`;
    } else {
      return `$${volume.toFixed(0)}`;
    }
  };

  // Don't render until mounted to prevent hydration mismatch
  if (!mounted || isLoading) {
    return (
      <section className="py-20 px-4">
        <div className="max-w-6xl mx-auto">
          <h2 className="text-3xl font-bold text-white text-center mb-12">
            {mounted ? '载入中...' : '载入中...'}
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {[...Array(12)].map((_, i) => (
              <div key={i} className="bg-gray-800 rounded-lg p-4 animate-pulse">
                <div className="h-6 bg-gray-600 rounded mb-2"></div>
                <div className="h-4 bg-gray-600 rounded mb-2"></div>
                <div className="h-4 bg-gray-600 rounded"></div>
              </div>
            ))}
          </div>
        </div>
      </section>
    );
  }

  return (
    <section className="py-20 px-4 bg-gradient-to-b from-[#0c0e0e] to-gray-900">
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-12">
          <h2 className="text-3xl md:text-4xl font-bold text-white mb-4">
            热门加密货币实时价格
          </h2>
          <p className="text-gray-400 text-lg">
            追踪热门加密货币的实时价格变化和市场数据
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {cryptoList.map((crypto) => {
            const isPositive = crypto.price_change_percentage_24h >= 0;

            return (
              <div
                key={crypto.id}
                className="bg-gray-800 rounded-lg p-4 border border-gray-700 hover:border-[#beeb26] transition-all duration-300 cursor-pointer transform hover:scale-105"
              >
                {/* 币种名称和符号 */}
                <div className="flex items-center justify-between mb-3">
                  <div>
                    <h3 className="text-white font-bold text-lg">{crypto.symbol}</h3>
                    <p className="text-gray-400 text-sm">{crypto.name}</p>
                  </div>
                  <div className={`p-2 rounded-full ${isPositive ? 'bg-green-500' : 'bg-red-500'}`}>
                    {isPositive ? (
                      <TrendingUp className="h-4 w-4 text-white" />
                    ) : (
                      <TrendingDown className="h-4 w-4 text-white" />
                    )}
                  </div>
                </div>

                {/* 价格 */}
                <div className="mb-3">
                  <div className="text-white text-xl font-bold">
                    {formatPrice(crypto.current_price)}
                  </div>
                  <div className={`text-sm font-medium ${isPositive ? 'text-green-400' : 'text-red-400'}`}>
                    {isPositive ? '+' : ''}{crypto.price_change_percentage_24h.toFixed(2)}%
                  </div>
                </div>

                {/* 市值和成交量 */}
                <div className="space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-400">市值:</span>
                    <span className="text-white">{formatMarketCap(crypto.market_cap)}</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-400">24h成交量:</span>
                    <span className="text-white">{formatVolume(crypto.total_volume)}</span>
                  </div>
                </div>

                {/* 价格变化指示器 */}
                <div className="mt-3">
                  <div className="h-1 bg-gray-600 rounded-full overflow-hidden">
                    <div
                      className={`h-full transition-all duration-500 ${isPositive ? 'bg-green-500' : 'bg-red-500'}`}
                      style={{
                        width: `${Math.min(Math.abs(crypto.price_change_percentage_24h) * 10, 100)}%`
                      }}
                    ></div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        {/* 免责声明 */}
        <div className="mt-12 text-center">
          <p className="text-gray-500 text-sm">
            * 价格数据来源于CoinGecko API，仅供参考，投资需谨慎
          </p>
        </div>
      </div>
    </section>
  );
}
