module.exports = {
  apps: [
    {
      name: 'gmgn-app',
      script: 'node_modules/next/dist/bin/next',
      args: 'start -H 0.0.0.0 -p 3000',
      cwd: '/home/project/gmgn-clone',
      instances: 'max', // 使用所有CPU核心
      exec_mode: 'cluster', // 集群模式提高性能
      env: {
        NODE_ENV: 'production',
        PORT: 3000,
        HOSTNAME: '0.0.0.0'
      },
      // 自动重启配置
      autorestart: true,
      watch: false, // 生产环境不监听文件变化
      max_memory_restart: '1G',

      // 错误和日志管理
      error_file: '/var/log/pm2/gmgn-error.log',
      out_file: '/var/log/pm2/gmgn-out.log',
      log_file: '/var/log/pm2/gmgn-combined.log',
      time: true,

      // 健康检查
      min_uptime: '10s',
      max_restarts: 10,

      // 优雅关闭
      kill_timeout: 5000,
      wait_ready: true,
      listen_timeout: 8000,

      // 环境变量
      env_production: {
        NODE_ENV: 'production',
        PORT: 3000,
        HOSTNAME: '0.0.0.0',
        // API配置
        NEXT_PUBLIC_API_URL: 'https://api.coingecko.com/api/v3',
        // 其他生产环境变量
        NEXT_TELEMETRY_DISABLED: 1
      }
    }
  ],

  // 部署配置
  deploy: {
    production: {
      user: 'root',
      host: 'localhost',
      ref: 'origin/main',
      repo: 'local',
      path: '/home/project',
      'pre-deploy-local': '',
      'post-deploy': 'bun install && bun run build && pm2 reload ecosystem.config.js --env production',
      'pre-setup': ''
    }
  }
};
