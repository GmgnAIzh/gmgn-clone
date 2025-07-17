export class SoundManager {
  private enabled: boolean = true;
  private context: AudioContext | null = null;

  constructor() {
    if (typeof window !== 'undefined') {
      this.context = new (window.AudioContext || (window as typeof window & { webkitAudioContext: typeof AudioContext }).webkitAudioContext)();
    }
  }

  setEnabled(enabled: boolean) {
    this.enabled = enabled;
  }

  isEnabled() {
    return this.enabled;
  }

  private createTone(frequency: number, duration: number, type: OscillatorType = 'sine') {
    if (!this.enabled || !this.context) return;

    const oscillator = this.context.createOscillator();
    const gainNode = this.context.createGain();

    oscillator.connect(gainNode);
    gainNode.connect(this.context.destination);

    oscillator.frequency.value = frequency;
    oscillator.type = type;

    gainNode.gain.setValueAtTime(0.1, this.context.currentTime);
    gainNode.gain.exponentialRampToValueAtTime(0.01, this.context.currentTime + duration);

    oscillator.start(this.context.currentTime);
    oscillator.stop(this.context.currentTime + duration);
  }

  click() {
    this.createTone(800, 0.1, 'square');
  }

  hover() {
    this.createTone(600, 0.05, 'sine');
  }

  success() {
    this.createTone(1000, 0.2, 'sine');
    setTimeout(() => this.createTone(1200, 0.15, 'sine'), 100);
  }

  error() {
    this.createTone(300, 0.3, 'sawtooth');
  }
}

export const soundManager = typeof window !== 'undefined' ? new SoundManager() : null;
