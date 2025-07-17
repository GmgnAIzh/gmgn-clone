'use client';

import { useEffect } from 'react';
import { useSound } from '@/context/SoundContext';

export default function SoundEffects() {
  const { enabled } = useSound();

  useEffect(() => {
    // 页面加载时播放欢迎音效
    if (enabled) {
      const playWelcomeSound = () => {
        const context = new (window.AudioContext || (window as typeof window & { webkitAudioContext: typeof AudioContext }).webkitAudioContext)();
        const oscillator = context.createOscillator();
        const gainNode = context.createGain();

        oscillator.connect(gainNode);
        gainNode.connect(context.destination);

        oscillator.frequency.value = 600;
        oscillator.type = 'sine';

        gainNode.gain.setValueAtTime(0.1, context.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.01, context.currentTime + 0.3);

        oscillator.start(context.currentTime);
        oscillator.stop(context.currentTime + 0.3);
      };

      // 延迟播放欢迎音效
      const timer = setTimeout(playWelcomeSound, 500);
      return () => clearTimeout(timer);
    }
  }, [enabled]);

  return null;
}
