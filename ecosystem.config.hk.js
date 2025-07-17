module.exports = {
  apps: [
    {
      name: 'gmgn-app',
      script: 'node_modules/next/dist/bin/next',
      args: 'start -H 0.0.0.0 -p 3000',
      cwd: '/home/project/gmgn-clone',
      instances: 3, // 4核CPU使用3个实例，保留1核给系统
      exec_mode: 'cluster',

      // 环境变量
      env: {
        NODE_ENV: 'production',
        PORT: 3000,
        HOSTNAME: '0.0.0.0',
        NODE_OPTIONS: '--max-old-space-size=1536', // 1.5GB堆内存
        TZ: 'Asia/Hong_Kong' // 香港时区
      },

      // 内存和重启配置
      autorestart: true,
      watch: false,
      max_memory_restart: '1536M', // 1.5GB内存限制
      restart_delay: 4000, // 重启延迟4秒

      // 日志配置
      error_file: '/var/log/pm2/gmgn-error.log',
      out_file: '/var/log/pm2/gmgn-out.log',
      log_file: '/var/log/pm2/gmgn-combined.log',
      time: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',

      // 健康检查配置 - 适合香港网络延迟
      min_uptime: '15s', // 最小运行时间15秒
      max_restarts: 5, // 减少最大重启次数

      // 优雅关闭配置
      kill_timeout: 8000, // 增加kill超时
      wait_ready: true,
      listen_timeout: 10000, // 增加监听超时

      // 生产环境变量
      env_production: {
        NODE_ENV: 'production',
        PORT: 3000,
        HOSTNAME: '0.0.0.0',
        NODE_OPTIONS: '--max-old-space-size=1536',
        TZ: 'Asia/Hong_Kong',

        // API配置
        NEXT_PUBLIC_API_URL: 'https://api.coingecko.com/api/v3',
        NEXT_PUBLIC_API_TIMEOUT: 15000, // 增加API超时

        // 香港地域优化
        NEXT_PUBLIC_REGION: 'HK',
        NEXT_PUBLIC_CDN_URL: 'https://cdn.hongkong.com',

        // 性能优化
        NEXT_TELEMETRY_DISABLED: 1,
        UV_THREADPOOL_SIZE: 8, // 线程池大小

        // 带宽优化
        COMPRESS_RESPONSE: 1,
        ENABLE_CACHE: 1
      },

      // 进程监控
      monitoring: {
        http: true,
        https: false,
        port: 3000
      }
    }
  ],

  // 部署配置
  deploy: {
    production: {
      user: 'root',
      host: '45.194.37.150',
      port: 22,
      ref: 'origin/main',
      repo: 'local',
      path: '/home/project',
      'pre-deploy-local': '',
      'post-deploy': 'npm install && npm run build && pm2 reload ecosystem.config.hk.js --env production',
      'pre-setup': '',
      env: {
        NODE_ENV: 'production',
        TZ: 'Asia/Hong_Kong'
      }
    }
  }
};
