'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import { soundManager } from '@/lib/sound';

interface SoundContextType {
  enabled: boolean;
  toggle: () => void;
  playClick: () => void;
  playHover: () => void;
  playSuccess: () => void;
  playError: () => void;
}

const SoundContext = createContext<SoundContextType | undefined>(undefined);

export function SoundProvider({ children }: { children: React.ReactNode }) {
  const [enabled, setEnabled] = useState(true);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    const saved = localStorage.getItem('sound-enabled');
    if (saved !== null) {
      setEnabled(JSON.parse(saved));
    }
  }, []);

  useEffect(() => {
    if (!mounted) return;
    localStorage.setItem('sound-enabled', JSON.stringify(enabled));
    soundManager?.setEnabled(enabled);
  }, [enabled, mounted]);

  const toggle = () => setEnabled(!enabled);

  const playClick = () => soundManager?.click();
  const playHover = () => soundManager?.hover();
  const playSuccess = () => soundManager?.success();
  const playError = () => soundManager?.error();

  return (
    <SoundContext.Provider
      value={{
        enabled,
        toggle,
        playClick,
        playHover,
        playSuccess,
        playError,
      }}
    >
      {children}
    </SoundContext.Provider>
  );
}

export function useSound() {
  const context = useContext(SoundContext);
  if (context === undefined) {
    throw new Error('useSound must be used within a SoundProvider');
  }
  return context;
}
