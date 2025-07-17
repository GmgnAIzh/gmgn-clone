#!/bin/bash

# GMGN 配置模板应用工具
# 版本: 1.0
# 功能: 快速应用预设的服务器配置模板

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 配置文件
TEMPLATES_FILE="server-templates.json"
CONFIG_FILE="server-config.json"

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

# 显示标题
show_header() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║               GMGN 配置模板应用工具                           ║"
    echo "║            快速应用预设的服务器配置模板                        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
}

# 检查依赖
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        error "需要安装 jq 工具"
        info "安装命令: apt install jq 或 yum install jq"
        exit 1
    fi

    if [[ ! -f "$TEMPLATES_FILE" ]]; then
        error "模板文件不存在: $TEMPLATES_FILE"
        exit 1
    fi

    log "依赖检查通过"
}

# 显示可用模板
show_available_templates() {
    log "可用的配置模板:"
    echo

    local templates=$(jq -r '.templates | keys[]' $TEMPLATES_FILE)
    local index=1

    for template in $templates; do
        local name=$(jq -r ".templates.$template.name" $TEMPLATES_FILE)
        local description=$(jq -r ".templates.$template.description" $TEMPLATES_FILE)

        echo -e "${CYAN}[$index]${NC} ${GREEN}$template${NC}"
        echo "    名称: $name"
        echo "    描述: $description"
        echo

        ((index++))
    done
}

# 显示模板详情
show_template_details() {
    local template_key="$1"

    if ! jq -e ".templates.$template_key" $TEMPLATES_FILE >/dev/null 2>&1; then
        error "模板不存在: $template_key"
        return 1
    fi

    local name=$(jq -r ".templates.$template_key.name" $TEMPLATES_FILE)
    local description=$(jq -r ".templates.$template_key.description" $TEMPLATES_FILE)

    echo -e "${CYAN}=== 模板详情 ===${NC}"
    echo "名称: $name"
    echo "描述: $description"
    echo

    # 显示规格要求
    echo -e "${CYAN}硬件规格:${NC}"
    local cpu_cores=$(jq -r ".templates.$template_key.specs.cpu_cores" $TEMPLATES_FILE)
    local memory_mb=$(jq -r ".templates.$template_key.specs.memory_mb" $TEMPLATES_FILE)
    local disk_gb=$(jq -r ".templates.$template_key.specs.disk_gb" $TEMPLATES_FILE)

    echo "  CPU核心: $cpu_cores"
    echo "  内存: ${memory_mb}MB"
    echo "  硬盘: ${disk_gb}GB"
    echo

    # 显示性能配置
    echo -e "${CYAN}性能配置:${NC}"
    local pm2_instances=$(jq -r ".templates.$template_key.config.pm2_instances" $TEMPLATES_FILE)
    local node_heap_size=$(jq -r ".templates.$template_key.config.node_heap_size" $TEMPLATES_FILE)
    local health_interval=$(jq -r ".templates.$template_key.config.health_check_interval" $TEMPLATES_FILE)

    echo "  PM2实例数: $pm2_instances"
    echo "  Node.js堆大小: ${node_heap_size}MB"
    echo "  健康检查间隔: ${health_interval}分钟"
    echo

    # 显示限制配置
    echo -e "${CYAN}性能限制:${NC}"
    local max_connections=$(jq -r ".templates.$template_key.limits.max_concurrent_connections" $TEMPLATES_FILE)
    local max_rate=$(jq -r ".templates.$template_key.limits.max_request_rate" $TEMPLATES_FILE)
    local max_upload=$(jq -r ".templates.$template_key.limits.max_file_uploads" $TEMPLATES_FILE)

    echo "  最大并发连接: $max_connections"
    echo "  最大请求频率: $max_rate"
    echo "  最大文件上传: $max_upload"
    echo
}

# 检测当前系统匹配的模板
detect_recommended_template() {
    log "检测推荐模板..."

    local cpu_cores=$(nproc)
    local total_memory=$(free -m | awk 'NR==2{printf "%.0f", $2}')

    info "当前系统配置:"
    echo "  CPU核心: $cpu_cores"
    echo "  总内存: ${total_memory}MB"
    echo

    # 根据系统配置推荐模板
    if [[ $total_memory -lt 2048 ]]; then
        echo -e "${YELLOW}推荐模板: small_server${NC}"
        recommend "small_server"
    elif [[ $total_memory -lt 8192 ]]; then
        echo -e "${YELLOW}推荐模板: medium_server${NC}"
        recommend "medium_server"
    else
        echo -e "${YELLOW}推荐模板: large_server${NC}"
        recommend "large_server"
    fi
}

# 推荐模板
recommend() {
    local template_key="$1"
    echo
    echo -e "${GREEN}=== 推荐配置 ===${NC}"
    show_template_details "$template_key"
}

# 应用模板配置
apply_template() {
    local template_key="$1"
    local domain_name="${2:-localhost}"
    local admin_email="${3:-admin@example.com}"

    if ! jq -e ".templates.$template_key" $TEMPLATES_FILE >/dev/null 2>&1; then
        error "模板不存在: $template_key"
        return 1
    fi

    log "应用模板: $template_key"

    # 获取当前系统信息
    local cpu_cores=$(nproc)
    local total_memory=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    local available_memory=$(free -m | awk 'NR==2{printf "%.0f", $4}')
    local disk_total=$(df -h / | awk 'NR==2 {print $2}')
    local disk_available=$(df -h / | awk 'NR==2 {print $4}')
    local public_ip=$(curl -s ifconfig.me 2>/dev/null || echo "Unknown")

    # 获取模板配置
    local pm2_instances=$(jq -r ".templates.$template_key.config.pm2_instances" $TEMPLATES_FILE)
    local node_heap_size=$(jq -r ".templates.$template_key.config.node_heap_size" $TEMPLATES_FILE)
    local health_interval=$(jq -r ".templates.$template_key.config.health_check_interval" $TEMPLATES_FILE)
    local memory_threshold=$(jq -r ".templates.$template_key.config.memory_threshold" $TEMPLATES_FILE)
    local cpu_threshold=$(jq -r ".templates.$template_key.config.cpu_threshold" $TEMPLATES_FILE)
    local backup_retention=$(jq -r ".templates.$template_key.config.backup_retention_days" $TEMPLATES_FILE)

    # 处理auto值
    if [[ "$pm2_instances" == "max" ]]; then
        pm2_instances=$((cpu_cores > 1 ? cpu_cores - 1 : 1))
    elif [[ "$pm2_instances" == "auto" ]]; then
        if [[ $cpu_cores -le 2 ]]; then
            pm2_instances=1
        else
            pm2_instances=$((cpu_cores / 2))
        fi
    fi

    if [[ "$node_heap_size" == "auto" ]]; then
        if [[ $total_memory -le 2048 ]]; then
            node_heap_size=1024
        elif [[ $total_memory -le 4096 ]]; then
            node_heap_size=2048
        else
            node_heap_size=4096
        fi
    fi

    # 生成配置文件
    cat > $CONFIG_FILE << EOF
{
    "template_applied": "$template_key",
    "system": {
        "os_name": "$(. /etc/os-release && echo $NAME)",
        "os_version": "$(. /etc/os-release && echo $VERSION_ID)",
        "cpu_cores": $cpu_cores,
        "total_memory": $total_memory,
        "available_memory": $available_memory,
        "disk_total": "$disk_total",
        "disk_available": "$disk_available",
        "public_ip": "$public_ip"
    },
    "project": {
        "name": "gmgn-app",
        "deploy_path": "/home/project/gmgn-clone",
        "run_user": "root",
        "app_port": 3000
    },
    "domain": {
        "use_domain": "$([ "$domain_name" != "localhost" ] && echo "y" || echo "n")",
        "domain_name": "$domain_name",
        "admin_email": "$admin_email",
        "use_ssl": "$([ "$domain_name" != "localhost" ] && echo "y" || echo "n")"
    },
    "performance": {
        "pm2_instances": $pm2_instances,
        "node_heap_size": $node_heap_size
    },
    "monitoring": {
        "health_check_interval": $health_interval,
        "memory_threshold": $memory_threshold,
        "cpu_threshold": $cpu_threshold,
        "alert_email": "$admin_email"
    },
    "backup": {
        "retention_days": $backup_retention,
        "backup_dir": "/home/project/backups"
    },
    "template_info": $(jq ".templates.$template_key" $TEMPLATES_FILE),
    "generated_at": "$(date -Iseconds)"
}
EOF

    info "配置文件已生成: $CONFIG_FILE"

    # 应用配置到各个文件
    apply_pm2_config "$template_key"
    apply_nginx_config "$template_key" "$domain_name"
    apply_env_config "$template_key" "$domain_name"

    log "模板应用完成"
}

# 应用PM2配置
apply_pm2_config() {
    local template_key="$1"

    local pm2_instances=$(jq -r '.performance.pm2_instances' $CONFIG_FILE)
    local node_heap_size=$(jq -r '.performance.node_heap_size' $CONFIG_FILE)
    local deploy_path=$(jq -r '.project.deploy_path' $CONFIG_FILE)
    local app_port=$(jq -r '.project.app_port' $CONFIG_FILE)

    cat > ecosystem.config.js << EOF
module.exports = {
  apps: [
    {
      name: 'gmgn-app',
      script: 'node_modules/next/dist/bin/next',
      args: 'start -H 0.0.0.0 -p $app_port',
      cwd: '$deploy_path',
      instances: $pm2_instances,
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'production',
        PORT: $app_port,
        HOSTNAME: '0.0.0.0',
        NODE_OPTIONS: '--max-old-space-size=$node_heap_size'
      },
      autorestart: true,
      watch: false,
      max_memory_restart: '${node_heap_size}M',
      error_file: '/var/log/pm2/gmgn-error.log',
      out_file: '/var/log/pm2/gmgn-out.log',
      log_file: '/var/log/pm2/gmgn-combined.log',
      time: true,
      min_uptime: '10s',
      max_restarts: 10,
      kill_timeout: 5000,
      env_production: {
        NODE_ENV: 'production',
        PORT: $app_port,
        HOSTNAME: '0.0.0.0',
        NODE_OPTIONS: '--max-old-space-size=$node_heap_size',
        NEXT_PUBLIC_API_URL: 'https://api.coingecko.com/api/v3',
        NEXT_TELEMETRY_DISABLED: 1
      }
    }
  ]
};
EOF

    info "PM2配置已更新"
}

# 应用Nginx配置
apply_nginx_config() {
    local template_key="$1"
    local domain_name="$2"

    local app_port=$(jq -r '.project.app_port' $CONFIG_FILE)
    local deploy_path=$(jq -r '.project.deploy_path' $CONFIG_FILE)

    # 获取模板的worker配置
    local worker_processes=$(jq -r ".templates.$template_key.config.nginx_worker_processes // 1" $TEMPLATES_FILE)
    local worker_connections=$(jq -r ".templates.$template_key.config.nginx_worker_connections // 1024" $TEMPLATES_FILE)

    if [[ "$worker_processes" == "auto" ]]; then
        worker_processes="auto"
    fi

    cat > nginx.conf << EOF
# GMGN Nginx配置 - 模板: $template_key
worker_processes $worker_processes;
events {
    worker_connections $worker_connections;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # 基础配置
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    upstream gmgn_backend {
        least_conn;
        server 127.0.0.1:$app_port max_fails=3 fail_timeout=30s;
        keepalive 32;
    }
EOF

    if [[ "$domain_name" != "localhost" ]]; then
        cat >> nginx.conf << EOF

    # HTTP重定向到HTTPS
    server {
        listen 80;
        server_name $domain_name;
        return 301 https://\$server_name\$request_uri;
    }

    # HTTPS主配置
    server {
        listen 443 ssl http2;
        server_name $domain_name;

        ssl_certificate /etc/letsencrypt/live/$domain_name/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/$domain_name/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers off;

        # 安全头
        add_header Strict-Transport-Security "max-age=63072000" always;
        add_header X-Frame-Options "DENY" always;
        add_header X-Content-Type-Options "nosniff" always;

        location / {
            proxy_pass http://gmgn_backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_cache_bypass \$http_upgrade;
        }

        location /_next/static/ {
            alias $deploy_path/.next/static/;
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
EOF
    else
        cat >> nginx.conf << EOF

    server {
        listen 80;
        server_name localhost;

        location / {
            proxy_pass http://gmgn_backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_cache_bypass \$http_upgrade;
        }

        location /_next/static/ {
            alias $deploy_path/.next/static/;
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
EOF
    fi

    info "Nginx配置已更新"
}

# 应用环境变量配置
apply_env_config() {
    local template_key="$1"
    local domain_name="$2"

    local app_port=$(jq -r '.project.app_port' $CONFIG_FILE)
    local node_heap_size=$(jq -r '.performance.node_heap_size' $CONFIG_FILE)

    cat > .env.production << EOF
# 生产环境配置 - 模板: $template_key
NODE_ENV=production
PORT=$app_port
HOSTNAME=0.0.0.0
NODE_OPTIONS=--max-old-space-size=$node_heap_size

# API配置
NEXT_PUBLIC_API_URL=https://api.coingecko.com/api/v3
NEXT_PUBLIC_API_TIMEOUT=10000

# 性能优化
NEXT_TELEMETRY_DISABLED=1
NEXT_SHARP=1

# 站点配置
EOF

    if [[ "$domain_name" != "localhost" ]]; then
        echo "NEXT_PUBLIC_SITE_URL=https://$domain_name" >> .env.production
    else
        echo "NEXT_PUBLIC_SITE_URL=http://localhost:$app_port" >> .env.production
    fi

    cat >> .env.production << EOF

# 缓存配置
CACHE_TTL=300

# 模板信息
TEMPLATE_APPLIED=$template_key
GENERATED_AT=$(date -Iseconds)
EOF

    info "环境变量配置已更新"
}

# 显示应用结果
show_apply_result() {
    local template_key="$1"
    local domain_name="$2"

    echo
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   🎉 模板应用完成！                          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo

    log "应用的模板: $template_key"
    if [[ "$domain_name" != "localhost" ]]; then
        info "域名: $domain_name"
    else
        info "模式: 本地部署"
    fi

    echo
    log "生成的配置文件:"
    echo "  ✓ $CONFIG_FILE - 配置记录"
    echo "  ✓ ecosystem.config.js - PM2配置"
    echo "  ✓ nginx.conf - Nginx配置"
    echo "  ✓ .env.production - 环境变量"

    echo
    log "下一步操作:"
    info "1. 验证配置: ./validate-config.sh"
    info "2. 部署应用: ./deploy-production.sh"
    info "3. 一键部署: ./one-click-deploy.sh $domain_name"

    echo
    echo -e "${GREEN}🚀 配置已优化，可以开始部署！${NC}"
}

# 交互式模板选择
interactive_selection() {
    show_available_templates

    echo -n "请选择模板编号或名称: "
    read -r selection

    # 如果输入的是数字，转换为模板名称
    if [[ "$selection" =~ ^[0-9]+$ ]]; then
        local templates=($(jq -r '.templates | keys[]' $TEMPLATES_FILE))
        local index=$((selection - 1))

        if [[ $index -ge 0 && $index -lt ${#templates[@]} ]]; then
            selection="${templates[$index]}"
        else
            error "无效的选择: $selection"
            return 1
        fi
    fi

    # 验证模板是否存在
    if ! jq -e ".templates.$selection" $TEMPLATES_FILE >/dev/null 2>&1; then
        error "模板不存在: $selection"
        return 1
    fi

    echo
    show_template_details "$selection"

    echo -n "确认应用此模板? (y/n): "
    read -r confirm

    if [[ $confirm =~ ^[Yy]$ ]]; then
        echo -n "域名 (留空使用localhost): "
        read -r domain_name
        domain_name=${domain_name:-localhost}

        if [[ "$domain_name" != "localhost" ]]; then
            echo -n "管理员邮箱: "
            read -r admin_email
            admin_email=${admin_email:-admin@example.com}
        else
            admin_email=""
        fi

        apply_template "$selection" "$domain_name" "$admin_email"
        show_apply_result "$selection" "$domain_name"
    else
        info "已取消操作"
    fi
}

# 主函数
main() {
    show_header
    check_dependencies

    if [[ $# -eq 0 ]]; then
        # 交互模式
        detect_recommended_template
        echo
        interactive_selection
    else
        # 命令行模式
        local template_key="$1"
        local domain_name="${2:-localhost}"
        local admin_email="${3:-admin@example.com}"

        if [[ "$template_key" == "recommend" ]]; then
            detect_recommended_template
        else
            apply_template "$template_key" "$domain_name" "$admin_email"
            show_apply_result "$template_key" "$domain_name"
        fi
    fi
}

# 脚本入口
case "${1:-interactive}" in
    "interactive"|"")
        main
        ;;
    "list")
        check_dependencies
        show_available_templates
        ;;
    "recommend")
        check_dependencies
        detect_recommended_template
        ;;
    "small_server"|"medium_server"|"large_server"|"cloud_optimized"|"development"|"production_optimized")
        check_dependencies
        main "$@"
        ;;
    "help"|"-h"|"--help")
        echo "GMGN 配置模板应用工具"
        echo
        echo "用法: $0 [模板名称] [域名] [邮箱]"
        echo
        echo "模板:"
        echo "  small_server       小型服务器配置"
        echo "  medium_server      中型服务器配置"
        echo "  large_server       大型服务器配置"
        echo "  cloud_optimized    云服务器优化配置"
        echo "  development        开发环境配置"
        echo "  production_optimized 生产环境优化配置"
        echo
        echo "选项:"
        echo "  interactive        交互式选择 (默认)"
        echo "  list               列出所有模板"
        echo "  recommend          显示推荐模板"
        echo "  help               显示帮助信息"
        echo
        echo "示例:"
        echo "  $0                                   # 交互式选择"
        echo "  $0 medium_server                     # 应用中型服务器模板"
        echo "  $0 large_server example.com admin@example.com  # 域名部署"
        ;;
    *)
        error "未知参数: $1"
        echo "使用 $0 help 查看帮助"
        exit 1
        ;;
esac
