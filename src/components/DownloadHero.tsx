'use client';

import { useTranslations } from 'next-intl';
import { Button } from '@/components/ui/button';
import { Download, Apple, Monitor } from 'lucide-react';
import SimpleChart from '@/components/SimpleChart';

export default function DownloadHero() {
  const t = useTranslations();

  const handleDownload = () => {
    // 在实际项目中，这里会是真实的下载链接
    window.open('#', '_blank');
  };

  return (
    <section className="relative min-h-[80vh] flex items-center justify-center px-4 py-16">
      {/* Background grid pattern */}
      <div className="absolute inset-0 opacity-10" style={{
        backgroundImage: "url(\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='60' height='60' viewBox='0 0 60 60'%3E%3Crect width='1' height='1' fill='%23333'/%3E%3C/svg%3E\")"
      }}></div>

      <div className="relative z-10 max-w-6xl mx-auto text-center">
        {/* Main headline */}
        <div className="mb-12">
          <h1 className="text-5xl md:text-7xl font-bold mb-6">
            <span className="text-[#beeb26]">{t('hero.discoverFaster')}</span>
            <br />
            <span className="text-white">{t('hero.tradingInSeconds')}</span>
          </h1>

          <p className="text-gray-400 text-lg md:text-xl max-w-2xl mx-auto mb-12">
            {t('hero.description')}
          </p>
        </div>

        {/* Download button */}
        <div className="mb-16">
          <Button
            onClick={handleDownload}
            className="bg-[#beeb26] hover:bg-[#a5d423] text-black font-bold text-lg px-12 py-6 rounded-2xl transition-all duration-300 transform hover:scale-105 shadow-lg hover:shadow-xl"
          >
            <Apple className="mr-3 h-6 w-6" />
            {t('buttons.downloadFromAppStore')}
          </Button>
        </div>

        {/* Desktop mockup */}
        <div className="flex justify-center items-center">
          {/* Desktop browser window - shows trading interface */}
          <div className="relative">
            <div className="w-[800px] h-[500px] bg-gray-900 rounded-lg border border-gray-700 shadow-2xl">
              {/* Browser header */}
              <div className="h-8 bg-gray-800 rounded-t-lg flex items-center px-4 border-b border-gray-700">
                <div className="flex space-x-2">
                  <div className="w-3 h-3 bg-red-500 rounded-full"></div>
                  <div className="w-3 h-3 bg-yellow-500 rounded-full"></div>
                  <div className="w-3 h-3 bg-green-500 rounded-full"></div>
                </div>
                <div className="flex-1 mx-4">
                  <div className="bg-gray-700 rounded text-xs text-gray-300 px-3 py-1 text-center max-w-md mx-auto">
                    🌐 gmgn.ai - GMGN Trading Platform
                  </div>
                </div>
              </div>

              {/* Desktop screen content */}
              <div className="w-full h-[calc(100%-2rem)] bg-black p-6 overflow-hidden">
                <div className="grid grid-cols-3 gap-6 h-full">
                  {/* Left side - Interactive Trading chart */}
                  <div className="col-span-2">
                    <div className="text-[#beeb26] text-sm font-semibold mb-2">{t('trading.dashboard')}</div>
                    <SimpleChart width={520} height={320} />
                  </div>

                  {/* Right side - Live activities */}
                  <div className="space-y-3 col-span-1">
                    <div className="text-white text-sm font-semibold mb-3">{t('trading.liveActivity')}</div>

                    {/* Trade notifications */}
                    <div className="space-y-3">
                      {[
                        { name: t('trading.profitMaster'), action: t('trading.buyEth'), amount: "+$2.4k", positive: true, time: "2m ago" },
                        { name: t('trading.capitalGuru'), action: t('trading.sellSolana'), amount: "-$1.2k", positive: false, time: "5m ago" },
                        { name: t('trading.investmentKing'), action: t('trading.buyCardano'), amount: "+$890", positive: true, time: "8m ago" },
                        { name: t('trading.smartTrader'), action: t('trading.buyPolygon'), amount: "+$1.5k", positive: true, time: "12m ago" },
                        { name: t('trading.cryptoExpert'), action: t('trading.sellDogecoin'), amount: "-$750", positive: false, time: "15m ago" },
                      ].map((trade, index) => (
                        <div key={index} className="bg-gray-800 rounded-lg p-3 flex items-center justify-between hover:bg-gray-700 transition-colors">
                          <div className="flex items-center space-x-3">
                            <div className={`w-8 h-8 rounded-full flex items-center justify-center ${trade.positive ? 'bg-green-500' : 'bg-red-500'}`}>
                              {trade.positive ? '📈' : '📉'}
                            </div>
                            <div>
                              <div className="text-white text-sm font-medium">{trade.name}</div>
                              <div className="text-gray-400 text-xs">{trade.action}</div>
                            </div>
                          </div>
                          <div className="text-right">
                            <div className={`text-sm font-bold ${trade.positive ? 'text-green-400' : 'text-red-400'}`}>
                              {trade.amount}
                            </div>
                            <div className="text-gray-500 text-xs">{trade.time}</div>
                          </div>
                        </div>
                      ))}
                    </div>

                    {/* Bottom stats */}
                    <div className="mt-4 grid grid-cols-2 gap-3">
                      <div className="bg-gray-800 rounded-lg p-3 text-center">
                        <div className="text-[#beeb26] text-lg font-bold">2,847</div>
                        <div className="text-gray-400 text-xs">{t('trading.activeTraders')}</div>
                      </div>
                      <div className="bg-gray-800 rounded-lg p-3 text-center">
                        <div className="text-[#beeb26] text-lg font-bold">$45.2M</div>
                        <div className="text-gray-400 text-xs">{t('trading.volume24h')}</div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Quick features */}
        <div className="mt-16 grid grid-cols-1 md:grid-cols-3 gap-8 max-w-4xl mx-auto">
          <div className="text-center">
            <div className="w-12 h-12 bg-[#beeb26] rounded-full flex items-center justify-center mx-auto mb-4">
              <Monitor className="h-6 w-6 text-black" />
            </div>
            <h3 className="text-white font-semibold mb-2">{t('quickFeatures.realTimeAlerts')}</h3>
            <p className="text-gray-400 text-sm">{t('quickFeatures.realTimeAlertsDesc')}</p>
          </div>

          <div className="text-center">
            <div className="w-12 h-12 bg-[#beeb26] rounded-full flex items-center justify-center mx-auto mb-4">
              <Download className="h-6 w-6 text-black" />
            </div>
            <h3 className="text-white font-semibold mb-2">{t('quickFeatures.instantTrading')}</h3>
            <p className="text-gray-400 text-sm">{t('quickFeatures.instantTradingDesc')}</p>
          </div>

          <div className="text-center">
            <div className="w-12 h-12 bg-[#beeb26] rounded-full flex items-center justify-center mx-auto mb-4">
              <Apple className="h-6 w-6 text-black" />
            </div>
            <h3 className="text-white font-semibold mb-2">{t('quickFeatures.smartMoney')}</h3>
            <p className="text-gray-400 text-sm">{t('quickFeatures.smartMoneyDesc')}</p>
          </div>
        </div>
      </div>
    </section>
  );
}
