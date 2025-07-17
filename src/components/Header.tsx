'use client';

import { useState } from 'react';
import { Search, Download, Settings, Globe, Volume2, VolumeX } from 'lucide-react';
import { Button } from '@/components/ui/button';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';

export default function Header() {
  const [soundEnabled, setSoundEnabled] = useState(true);
  const [currentLocale, setCurrentLocale] = useState('zh');

  const toggleSound = () => {
    setSoundEnabled(!soundEnabled);
  };

  const toggleLanguage = () => {
    const newLocale = currentLocale === 'zh' ? 'en' : 'zh';
    setCurrentLocale(newLocale);
  };

  return (
    <header className="bg-[#0c0e0e] border-b border-gray-800 sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-4 py-3">
        <div className="flex items-center justify-between">
          {/* Logo */}
          <div className="flex items-center space-x-6">
            <div className="flex items-center space-x-2">
              <div className="w-8 h-8 bg-[#beeb26] rounded-lg flex items-center justify-center">
                <span className="text-black font-bold text-lg">G</span>
              </div>
              <span className="text-white font-bold text-xl">GMGN</span>
              <span className="text-gray-400 text-sm">战绩</span>
            </div>

            {/* Navigation */}
            <nav className="hidden md:flex items-center space-x-6">
              <a href="#" className="text-gray-300 hover:text-white transition-colors">
                新配对
              </a>
              <a href="#" className="text-gray-300 hover:text-white transition-colors">
                热门
              </a>
              <a href="#" className="text-gray-300 hover:text-white transition-colors">
                X概念
              </a>
            </nav>
          </div>

          {/* Right side */}
          <div className="flex items-center space-x-4">
            {/* Search */}
            <div className="relative hidden md:block">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
              <input
                type="text"
                placeholder="搜索代币..."
                className="bg-gray-800 border border-gray-700 rounded-lg pl-10 pr-4 py-2 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#beeb26] w-64"
              />
            </div>

            {/* Download Button */}
            <Button
              className="bg-[#beeb26] text-black hover:bg-[#a5d423] font-semibold"
            >
              <Download className="h-4 w-4 mr-2" />
              下载应用
            </Button>

            {/* Stats */}
            <div className="hidden lg:flex items-center space-x-4 text-sm">
              <div className="flex items-center space-x-2">
                <span className="text-[#beeb26]">盈利</span>
                <span className="text-white">0 Fees</span>
              </div>
            </div>

            {/* Settings */}
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="sm" className="text-gray-400 hover:text-white">
                  <Settings className="h-4 w-4" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent className="bg-gray-800 border-gray-700">
                <DropdownMenuItem onClick={toggleSound} className="text-white hover:bg-gray-700">
                  {soundEnabled ? (
                    <>
                      <Volume2 className="h-4 w-4 mr-2" />
                      关闭声音
                    </>
                  ) : (
                    <>
                      <VolumeX className="h-4 w-4 mr-2" />
                      开启声音
                    </>
                  )}
                </DropdownMenuItem>
                <DropdownMenuItem onClick={toggleLanguage} className="text-white hover:bg-gray-700">
                  <Globe className="h-4 w-4 mr-2" />
                  {currentLocale === 'zh' ? 'English' : '中文'}
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>

            {/* Auth Buttons */}
            <div className="flex items-center space-x-2">
              <Button variant="outline" size="sm" className="border-gray-600 text-gray-300 hover:text-white">
                注册
              </Button>
              <Button variant="outline" size="sm" className="border-gray-600 text-gray-300 hover:text-white">
                登录
              </Button>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
}
