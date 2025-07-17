#!/bin/bash

# GMGN 服务器环境配置脚本
# 版本: 1.0
# 功能: 收集服务器信息并生成适配的配置文件

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 配置变量
CONFIG_FILE="server-config.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 日志函数
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示欢迎信息
show_welcome() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║               GMGN 服务器环境配置工具                         ║"
    echo "║          自动收集信息并生成适配的配置文件                       ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
    log "开始服务器环境配置..."
    echo
}

# 检测系统信息
detect_system_info() {
    log "检测系统信息..."

    # 操作系统
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_NAME=$NAME
        OS_VERSION=$VERSION_ID
    else
        OS_NAME="Unknown"
        OS_VERSION="Unknown"
    fi

    # CPU信息
    CPU_CORES=$(nproc)
    CPU_MODEL=$(lscpu | grep "Model name" | sed 's/Model name:[[:space:]]*//')

    # 内存信息
    TOTAL_MEMORY=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    AVAILABLE_MEMORY=$(free -m | awk 'NR==2{printf "%.0f", $4}')

    # 磁盘信息
    DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
    DISK_AVAILABLE=$(df -h / | awk 'NR==2 {print $4}')
    DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}')

    # 网络信息
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "Unknown")

    echo
    info "系统检测结果:"
    echo "  操作系统: $OS_NAME $OS_VERSION"
    echo "  CPU: $CPU_MODEL ($CPU_CORES 核心)"
    echo "  内存: ${TOTAL_MEMORY}MB (可用: ${AVAILABLE_MEMORY}MB)"
    echo "  磁盘: $DISK_TOTAL (可用: $DISK_AVAILABLE, 使用率: $DISK_USAGE)"
    echo "  公网IP: $PUBLIC_IP"
    echo
}

# 交互式收集配置信息
collect_config_info() {
    log "收集配置信息..."
    echo

    # 项目配置
    echo -e "${CYAN}=== 项目配置 ===${NC}"
    read -p "项目名称 [gmgn-app]: " PROJECT_NAME
    PROJECT_NAME=${PROJECT_NAME:-gmgn-app}

    read -p "部署路径 [/home/project/gmgn-clone]: " DEPLOY_PATH
    DEPLOY_PATH=${DEPLOY_PATH:-/home/project/gmgn-clone}

    read -p "运行用户 [root]: " RUN_USER
    RUN_USER=${RUN_USER:-root}

    read -p "运行端口 [3000]: " APP_PORT
    APP_PORT=${APP_PORT:-3000}

    # 域名配置
    echo
    echo -e "${CYAN}=== 域名配置 ===${NC}"
    read -p "是否使用域名? (y/n) [n]: " USE_DOMAIN
    USE_DOMAIN=${USE_DOMAIN:-n}

    if [[ $USE_DOMAIN =~ ^[Yy]$ ]]; then
        read -p "主域名: " DOMAIN_NAME
        read -p "管理员邮箱 (用于SSL证书): " ADMIN_EMAIL
        read -p "是否配置SSL? (y/n) [y]: " USE_SSL
        USE_SSL=${USE_SSL:-y}
    else
        DOMAIN_NAME="localhost"
        ADMIN_EMAIL=""
        USE_SSL="n"
    fi

    # 性能配置
    echo
    echo -e "${CYAN}=== 性能配置 ===${NC}"

    # 根据CPU核心数推荐PM2实例数
    if [ $CPU_CORES -le 2 ]; then
        RECOMMENDED_INSTANCES=1
    elif [ $CPU_CORES -le 4 ]; then
        RECOMMENDED_INSTANCES=2
    else
        RECOMMENDED_INSTANCES=$((CPU_CORES - 1))
    fi

    read -p "PM2实例数 [$RECOMMENDED_INSTANCES]: " PM2_INSTANCES
    PM2_INSTANCES=${PM2_INSTANCES:-$RECOMMENDED_INSTANCES}

    # 根据内存大小推荐Node.js堆大小
    if [ $TOTAL_MEMORY -le 2048 ]; then
        RECOMMENDED_HEAP_SIZE=1024
    elif [ $TOTAL_MEMORY -le 4096 ]; then
        RECOMMENDED_HEAP_SIZE=2048
    else
        RECOMMENDED_HEAP_SIZE=4096
    fi

    read -p "Node.js堆大小 (MB) [$RECOMMENDED_HEAP_SIZE]: " NODE_HEAP_SIZE
    NODE_HEAP_SIZE=${NODE_HEAP_SIZE:-$RECOMMENDED_HEAP_SIZE}

    # 监控配置
    echo
    echo -e "${CYAN}=== 监控配置 ===${NC}"
    read -p "健康检查间隔 (分钟) [5]: " HEALTH_CHECK_INTERVAL
    HEALTH_CHECK_INTERVAL=${HEALTH_CHECK_INTERVAL:-5}

    read -p "内存使用率告警阈值 (%) [80]: " MEMORY_THRESHOLD
    MEMORY_THRESHOLD=${MEMORY_THRESHOLD:-80}

    read -p "CPU使用率告警阈值 (%) [90]: " CPU_THRESHOLD
    CPU_THRESHOLD=${CPU_THRESHOLD:-90}

    read -p "告警邮箱: " ALERT_EMAIL

    # 备份配置
    echo
    echo -e "${CYAN}=== 备份配置 ===${NC}"
    read -p "备份保留天数 [7]: " BACKUP_RETENTION_DAYS
    BACKUP_RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-7}

    read -p "备份目录 [/home/project/backups]: " BACKUP_DIR
    BACKUP_DIR=${BACKUP_DIR:-/home/project/backups}
}

# 生成配置文件
generate_config_file() {
    log "生成配置文件..."

    cat > $CONFIG_FILE << EOF
{
    "system": {
        "os_name": "$OS_NAME",
        "os_version": "$OS_VERSION",
        "cpu_cores": $CPU_CORES,
        "cpu_model": "$CPU_MODEL",
        "total_memory": $TOTAL_MEMORY,
        "available_memory": $AVAILABLE_MEMORY,
        "disk_total": "$DISK_TOTAL",
        "disk_available": "$DISK_AVAILABLE",
        "public_ip": "$PUBLIC_IP"
    },
    "project": {
        "name": "$PROJECT_NAME",
        "deploy_path": "$DEPLOY_PATH",
        "run_user": "$RUN_USER",
        "app_port": $APP_PORT
    },
    "domain": {
        "use_domain": "$USE_DOMAIN",
        "domain_name": "$DOMAIN_NAME",
        "admin_email": "$ADMIN_EMAIL",
        "use_ssl": "$USE_SSL"
    },
    "performance": {
        "pm2_instances": $PM2_INSTANCES,
        "node_heap_size": $NODE_HEAP_SIZE
    },
    "monitoring": {
        "health_check_interval": $HEALTH_CHECK_INTERVAL,
        "memory_threshold": $MEMORY_THRESHOLD,
        "cpu_threshold": $CPU_THRESHOLD,
        "alert_email": "$ALERT_EMAIL"
    },
    "backup": {
        "retention_days": $BACKUP_RETENTION_DAYS,
        "backup_dir": "$BACKUP_DIR"
    },
    "generated_at": "$(date -Iseconds)"
}
EOF

    info "配置文件已生成: $CONFIG_FILE"
}

# 更新PM2配置
update_pm2_config() {
    log "更新PM2配置..."

    cat > ecosystem.config.js << EOF
module.exports = {
  apps: [
    {
      name: '$PROJECT_NAME',
      script: 'node_modules/next/dist/bin/next',
      args: 'start -H 0.0.0.0 -p $APP_PORT',
      cwd: '$DEPLOY_PATH',
      instances: $PM2_INSTANCES,
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'production',
        PORT: $APP_PORT,
        HOSTNAME: '0.0.0.0',
        NODE_OPTIONS: '--max-old-space-size=$NODE_HEAP_SIZE'
      },
      // 自动重启配置
      autorestart: true,
      watch: false,
      max_memory_restart: '${NODE_HEAP_SIZE}M',

      // 错误和日志管理
      error_file: '/var/log/pm2/${PROJECT_NAME}-error.log',
      out_file: '/var/log/pm2/${PROJECT_NAME}-out.log',
      log_file: '/var/log/pm2/${PROJECT_NAME}-combined.log',
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
        PORT: $APP_PORT,
        HOSTNAME: '0.0.0.0',
        NODE_OPTIONS: '--max-old-space-size=$NODE_HEAP_SIZE',
        NEXT_PUBLIC_API_URL: 'https://api.coingecko.com/api/v3',
        NEXT_TELEMETRY_DISABLED: 1
      }
    }
  ],

  // 部署配置
  deploy: {
    production: {
      user: '$RUN_USER',
      host: 'localhost',
      ref: 'origin/main',
      repo: 'local',
      path: '$DEPLOY_PATH',
      'pre-deploy-local': '',
      'post-deploy': 'bun install && bun run build && pm2 reload ecosystem.config.js --env production',
      'pre-setup': ''
    }
  }
};
EOF

    info "PM2配置已更新"
}

# 更新Nginx配置
update_nginx_config() {
    log "更新Nginx配置..."

    if [[ $USE_DOMAIN =~ ^[Yy]$ ]]; then
        # 域名配置
        cat > nginx.conf << EOF
# GMGN Nginx配置 - 域名模式
upstream ${PROJECT_NAME}_backend {
    least_conn;
    server 127.0.0.1:$APP_PORT max_fails=3 fail_timeout=30s;
    keepalive 32;
}

# HTTP重定向到HTTPS
server {
    listen 80;
    server_name $DOMAIN_NAME;
    return 301 https://\$server_name\$request_uri;
}

# HTTPS主配置
server {
    listen 443 ssl http2;
    server_name $DOMAIN_NAME;

    # SSL配置 (Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;

    # SSL安全配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;

    # 安全头
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;

    # 日志
    access_log /var/log/nginx/${PROJECT_NAME}-access.log;
    error_log /var/log/nginx/${PROJECT_NAME}-error.log;

    # 文件上传限制
    client_max_body_size 10M;

    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # 静态资源缓存
    location /_next/static/ {
        alias $DEPLOY_PATH/.next/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # 主应用代理
    location / {
        proxy_pass http://${PROJECT_NAME}_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;

        # 超时配置
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
}
EOF
    else
        # 本地配置
        cat > nginx.conf << EOF
# GMGN Nginx配置 - 本地模式
upstream ${PROJECT_NAME}_backend {
    least_conn;
    server 127.0.0.1:$APP_PORT max_fails=3 fail_timeout=30s;
    keepalive 32;
}

server {
    listen 80;
    server_name localhost;

    # 日志
    access_log /var/log/nginx/${PROJECT_NAME}-access.log;
    error_log /var/log/nginx/${PROJECT_NAME}-error.log;

    # 文件上传限制
    client_max_body_size 10M;

    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # 静态资源缓存
    location /_next/static/ {
        alias $DEPLOY_PATH/.next/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # 主应用代理
    location / {
        proxy_pass http://${PROJECT_NAME}_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
    fi

    info "Nginx配置已更新"
}

# 更新环境变量配置
update_env_config() {
    log "更新环境变量配置..."

    cat > .env.production << EOF
# 生产环境配置 - 自动生成
NODE_ENV=production
PORT=$APP_PORT
HOSTNAME=0.0.0.0

# Node.js配置
NODE_OPTIONS=--max-old-space-size=$NODE_HEAP_SIZE

# API配置
NEXT_PUBLIC_API_URL=https://api.coingecko.com/api/v3
NEXT_PUBLIC_API_TIMEOUT=10000

# 性能优化
NEXT_TELEMETRY_DISABLED=1
NEXT_SHARP=1

# 域名配置
EOF

    if [[ $USE_DOMAIN =~ ^[Yy]$ ]]; then
        echo "NEXT_PUBLIC_SITE_URL=https://$DOMAIN_NAME" >> .env.production
    else
        echo "NEXT_PUBLIC_SITE_URL=http://localhost:$APP_PORT" >> .env.production
    fi

    cat >> .env.production << EOF

# 缓存配置
CACHE_TTL=300

# 生成时间
GENERATED_AT=$(date -Iseconds)
EOF

    info "环境变量配置已更新"
}

# 更新健康检查配置
update_health_check_config() {
    log "更新健康检查配置..."

    # 更新健康检查脚本中的配置变量
    sed -i "s/APP_NAME=\"gmgn-app\"/APP_NAME=\"$PROJECT_NAME\"/" health-check.sh
    sed -i "s/HEALTH_URL=\"http:\/\/localhost:3000\"/HEALTH_URL=\"http:\/\/localhost:$APP_PORT\"/" health-check.sh
    sed -i "s/MEMORY_THRESHOLD=80/MEMORY_THRESHOLD=$MEMORY_THRESHOLD/" health-check.sh
    sed -i "s/CPU_THRESHOLD=90/CPU_THRESHOLD=$CPU_THRESHOLD/" health-check.sh

    if [[ -n "$ALERT_EMAIL" ]]; then
        sed -i "s/ALERT_EMAIL=\"admin@yourdomain.com\"/ALERT_EMAIL=\"$ALERT_EMAIL\"/" health-check.sh
    fi

    info "健康检查配置已更新"
}

# 更新部署脚本配置
update_deploy_script_config() {
    log "更新部署脚本配置..."

    # 更新部署脚本中的配置变量
    sed -i "s/APP_NAME=\"gmgn-app\"/APP_NAME=\"$PROJECT_NAME\"/" deploy-production.sh
    sed -i "s|APP_DIR=\"/home/project/gmgn-clone\"|APP_DIR=\"$DEPLOY_PATH\"|" deploy-production.sh
    sed -i "s|BACKUP_DIR=\"/home/project/backups\"|BACKUP_DIR=\"$BACKUP_DIR\"|" deploy-production.sh
    sed -i "s/HEALTH_CHECK_URL=\"http:\/\/localhost:3000\"/HEALTH_CHECK_URL=\"http:\/\/localhost:$APP_PORT\"/" deploy-production.sh

    info "部署脚本配置已更新"
}

# 生成系统服务配置
generate_systemd_service() {
    log "生成系统服务配置..."

    cat > ${PROJECT_NAME}.service << EOF
[Unit]
Description=$PROJECT_NAME - GMGN Trading Platform
Documentation=https://github.com/your-org/gmgn-clone
After=network.target
Wants=network.target

[Service]
Type=simple
User=$RUN_USER
Group=$RUN_USER
WorkingDirectory=$DEPLOY_PATH
Environment=NODE_ENV=production
Environment=PORT=$APP_PORT
Environment=HOSTNAME=0.0.0.0
Environment=NODE_OPTIONS=--max-old-space-size=$NODE_HEAP_SIZE
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.bun/bin
ExecStart=/usr/bin/node $DEPLOY_PATH/node_modules/next/dist/bin/next start -H 0.0.0.0 -p $APP_PORT
ExecReload=/bin/kill -HUP \$MAINPID
ExecStop=/bin/kill -TERM \$MAINPID
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=$PROJECT_NAME

# 资源限制
LimitNOFILE=65536
LimitNPROC=32768

# 安全配置
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=$DEPLOY_PATH
ReadWritePaths=/var/log
ReadWritePaths=/tmp

[Install]
WantedBy=multi-user.target
EOF

    info "系统服务配置已生成"
}

# 生成定时任务配置
generate_crontab_config() {
    log "生成定时任务配置..."

    cat > crontab-config << EOF
# GMGN 定时任务配置
# 使用方法: crontab crontab-config

# 健康检查 - 每${HEALTH_CHECK_INTERVAL}分钟执行一次
*/${HEALTH_CHECK_INTERVAL} * * * * $DEPLOY_PATH/health-check.sh check >> /var/log/gmgn/health.log 2>&1

# 日志清理 - 每天凌晨2点执行
0 2 * * * find /var/log/pm2 -name "*.log" -mtime +7 -delete

# 备份清理 - 每天凌晨3点执行，保留${BACKUP_RETENTION_DAYS}天
0 3 * * * find $BACKUP_DIR -name "gmgn-backup-*" -mtime +${BACKUP_RETENTION_DAYS} -exec rm -rf {} \;

EOF

    if [[ $USE_SSL =~ ^[Yy]$ ]]; then
        echo "# SSL证书续期 - 每天中午12点检查" >> crontab-config
        echo "0 12 * * * /usr/bin/certbot renew --quiet" >> crontab-config
    fi

    info "定时任务配置已生成"
}

# 显示配置摘要
show_config_summary() {
    clear
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   🎉 配置生成完成！                          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo

    log "📋 配置摘要:"
    echo "  项目名称: $PROJECT_NAME"
    echo "  部署路径: $DEPLOY_PATH"
    echo "  运行端口: $APP_PORT"
    echo "  PM2实例数: $PM2_INSTANCES"
    echo "  Node.js堆大小: ${NODE_HEAP_SIZE}MB"

    if [[ $USE_DOMAIN =~ ^[Yy]$ ]]; then
        echo "  域名: $DOMAIN_NAME"
        echo "  SSL: ${USE_SSL}"
    else
        echo "  模式: 本地部署"
    fi

    echo
    log "📁 生成的配置文件:"
    echo "  ✓ ecosystem.config.js - PM2配置"
    echo "  ✓ nginx.conf - Nginx配置"
    echo "  ✓ .env.production - 环境变量"
    echo "  ✓ ${PROJECT_NAME}.service - 系统服务"
    echo "  ✓ crontab-config - 定时任务"
    echo "  ✓ $CONFIG_FILE - 配置记录"

    echo
    log "🚀 下一步操作:"
    info "1. 复制Nginx配置: cp nginx.conf /etc/nginx/sites-available/$PROJECT_NAME"
    info "2. 启用Nginx站点: ln -sf /etc/nginx/sites-available/$PROJECT_NAME /etc/nginx/sites-enabled/"
    info "3. 安装系统服务: cp ${PROJECT_NAME}.service /etc/systemd/system/"
    info "4. 设置定时任务: crontab crontab-config"
    info "5. 执行部署: ./deploy-production.sh"

    if [[ $USE_SSL =~ ^[Yy]$ ]]; then
        echo
        warn "SSL证书配置:"
        info "certbot --nginx -d $DOMAIN_NAME --email $ADMIN_EMAIL --agree-tos --non-interactive --redirect"
    fi

    echo
    echo -e "${GREEN}🎯 所有配置文件已根据您的服务器环境优化完成！${NC}"
}

# 主函数
main() {
    show_welcome
    detect_system_info
    collect_config_info

    echo
    log "正在生成配置文件..."

    generate_config_file
    update_pm2_config
    update_nginx_config
    update_env_config
    update_health_check_config
    update_deploy_script_config
    generate_systemd_service
    generate_crontab_config

    show_config_summary
}

# 脚本入口
case "${1:-configure}" in
    "configure"|"")
        main
        ;;
    "auto")
        # 自动模式 - 使用默认值
        detect_system_info
        PROJECT_NAME="gmgn-app"
        DEPLOY_PATH="/home/project/gmgn-clone"
        RUN_USER="root"
        APP_PORT=3000
        USE_DOMAIN="n"
        DOMAIN_NAME="localhost"
        ADMIN_EMAIL=""
        USE_SSL="n"
        PM2_INSTANCES=$((CPU_CORES > 1 ? CPU_CORES - 1 : 1))
        NODE_HEAP_SIZE=$((TOTAL_MEMORY > 2048 ? 2048 : 1024))
        HEALTH_CHECK_INTERVAL=5
        MEMORY_THRESHOLD=80
        CPU_THRESHOLD=90
        ALERT_EMAIL=""
        BACKUP_RETENTION_DAYS=7
        BACKUP_DIR="/home/project/backups"

        generate_config_file
        update_pm2_config
        update_nginx_config
        update_env_config
        update_health_check_config
        update_deploy_script_config
        generate_systemd_service
        generate_crontab_config

        log "自动配置完成"
        ;;
    "help"|"-h"|"--help")
        echo "GMGN 服务器环境配置工具"
        echo
        echo "用法: $0 [选项]"
        echo
        echo "选项:"
        echo "  configure  交互式配置 (默认)"
        echo "  auto       自动配置 (使用检测到的最佳值)"
        echo "  help       显示帮助信息"
        ;;
    *)
        error "未知参数: $1"
        echo "使用 $0 help 查看帮助"
        exit 1
        ;;
esac
