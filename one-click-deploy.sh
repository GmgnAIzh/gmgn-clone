#!/bin/bash

# GMGN 一键部署脚本
# 版本: 3.0
# 适用于: Ubuntu 20.04+ / CentOS 8+

set -e

# 配置变量
DOMAIN="${1:-localhost}"
EMAIL="${2:-admin@example.com}"
APP_DIR="/home/project/gmgn-clone"
PROJECT_DIR="/home/project"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

# 显示欢迎信息
show_welcome() {
    clear
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    GMGN 一键部署脚本                          ║"
    echo "║                     版本: 3.0                               ║"
    echo "║              全自动生产环境部署解决方案                         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
    log "开始 GMGN 应用一键部署..."
    log "域名: $DOMAIN"
    log "邮箱: $EMAIL"
    echo
}

# 检测操作系统
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        error "无法检测操作系统"
        exit 1
    fi

    log "检测到操作系统: $OS $VER"
}

# 更新系统
update_system() {
    log "更新系统包..."

    if [[ $OS == *"Ubuntu"* ]] || [[ $OS == *"Debian"* ]]; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        apt-get upgrade -y
        apt-get install -y curl wget git unzip jq bc
    elif [[ $OS == *"CentOS"* ]] || [[ $OS == *"Red Hat"* ]]; then
        yum update -y
        yum install -y curl wget git unzip jq bc
    fi

    log "系统更新完成"
}

# 安装Node.js 18
install_nodejs() {
    log "安装 Node.js 18..."

    # 卸载旧版本
    if command -v node &> /dev/null; then
        warning "检测到现有 Node.js 版本，正在卸载..."
        if [[ $OS == *"Ubuntu"* ]] || [[ $OS == *"Debian"* ]]; then
            apt-get remove -y nodejs npm
        elif [[ $OS == *"CentOS"* ]] || [[ $OS == *"Red Hat"* ]]; then
            yum remove -y nodejs npm
        fi
    fi

    # 安装 Node.js 18
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    if [[ $OS == *"Ubuntu"* ]] || [[ $OS == *"Debian"* ]]; then
        apt-get install -y nodejs
    elif [[ $OS == *"CentOS"* ]] || [[ $OS == *"Red Hat"* ]]; then
        yum install -y nodejs
    fi

    # 验证安装
    local node_version=$(node --version)
    log "Node.js 安装完成: $node_version"
}

# 安装Bun
install_bun() {
    log "安装 Bun..."

    curl -fsSL https://bun.sh/install | bash
    export PATH="$HOME/.bun/bin:$PATH"
    echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.bashrc

    # 验证安装
    local bun_version=$(~/.bun/bin/bun --version)
    log "Bun 安装完成: $bun_version"
}

# 安装PM2
install_pm2() {
    log "安装 PM2..."

    npm install -g pm2@latest

    # 配置PM2启动服务
    pm2 startup ubuntu -u root --hp /root

    local pm2_version=$(pm2 --version)
    log "PM2 安装完成: $pm2_version"
}

# 安装Nginx
install_nginx() {
    log "安装 Nginx..."

    if [[ $OS == *"Ubuntu"* ]] || [[ $OS == *"Debian"* ]]; then
        apt-get install -y nginx
    elif [[ $OS == *"CentOS"* ]] || [[ $OS == *"Red Hat"* ]]; then
        yum install -y nginx
    fi

    # 启动并启用Nginx
    systemctl start nginx
    systemctl enable nginx

    log "Nginx 安装完成"
}

# 配置防火墙
configure_firewall() {
    log "配置防火墙..."

    if command -v ufw &> /dev/null; then
        # Ubuntu UFW
        ufw --force enable
        ufw allow ssh
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw allow 3000/tcp
    elif command -v firewall-cmd &> /dev/null; then
        # CentOS firewalld
        systemctl start firewalld
        systemctl enable firewalld
        firewall-cmd --permanent --add-service=ssh
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --permanent --add-port=3000/tcp
        firewall-cmd --reload
    fi

    log "防火墙配置完成"
}

# 部署应用
deploy_application() {
    log "部署GMGN应用..."

    cd $APP_DIR

    # 安装依赖
    export PATH="$HOME/.bun/bin:$PATH"
    ~/.bun/bin/bun install

    # 构建应用
    ~/.bun/bin/bun run build

    # 停止现有应用
    pm2 stop gmgn-app 2>/dev/null || true
    pm2 delete gmgn-app 2>/dev/null || true

    # 启动应用
    pm2 start ecosystem.config.js --env production
    pm2 save

    log "应用部署完成"
}

# 配置Nginx
configure_nginx() {
    log "配置 Nginx..."

    # 备份默认配置
    cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup 2>/dev/null || true

    # 创建GMGN站点配置
    cat > /etc/nginx/sites-available/gmgn << EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:3000;
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

    # 静态资源
    location /_next/static/ {
        alias $APP_DIR/.next/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # 健康检查
    location /health {
        proxy_pass http://127.0.0.1:3000;
        access_log off;
    }
}
EOF

    # 启用站点
    ln -sf /etc/nginx/sites-available/gmgn /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default

    # 测试配置
    nginx -t

    # 重启Nginx
    systemctl reload nginx

    log "Nginx 配置完成"
}

# 安装SSL证书
install_ssl() {
    if [ "$DOMAIN" != "localhost" ] && [ "$DOMAIN" != "127.0.0.1" ]; then
        log "安装 SSL 证书..."

        # 安装Certbot
        if [[ $OS == *"Ubuntu"* ]] || [[ $OS == *"Debian"* ]]; then
            apt-get install -y certbot python3-certbot-nginx
        elif [[ $OS == *"CentOS"* ]] || [[ $OS == *"Red Hat"* ]]; then
            yum install -y certbot python3-certbot-nginx
        fi

        # 获取SSL证书
        certbot --nginx -d $DOMAIN --email $EMAIL --agree-tos --non-interactive --redirect

        # 设置自动续期
        echo "0 12 * * * /usr/bin/certbot renew --quiet" | crontab -

        log "SSL 证书安装完成"
    else
        warning "跳过 SSL 配置 (使用 localhost)"
    fi
}

# 设置监控
setup_monitoring() {
    log "设置监控和日志..."

    # 创建日志目录
    mkdir -p /var/log/pm2
    mkdir -p /var/log/gmgn

    # 设置日志轮转
    cat > /etc/logrotate.d/gmgn << EOF
/var/log/pm2/*.log {
    daily
    missingok
    rotate 7
    compress
    notifempty
    create 644 root root
    postrotate
        pm2 reloadLogs
    endscript
}
EOF

    # 设置crontab监控
    cat > /etc/cron.d/gmgn-health << EOF
# GMGN 健康检查 - 每5分钟执行一次
*/5 * * * * root $APP_DIR/health-check.sh check >> /var/log/gmgn/health.log 2>&1
EOF

    log "监控设置完成"
}

# 创建管理脚本
create_management_scripts() {
    log "创建管理脚本..."

    # 创建服务管理脚本
    cat > /usr/local/bin/gmgn << 'EOF'
#!/bin/bash

APP_DIR="/home/project/gmgn-clone"

case "$1" in
    start)
        cd $APP_DIR && pm2 start ecosystem.config.js --env production
        ;;
    stop)
        pm2 stop gmgn-app
        ;;
    restart)
        pm2 restart gmgn-app
        ;;
    status)
        pm2 status gmgn-app
        ;;
    logs)
        pm2 logs gmgn-app
        ;;
    deploy)
        cd $APP_DIR && ./deploy-production.sh
        ;;
    health)
        cd $APP_DIR && ./health-check.sh
        ;;
    *)
        echo "用法: gmgn {start|stop|restart|status|logs|deploy|health}"
        exit 1
        ;;
esac
EOF

    chmod +x /usr/local/bin/gmgn

    log "管理脚本创建完成"
    info "使用 'gmgn help' 查看可用命令"
}

# 验证部署
verify_deployment() {
    log "验证部署..."

    # 等待应用启动
    sleep 10

    # 检查PM2状态
    local pm2_status=$(pm2 jlist | jq -r '.[] | select(.name=="gmgn-app") | .pm2_env.status' 2>/dev/null || echo "stopped")

    if [ "$pm2_status" = "online" ]; then
        log "✓ PM2 状态正常"
    else
        error "✗ PM2 状态异常: $pm2_status"
        return 1
    fi

    # 检查HTTP响应
    local http_url="http://localhost:3000"
    if [ "$DOMAIN" != "localhost" ]; then
        http_url="https://$DOMAIN"
    fi

    local http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 $http_url 2>/dev/null || echo "000")

    if [ "$http_code" = "200" ]; then
        log "✓ HTTP 响应正常"
    else
        error "✗ HTTP 响应异常: $http_code"
        return 1
    fi

    log "部署验证成功！"
}

# 显示部署结果
show_deployment_result() {
    clear
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   🎉 部署成功完成！                          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo

    if [ "$DOMAIN" != "localhost" ]; then
        log "🌐 网站地址: https://$DOMAIN"
    else
        log "🌐 本地地址: http://localhost:3000"
    fi

    echo
    log "📋 管理命令:"
    info "  gmgn start     - 启动应用"
    info "  gmgn stop      - 停止应用"
    info "  gmgn restart   - 重启应用"
    info "  gmgn status    - 查看状态"
    info "  gmgn logs      - 查看日志"
    info "  gmgn deploy    - 重新部署"
    info "  gmgn health    - 健康检查"

    echo
    log "📊 监控信息:"
    info "  应用状态: $(pm2 jlist | jq -r '.[] | select(.name=="gmgn-app") | .pm2_env.status' 2>/dev/null || echo "unknown")"
    info "  内存使用: $(pm2 jlist | jq -r '.[] | select(.name=="gmgn-app") | .monit.memory' 2>/dev/null | awk '{print int($1/1024/1024)"MB"}' || echo "unknown")"
    info "  CPU使用: $(pm2 jlist | jq -r '.[] | select(.name=="gmgn-app") | .monit.cpu' 2>/dev/null || echo "unknown")%"

    echo
    log "📁 重要文件路径:"
    info "  应用目录: $APP_DIR"
    info "  日志目录: /var/log/pm2/"
    info "  Nginx配置: /etc/nginx/sites-available/gmgn"

    echo
    log "🔧 故障排除:"
    info "  如果网站无法访问，请检查防火墙设置"
    info "  查看详细日志: tail -f /var/log/pm2/gmgn-*.log"
    info "  重新部署: cd $APP_DIR && ./deploy-production.sh"

    echo
    echo -e "${GREEN}🚀 GMGN 应用已成功部署并运行！${NC}"
}

# 主部署流程
main() {
    # 检查是否为root用户
    if [ "$EUID" -ne 0 ]; then
        error "请使用 root 用户运行此脚本"
        exit 1
    fi

    show_welcome

    # 执行部署步骤
    detect_os
    update_system
    install_nodejs
    install_bun
    install_pm2
    install_nginx
    configure_firewall
    deploy_application
    configure_nginx
    install_ssl
    setup_monitoring
    create_management_scripts
    verify_deployment
    show_deployment_result
}

# 脚本入口
case "${1:-deploy}" in
    "deploy"|"")
        main
        ;;
    "help"|"-h"|"--help")
        echo "GMGN 一键部署脚本"
        echo
        echo "用法: $0 [域名] [邮箱]"
        echo
        echo "参数:"
        echo "  域名    可选，默认为 localhost"
        echo "  邮箱    可选，SSL证书邮箱，默认为 admin@example.com"
        echo
        echo "示例:"
        echo "  $0                              # 本地部署"
        echo "  $0 example.com                  # 域名部署"
        echo "  $0 example.com admin@gmail.com  # 域名+邮箱部署"
        ;;
    *)
        echo "未知参数: $1"
        echo "使用 $0 help 查看帮助"
        exit 1
        ;;
esac
