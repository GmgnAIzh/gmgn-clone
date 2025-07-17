'use client';

import { useTranslations } from 'next-intl';
import { Button } from '@/components/ui/button';
import { Bell, TrendingUp, Settings, DollarSign, Eye, Target } from 'lucide-react';
import { useSound } from '@/context/SoundContext';

export default function FeaturesSection() {
  const t = useTranslations();
  const { playClick, playHover } = useSound();

  const features = [
    {
      icon: Bell,
      title: t('features.realTimeAlerts'),
      description: t('features.realTimeAlertsDesc'),
      image: "🔔"
    },
    {
      icon: TrendingUp,
      title: t('features.realTimeTrading'),
      description: t('features.realTimeTradingDesc'),
      image: "📊"
    },
    {
      icon: Target,
      title: t('features.trackSmartMoney'),
      description: t('features.trackSmartMoneyDesc'),
      image: "🎯"
    },
    {
      icon: DollarSign,
      title: t('features.walletAnalysis'),
      description: t('features.walletAnalysisDesc'),
      image: "💰"
    }
  ];

  return (
    <section className="py-20 px-4">
      <div className="max-w-6xl mx-auto">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">
          {features.map((feature, index) => {
            const Icon = feature.icon;
            const isReverse = index % 2 === 1;

            return (
              <div
                key={index}
                className={`flex items-center space-x-8 ${isReverse ? 'lg:flex-row-reverse lg:space-x-reverse lg:space-x-8' : ''}`}
              >
                {/* Content */}
                <div className="flex-1">
                  <div className="flex items-center space-x-3 mb-6">
                    <div className="w-12 h-12 bg-[#beeb26] rounded-xl flex items-center justify-center">
                      <Icon className="h-6 w-6 text-black" />
                    </div>
                    <span className="text-2xl">{feature.image}</span>
                  </div>

                  <h3 className="text-2xl font-bold text-white mb-4">
                    {feature.title}
                  </h3>

                  <p className="text-gray-400 text-lg leading-relaxed mb-6">
                    {feature.description}
                  </p>

                  <Button
                    variant="outline"
                    className="border-[#beeb26] text-[#beeb26] hover:bg-[#beeb26] hover:text-black transition-all duration-300"
                    onMouseEnter={playHover}
                    onClick={playClick}
                  >
                    {t('features.learnMore')}
                  </Button>
                </div>

                {/* Feature illustration */}
                <div className="flex-1">
                  <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-2xl p-8 shadow-2xl">
                    <div className="w-full h-64 bg-gray-700 rounded-xl flex items-center justify-center">
                      <div className="text-center">
                        <div className="text-6xl mb-4">{feature.image}</div>
                        <div className="text-[#beeb26] font-semibold">
                          {feature.title.split(':')[0]}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        {/* Call to action */}
        <div className="text-center mt-20">
          <div className="bg-gradient-to-r from-gray-900 to-gray-800 rounded-3xl p-12 border border-gray-700">
            <h2 className="text-4xl font-bold text-white mb-6">
              {t('features.ctaTitle')}
            </h2>
            <p className="text-gray-400 text-xl mb-8 max-w-2xl mx-auto">
              {t('features.ctaDescription')}
            </p>
            <Button
              className="bg-[#beeb26] hover:bg-[#a5d423] text-black font-bold text-lg px-12 py-6 rounded-2xl transition-all duration-300 transform hover:scale-105"
              onMouseEnter={playHover}
              onClick={playClick}
            >
              <Settings className="mr-3 h-5 w-5" />
              {t('features.downloadNow')}
            </Button>
          </div>
        </div>
      </div>
    </section>
  );
}
