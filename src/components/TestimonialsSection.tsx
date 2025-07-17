'use client';

import { useTranslations } from 'next-intl';
import { Button } from '@/components/ui/button';
import { Star, MessageSquare, ExternalLink } from 'lucide-react';

export default function TestimonialsSection() {
  const t = useTranslations();

  const testimonials = [
    {
      name: "Meraki Crypto",
      handle: "@merakicrypto_",
      avatar: "🚀",
      content: "Gmgn is pretty dope, speed is key to get quick entries. Doing my challenge wallet using it So far I've turned $100 -> $13k",
      link: "https://x.com/merakicrypto_",
      verified: true
    },
    {
      name: "Dior",
      handle: "@Dior100x",
      avatar: "💎",
      content: "I found a trading bot (GMGN.AI) it has meme discovering, tracking & TG bot trading ALL IN ONE platform (I've been using for a while) - Trading bot - Great UI - quick processing",
      link: "https://x.com/Dior100x",
      verified: true
    },
    {
      name: "Sibel",
      handle: "@sibeleth",
      avatar: "⭐",
      content: "How do you make money? For sure by using a fast, safe and easy TG trading bot! I am thrilled to announce that I have partnered with @gmgnai",
      link: "https://x.com/sibeleth",
      verified: true
    }
  ];

  return (
    <section className="py-20 px-4 bg-gradient-to-b from-[#0c0e0e] to-gray-900">
      <div className="max-w-6xl mx-auto">
        {/* Section header */}
        <div className="text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">
            {t('testimonials.title')}
          </h2>
          <p className="text-gray-400 text-xl max-w-2xl mx-auto">
            {t('testimonials.subtitle')}
          </p>
        </div>

        {/* Testimonials grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 mb-16">
          {testimonials.map((testimonial, index) => (
            <div
              key={index}
              className="bg-gray-800 rounded-2xl p-6 border border-gray-700 hover:border-[#beeb26] transition-all duration-300 transform hover:scale-105 cursor-pointer"
            >
              {/* User info */}
              <div className="flex items-center space-x-3 mb-4">
                <div className="w-12 h-12 bg-gradient-to-br from-[#beeb26] to-green-500 rounded-full flex items-center justify-center text-xl">
                  {testimonial.avatar}
                </div>
                <div className="flex-1">
                  <div className="flex items-center space-x-2">
                    <h4 className="text-white font-semibold">{testimonial.name}</h4>
                    {testimonial.verified && (
                      <div className="w-4 h-4 bg-blue-500 rounded-full flex items-center justify-center">
                        <span className="text-white text-xs">✓</span>
                      </div>
                    )}
                  </div>
                  <p className="text-gray-400 text-sm">{testimonial.handle}</p>
                </div>
                <ExternalLink className="h-4 w-4 text-gray-400" />
              </div>

              {/* Rating */}
              <div className="flex items-center space-x-1 mb-3">
                {[...Array(5)].map((_, i) => (
                  <Star key={i} className="h-4 w-4 fill-[#beeb26] text-[#beeb26]" />
                ))}
              </div>

              {/* Content */}
              <p className="text-gray-300 leading-relaxed mb-4">
                "{testimonial.content}"
              </p>

              {/* Link */}
              <Button
                variant="ghost"
                size="sm"
                className="text-[#beeb26] hover:text-white hover:bg-gray-700 p-0 h-auto"
                onClick={(e) => {
                  e.stopPropagation();
                  window.open(testimonial.link, '_blank');
                }}
              >
                <MessageSquare className="mr-2 h-4 w-4" />
                {t('testimonials.viewTweet')}
              </Button>
            </div>
          ))}
        </div>

        {/* Download CTA */}
        <div className="text-center">
          <div className="bg-gradient-to-r from-[#beeb26] to-green-500 rounded-3xl p-12 text-black">
            <h3 className="text-3xl font-bold mb-4">
              {t('testimonials.joinCommunity')}
            </h3>
            <p className="text-lg mb-8 opacity-80">
              {t('testimonials.joinCommunityDesc')}
            </p>

            <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
              <Button
                className="bg-black hover:bg-gray-800 text-white font-semibold px-8 py-4 rounded-xl transition-all duration-300"
              >
                📱 {t('buttons.downloadFromAppStore')}
              </Button>

              <Button
                variant="outline"
                className="border-black text-black hover:bg-black hover:text-white font-semibold px-8 py-4 rounded-xl transition-all duration-300"
              >
                📱 {t('buttons.telegramGroup')}
              </Button>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
