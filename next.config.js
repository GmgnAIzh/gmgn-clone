const createNextIntlPlugin = require('next-intl/plugin');

const withNextIntl = createNextIntlPlugin();

/** @type {import('next').NextConfig} */
const nextConfig = {
  // 简化配置以避免部署错误
  experimental: {
    // 移除可能导致问题的turbo配置
  },

  // 生产优化
  poweredByHeader: false,
  compress: true,
  generateEtags: true,

  // 图片优化
  images: {
    domains: ['api.coingecko.com', 'assets.coingecko.com'],
    unoptimized: true // 简化图片处理
  },

  // 环境变量
  env: {
    NEXT_PUBLIC_API_URL: 'https://api.coingecko.com/api/v3',
  },

  // 输出配置
  output: 'standalone',
};

module.exports = nextConfig;
