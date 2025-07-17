#!/bin/bash

# GMGN 香港地域专用一键部署脚本
# 版本: 1.0
# 服务器: 45.194.37.150 (4vCPU, 4GB RAM, 5Mbps)

set -e

# 服务器配置
SERVER_IP="45.194.37.150"
SERVER_CORES="4"
SERVER_MEMORY="4096"
SERVER_BANDWIDTH="5"
DEPLOY_PATH="/home/project/gmgn-clone"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 日志函数
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S HKT')]${NC} $1"
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
    echo "║                GMGN 香港地域专用部署脚本                      ║"
    echo "║                版本: HK-Optimized v1.0                      ║"
    echo "║             针对香港云服务器优化配置                          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
    log "开始 GMGN 香港地域优化部署..."
    echo "服务器IP: $SERVER_IP"
    echo "CPU核心: ${SERVER_CORES}vCPU"
    echo "内存大小: ${SERVER_MEMORY}MB"
    echo "带宽限制: ${SERVER_BANDWIDTH}Mbps"
    echo
}

# 设置香港时区
setup_timezone() {
    log "设置香港时区..."

    timedatectl set-timezone Asia/Hong_Kong

    # 同步时间
    apt-get update -qq
    apt-get install -y ntp ntpdate

    # 配置NTP服务器
    cat > /etc/ntp.conf << EOF
# 香港和亚洲NTP服务器
server ntp.aliyun.com iburst
server time.cloudflare.com iburst
server pool.ntp.org iburst
server 0.asia.pool.ntp.org iburst
server 1.asia.pool.ntp.org iburst

# 本地时间配置
driftfile /var/lib/ntp/ntp.drift
logfile /var/log/ntpd.log
EOF

    systemctl restart ntp
    ntpdate -s ntp.aliyun.com

    info "时区设置完成: $(date)"
}

# 系统优化 - 香港网络环境
optimize_system() {
    log "优化系统参数 - 香港网络环境..."

    # 网络优化
    cat >> /etc/sysctl.conf << EOF

# GMGN 香港网络优化配置
# TCP BBR拥塞控制
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

# 网络缓冲区优化 - 适配5Mbps带宽
net.core.rmem_default=262144
net.core.rmem_max=8388608
net.core.wmem_default=262144
net.core.wmem_max=8388608
net.ipv4.tcp_rmem=4096 87380 8388608
net.ipv4.tcp_wmem=4096 65536 8388608

# TCP优化
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_timestamps=1
net.ipv4.tcp_sack=1
net.ipv4.tcp_fack=1
net.ipv4.tcp_low_latency=1

# 连接优化
net.core.somaxconn=65535
net.core.netdev_max_backlog=5000
net.ipv4.tcp_max_syn_backlog=4096
net.ipv4.tcp_keepalive_time=300
net.ipv4.tcp_keepalive_probes=3
net.ipv4.tcp_keepalive_intvl=15

# 文件描述符限制
fs.file-max=1000000
fs.nr_open=1000000
EOF

    # 应用系统参数
    sysctl -p

    # 设置用户限制
    cat >> /etc/security/limits.conf << EOF
# GMGN 用户限制配置
* soft nofile 65535
* hard nofile 65535
* soft nproc 32768
* hard nproc 32768
root soft nofile 65535
root hard nofile 65535
EOF

    info "系统优化完成"
}

# 安装依赖 - Ubuntu 24.04
install_dependencies() {
    log "安装系统依赖 - Ubuntu 24.04..."

    # 更新包列表
    apt-get update -y

    # 安装基础工具
    apt-get install -y \
        curl wget git unzip \
        build-essential \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        htop iotop \
        jq bc \
        nginx \
        ufw \
        fail2ban

    info "系统依赖安装完成"
}

# 安装Node.js 18 - 针对4GB内存优化
install_nodejs() {
    log "安装 Node.js 18 - 内存优化配置..."

    # 添加NodeSource仓库
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -

    # 安装Node.js
    apt-get install -y nodejs

    # 配置npm - 适配香港网络
    npm config set registry https://registry.npmmirror.com
    npm config set timeout 300000
    npm config set maxsockets 10

    # 验证安装
    local node_version=$(node --version)
    local npm_version=$(npm --version)

    info "Node.js 安装完成: $node_version"
    info "npm 版本: $npm_version"
}

# 安装PM2 - 4核心优化配置
install_pm2() {
    log "安装 PM2 - 多核心优化..."

    npm install -g pm2@latest

    # 配置PM2启动服务
    pm2 startup ubuntu -u root --hp /root

    # PM2日志轮转
    pm2 install pm2-logrotate
    pm2 set pm2-logrotate:max_size 10M
    pm2 set pm2-logrotate:retain 5
    pm2 set pm2-logrotate:compress true

    info "PM2 安装完成"
}

# 配置防火墙 - 香港安全策略
configure_firewall() {
    log "配置防火墙 - 香港安全策略..."

    # UFW配置
    ufw --force enable
    ufw default deny incoming
    ufw default allow outgoing

    # 允许必要端口
    ufw allow ssh
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 3000/tcp

    # 配置fail2ban
    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 1800
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10
EOF

    systemctl restart fail2ban

    info "防火墙配置完成"
}

# 部署应用 - 香港优化版本
deploy_application() {
    log "部署 GMGN 应用 - 香港优化版本..."

    # 确保目录存在
    mkdir -p $DEPLOY_PATH
    cd $DEPLOY_PATH

    # 安装项目依赖
    if [ -f "package.json" ]; then
        # 使用香港镜像源加速
        npm config set registry https://registry.npmmirror.com
        npm install --production=false --timeout=300000
    else
        error "package.json not found"
        return 1
    fi

    # 复制香港优化配置文件
    if [ -f "ecosystem.config.hk.js" ]; then
        cp ecosystem.config.hk.js ecosystem.config.js
        info "使用香港优化PM2配置"
    fi

    if [ -f ".env.hk" ]; then
        cp .env.hk .env.production
        info "使用香港优化环境变量"
    fi

    # 构建应用
    export NODE_OPTIONS="--max-old-space-size=1536"
    npm run build

    info "应用构建完成"
}

# 配置Nginx - 带宽优化
configure_nginx() {
    log "配置 Nginx - 5Mbps带宽优化..."

    # 备份默认配置
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

    # 使用香港优化配置
    if [ -f "$DEPLOY_PATH/nginx-hk.conf" ]; then
        cp $DEPLOY_PATH/nginx-hk.conf /etc/nginx/nginx.conf
    fi

    # 创建缓存目录
    mkdir -p /var/cache/nginx/gmgn
    mkdir -p /var/cache/nginx/temp
    chown -R www-data:www-data /var/cache/nginx

    # 测试配置
    nginx -t

    # 重启Nginx
    systemctl restart nginx
    systemctl enable nginx

    info "Nginx 配置完成"
}

# 启动应用服务
start_services() {
    log "启动应用服务..."

    cd $DEPLOY_PATH

    # 停止现有服务
    pm2 stop all 2>/dev/null || true
    pm2 delete all 2>/dev/null || true

    # 启动应用
    pm2 start ecosystem.config.js --env production
    pm2 save

    # 等待服务启动
    sleep 10

    info "应用服务启动完成"
}

# 健康检查
health_check() {
    log "执行健康检查..."

    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -sf http://localhost:3000 > /dev/null 2>&1; then
            info "✓ 应用健康检查通过"
            return 0
        fi

        info "等待应用启动... ($attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done

    error "✗ 应用健康检查失败"
    return 1
}

# 系统监控设置
setup_monitoring() {
    log "设置系统监控..."

    # 创建监控脚本
    cat > /usr/local/bin/gmgn-monitor << 'EOF'
#!/bin/bash
# GMGN系统监控脚本

LOG_FILE="/var/log/gmgn-monitor.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# 检查PM2状态
PM2_STATUS=$(pm2 jlist | jq -r '.[0].pm2_env.status' 2>/dev/null || echo "stopped")

# 检查内存使用
MEMORY_USAGE=$(free | grep Mem | awk '{printf("%.1f", $3/$2 * 100.0)}')

# 检查CPU使用
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')

# 检查磁盘使用
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

echo "[$DATE] PM2:$PM2_STATUS MEM:${MEMORY_USAGE}% CPU:${CPU_USAGE}% DISK:${DISK_USAGE}%" >> $LOG_FILE

# 如果内存使用超过85%，重启应用
if (( $(echo "$MEMORY_USAGE > 85" | bc -l) )); then
    echo "[$DATE] High memory usage, restarting PM2" >> $LOG_FILE
    pm2 restart all
fi
EOF

    chmod +x /usr/local/bin/gmgn-monitor

    # 添加到crontab
    (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/gmgn-monitor") | crontab -

    info "系统监控设置完成"
}

# 显示部署结果
show_result() {
    clear
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              🎉 GMGN 香港部署成功完成！                      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo

    log "🌐 访问地址: http://$SERVER_IP:3000"
    echo

    log "📊 服务器状态:"
    echo "  IP地址: $SERVER_IP"
    echo "  CPU核心: ${SERVER_CORES}vCPU"
    echo "  内存: ${SERVER_MEMORY}MB"
    echo "  带宽: ${SERVER_BANDWIDTH}Mbps"
    echo "  时区: $(timedatectl | grep "Time zone" | awk '{print $3}')"
    echo

    log "🔧 PM2状态:"
    pm2 status
    echo

    log "📈 系统资源:"
    echo "  内存使用: $(free | grep Mem | awk '{printf("%.1f%%", $3/$2 * 100.0)}')"
    echo "  磁盘使用: $(df -h / | awk 'NR==2 {print $5}')"
    echo "  负载均衡: $(uptime | awk -F'load average:' '{print $2}')"
    echo

    log "🛠️ 管理命令:"
    echo "  pm2 status          - 查看应用状态"
    echo "  pm2 logs            - 查看应用日志"
    echo "  pm2 restart all     - 重启应用"
    echo "  systemctl status nginx - 查看Nginx状态"
    echo "  tail -f /var/log/gmgn-monitor.log - 查看监控日志"
    echo

    echo -e "${GREEN}🚀 GMGN应用已成功部署在香港服务器！${NC}"
    echo -e "${CYAN}📱 请在浏览器访问: http://$SERVER_IP:3000${NC}"
}

# 主部署流程
main() {
    # 检查权限
    if [ "$EUID" -ne 0 ]; then
        error "请使用 root 用户运行此脚本"
        exit 1
    fi

    show_welcome

    # 执行部署步骤
    setup_timezone
    optimize_system
    install_dependencies
    install_nodejs
    install_pm2
    configure_firewall
    deploy_application
    configure_nginx
    start_services

    if health_check; then
        setup_monitoring
        show_result
    else
        error "部署失败，请检查日志"
        exit 1
    fi
}

# 脚本入口
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "status")
        echo "=== GMGN 服务状态 ==="
        echo "PM2状态:"
        pm2 status
        echo
        echo "Nginx状态:"
        systemctl status nginx --no-pager
        echo
        echo "系统资源:"
        echo "内存: $(free -h | grep Mem | awk '{print $3"/"$2}')"
        echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')"
        echo "磁盘: $(df -h / | awk 'NR==2 {print $3"/"$2" ("$5")"}')"
        ;;
    "restart")
        log "重启 GMGN 服务..."
        pm2 restart all
        systemctl restart nginx
        log "服务重启完成"
        ;;
    "logs")
        pm2 logs --lines 50
        ;;
    "monitor")
        tail -f /var/log/gmgn-monitor.log
        ;;
    "help")
        echo "GMGN 香港地域部署脚本"
        echo
        echo "用法: $0 [选项]"
        echo
        echo "选项:"
        echo "  deploy   - 执行完整部署 (默认)"
        echo "  status   - 查看服务状态"
        echo "  restart  - 重启所有服务"
        echo "  logs     - 查看应用日志"
        echo "  monitor  - 查看监控日志"
        echo "  help     - 显示帮助信息"
        ;;
    *)
        error "未知参数: $1"
        echo "使用 $0 help 查看帮助"
        exit 1
        ;;
esac
