import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import ClientBody from "./ClientBody";
import Script from "next/script";
import { SoundProvider } from '@/context/SoundContext';
import { LanguageProvider } from '@/context/LanguageContext';

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "GMGN.AI - 快速交易，快速跟单，快速AFK自动化",
  description: "GMGN 跟随聪明资金和KOL，发现未来热门资产，让GMGN带你先行一步！跟踪未实现/已实现利润，发现聪明交易者，实时监控钱包动态。",
  icons: {
    icon: '/gmgn-logo.png',
    shortcut: '/gmgn-logo.png',
    apple: '/gmgn-logo.png',
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {

  return (
    <html lang="zh" className={`${geistSans.variable} ${geistMono.variable} dark`}>
      <head>
        <Script
          crossOrigin="anonymous"
          src="//unpkg.com/same-runtime/dist/index.global.js"
        />
      </head>
      <body suppressHydrationWarning className="antialiased bg-[#0c0e0e] text-white">
        <SoundProvider>
          <LanguageProvider>
            <ClientBody>{children}</ClientBody>
          </LanguageProvider>
        </SoundProvider>
      </body>
    </html>
  );
}
