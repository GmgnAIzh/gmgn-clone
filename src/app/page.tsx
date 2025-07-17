import dynamic from 'next/dynamic';
import Header from '@/components/Header';
import DownloadHero from '@/components/DownloadHero';
import CryptoGrid from '@/components/CryptoGrid';
import SimpleChart from '@/components/SimpleChart';
import FeaturesSection from '@/components/FeaturesSection';
import TestimonialsSection from '@/components/TestimonialsSection';
import TokenList from '@/components/TokenList';
import BottomBar from '@/components/BottomBar';

const SoundEffects = dynamic(() => import('@/components/SoundEffects'), { ssr: false });

export default function Home() {
  return (
    <div className="min-h-screen bg-[#0c0e0e] text-white">
      {/* Sound Effects */}
      <SoundEffects />
      {/* Header */}
      <Header />
      {/* Main Content */}
      <main className="flex-1">
        {/* Hero Section */}
        <DownloadHero />
        {/* Real-time Crypto Prices */}
        <CryptoGrid />
        {/* Interactive Chart Section */}
        <section className="py-20 px-4 bg-gradient-to-b from-gray-900 to-[#0c0e0e]">
          <div className="max-w-6xl mx-auto">
            <div className="text-center mb-12">
              <h2 className="text-3xl md:text-4xl font-bold text-white mb-4">
                实时交易图表
              </h2>
              <p className="text-gray-400 text-lg">
                专业级交易图表，实时数据更新，支持多种技术指标
              </p>
            </div>
            <div className="bg-gray-800 rounded-2xl p-6 border border-gray-700">
              <SimpleChart />
            </div>
          </div>
        </section>
        {/* Token List Section */}
        <section className="py-20 px-4">
          <div className="max-w-6xl mx-auto">
            <div className="text-center mb-12">
              <h2 className="text-3xl md:text-4xl font-bold text-white mb-4">
                热门代币追踪
              </h2>
              <p className="text-gray-400 text-lg">
                实时追踪热门代币，发现下一个潜力项目
              </p>
            </div>
            <TokenList />
          </div>
        </section>
        {/* Features Section */}
        <FeaturesSection />
        {/* Testimonials */}
        <TestimonialsSection />
        {/* Final CTA */}
        <section className="py-20 px-4">
          <div className="max-w-4xl mx-auto text-center">
            <div className="bg-gradient-to-r from-[#beeb26] to-[#a5d423] rounded-2xl p-12">
              <h2 className="text-3xl font-bold text-black mb-4">
                立即加入GMGN社区！
              </h2>
              <p className="text-black/80 text-lg mb-6">
                下载应用，开始使用实时洞察进行更智能的交易
              </p>
              <div className="flex justify-center space-x-4">
                <button className="bg-black text-white px-6 py-3 rounded-lg font-semibold hover:bg-gray-800 transition-colors">
                  📱 从App Store下载
                </button>
                <button className="bg-black text-white px-6 py-3 rounded-lg font-semibold hover:bg-gray-800 transition-colors">
                  🤖 Android下载
                </button>
              </div>
            </div>
          </div>
        </section>
      </main>
      {/* Bottom Navigation */}
      <BottomBar />
      {/* Footer */}
      <footer className="bg-[#0c0e0e] border-t border-gray-800 py-12">
        <div className="max-w-7xl mx-auto px-4">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
            <div>
              <div className="flex items-center space-x-2 mb-4">
                <div className="w-8 h-8 bg-[#beeb26] rounded-lg flex items-center justify-center">
                  <span className="text-black font-bold text-lg">G</span>
                </div>
                <span className="text-white font-bold text-xl">GMGN</span>
              </div>
              <p className="text-gray-400 text-sm">
                跟踪聪明资金和KOL，发现未来热门资产，让GMGN带你先行一步！
              </p>
            </div>
            <div>
              <h3 className="text-white font-semibold mb-4">产品</h3>
              <ul className="space-y-2 text-gray-400 text-sm">
                <li><a href="#" className="hover:text-white transition-colors">移动应用</a></li>
                <li><a href="#" className="hover:text-white transition-colors">Web平台</a></li>
                <li><a href="#" className="hover:text-white transition-colors">API接口</a></li>
                <li><a href="#" className="hover:text-white transition-colors">开发者工具</a></li>
              </ul>
            </div>
            <div>
              <h3 className="text-white font-semibold mb-4">资源</h3>
              <ul className="space-y-2 text-gray-400 text-sm">
                <li><a href="#" className="hover:text-white transition-colors">使用指南</a></li>
                <li><a href="#" className="hover:text-white transition-colors">API文档</a></li>
                <li><a href="#" className="hover:text-white transition-colors">博客</a></li>
                <li><a href="#" className="hover:text-white transition-colors">社区</a></li>
              </ul>
            </div>
            <div>
              <h3 className="text-white font-semibold mb-4">联系我们</h3>
              <ul className="space-y-2 text-gray-400 text-sm">
                <li><a href="#" className="hover:text-white transition-colors">客服支持</a></li>
                <li><a href="#" className="hover:text-white transition-colors">商务合作</a></li>
                <li><a href="#" className="hover:text-white transition-colors">媒体询问</a></li>
                <li><a href="#" className="hover:text-white transition-colors">加入我们</a></li>
              </ul>
            </div>
          </div>
          <div className="border-t border-gray-800 mt-8 pt-8 flex flex-col md:flex-row justify-between items-center">
            <p className="text-gray-400 text-sm">
              © 2025 GMGN Trading Platform - 快速交易，快速跟单
            </p>
            <div className="flex space-x-6 mt-4 md:mt-0">
              <a href="#" className="text-gray-400 hover:text-white transition-colors text-sm">
                隐私政策
              </a>
              <a href="#" className="text-gray-400 hover:text-white transition-colors text-sm">
                服务条款
              </a>
              <a href="#" className="text-gray-400 hover:text-white transition-colors text-sm">
                法律声明
              </a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
