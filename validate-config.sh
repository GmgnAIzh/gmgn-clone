#!/bin/bash

# GMGN 配置验证和优化工具
# 版本: 1.0
# 功能: 验证服务器配置并提供优化建议

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 配置文件路径
CONFIG_FILE="server-config.json"
TEMPLATES_FILE="server-templates.json"

# 验证结果
VALIDATION_PASSED=true
WARNINGS=()
ERRORS=()
RECOMMENDATIONS=()

# 日志函数
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    WARNINGS+=("$1")
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    ERRORS+=("$1")
    VALIDATION_PASSED=false
}

recommend() {
    echo -e "${CYAN}[RECOMMEND]${NC} $1"
    RECOMMENDATIONS+=("$1")
}

# 显示标题
show_header() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║               GMGN 配置验证和优化工具                         ║"
    echo "║          检查配置合理性并提供优化建议                          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
}

# 检查配置文件是否存在
check_config_exists() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        error "配置文件不存在: $CONFIG_FILE"
        info "请先运行 ./configure-server.sh 生成配置文件"
        exit 1
    fi

    if [[ ! -f "$TEMPLATES_FILE" ]]; then
        warn "模板文件不存在: $TEMPLATES_FILE，将跳过模板对比"
    fi

    log "配置文件检查通过"
}

# 读取配置
read_config() {
    if ! command -v jq &> /dev/null; then
        error "需要安装 jq 工具来解析 JSON 配置"
        info "安装命令: apt install jq 或 yum install jq"
        exit 1
    fi

    # 读取系统配置
    CPU_CORES=$(jq -r '.system.cpu_cores' $CONFIG_FILE)
    TOTAL_MEMORY=$(jq -r '.system.total_memory' $CONFIG_FILE)
    AVAILABLE_MEMORY=$(jq -r '.system.available_memory' $CONFIG_FILE)

    # 读取项目配置
    PROJECT_NAME=$(jq -r '.project.name' $CONFIG_FILE)
    APP_PORT=$(jq -r '.project.app_port' $CONFIG_FILE)

    # 读取性能配置
    PM2_INSTANCES=$(jq -r '.performance.pm2_instances' $CONFIG_FILE)
    NODE_HEAP_SIZE=$(jq -r '.performance.node_heap_size' $CONFIG_FILE)

    # 读取监控配置
    HEALTH_CHECK_INTERVAL=$(jq -r '.monitoring.health_check_interval' $CONFIG_FILE)
    MEMORY_THRESHOLD=$(jq -r '.monitoring.memory_threshold' $CONFIG_FILE)
    CPU_THRESHOLD=$(jq -r '.monitoring.cpu_threshold' $CONFIG_FILE)

    log "配置读取完成"
}

# 验证硬件配置
validate_hardware() {
    log "验证硬件配置..."

    # 检查CPU核心数
    if [[ $CPU_CORES -lt 1 ]]; then
        error "无效的CPU核心数: $CPU_CORES"
    elif [[ $CPU_CORES -eq 1 ]]; then
        warn "单核CPU可能影响应用性能"
        recommend "考虑升级到至少2核心的服务器"
    fi

    # 检查内存大小
    if [[ $TOTAL_MEMORY -lt 1024 ]]; then
        error "内存不足: ${TOTAL_MEMORY}MB，至少需要1GB"
    elif [[ $TOTAL_MEMORY -lt 2048 ]]; then
        warn "内存较小: ${TOTAL_MEMORY}MB，建议至少2GB"
        recommend "考虑增加内存以提高性能"
    fi

    # 检查可用内存
    local memory_usage_percent=$((100 - (AVAILABLE_MEMORY * 100 / TOTAL_MEMORY)))
    if [[ $memory_usage_percent -gt 80 ]]; then
        warn "系统内存使用率过高: ${memory_usage_percent}%"
        recommend "清理系统内存或增加内存容量"
    fi

    info "硬件配置检查完成"
}

# 验证PM2配置
validate_pm2_config() {
    log "验证PM2配置..."

    # 检查实例数配置
    if [[ $PM2_INSTANCES -gt $CPU_CORES ]]; then
        warn "PM2实例数($PM2_INSTANCES)超过CPU核心数($CPU_CORES)"
        recommend "将PM2实例数调整为CPU核心数或更少"
    elif [[ $PM2_INSTANCES -eq 0 ]]; then
        error "PM2实例数不能为0"
    fi

    # 检查Node.js堆大小
    local heap_memory_percent=$((NODE_HEAP_SIZE * 100 / TOTAL_MEMORY))
    if [[ $heap_memory_percent -gt 60 ]]; then
        warn "Node.js堆大小占用内存过多: ${heap_memory_percent}%"
        recommend "减少Node.js堆大小以留出系统内存"
    elif [[ $heap_memory_percent -lt 25 ]]; then
        recommend "可以适当增加Node.js堆大小以提高性能"
    fi

    # 检查总内存使用
    local total_heap_memory=$((PM2_INSTANCES * NODE_HEAP_SIZE))
    local total_memory_percent=$((total_heap_memory * 100 / TOTAL_MEMORY))
    if [[ $total_memory_percent -gt 80 ]]; then
        error "所有PM2实例总内存使用超过80%: ${total_memory_percent}%"
        recommend "减少PM2实例数或Node.js堆大小"
    fi

    info "PM2配置检查完成"
}

# 验证监控配置
validate_monitoring_config() {
    log "验证监控配置..."

    # 检查健康检查间隔
    if [[ $HEALTH_CHECK_INTERVAL -lt 1 ]]; then
        error "健康检查间隔不能小于1分钟"
    elif [[ $HEALTH_CHECK_INTERVAL -gt 30 ]]; then
        warn "健康检查间隔过长: ${HEALTH_CHECK_INTERVAL}分钟"
        recommend "建议将健康检查间隔设置在5-10分钟之间"
    fi

    # 检查内存阈值
    if [[ $MEMORY_THRESHOLD -lt 50 || $MEMORY_THRESHOLD -gt 95 ]]; then
        warn "内存告警阈值设置不合理: ${MEMORY_THRESHOLD}%"
        recommend "建议将内存告警阈值设置在70-90%之间"
    fi

    # 检查CPU阈值
    if [[ $CPU_THRESHOLD -lt 70 || $CPU_THRESHOLD -gt 99 ]]; then
        warn "CPU告警阈值设置不合理: ${CPU_THRESHOLD}%"
        recommend "建议将CPU告警阈值设置在80-95%之间"
    fi

    info "监控配置检查完成"
}

# 验证端口配置
validate_port_config() {
    log "验证端口配置..."

    # 检查端口范围
    if [[ $APP_PORT -lt 1024 ]]; then
        warn "使用系统端口($APP_PORT)需要root权限"
    elif [[ $APP_PORT -gt 65535 ]]; then
        error "端口号超出有效范围: $APP_PORT"
    fi

    # 检查端口是否被占用
    if command -v netstat &> /dev/null; then
        if netstat -tlnp 2>/dev/null | grep -q ":$APP_PORT "; then
            warn "端口 $APP_PORT 可能已被占用"
            recommend "检查端口占用情况或选择其他端口"
        fi
    fi

    info "端口配置检查完成"
}

# 验证配置文件语法
validate_config_files() {
    log "验证配置文件语法..."

    # 检查ecosystem.config.js
    if [[ -f "ecosystem.config.js" ]]; then
        if node -c ecosystem.config.js 2>/dev/null; then
            info "✓ ecosystem.config.js 语法正确"
        else
            error "✗ ecosystem.config.js 语法错误"
        fi
    else
        warn "ecosystem.config.js 文件不存在"
    fi

    # 检查nginx.conf
    if [[ -f "nginx.conf" ]]; then
        if command -v nginx &> /dev/null; then
            if nginx -t -c $(pwd)/nginx.conf 2>/dev/null; then
                info "✓ nginx.conf 语法正确"
            else
                error "✗ nginx.conf 语法错误"
            fi
        else
            warn "nginx 未安装，跳过语法检查"
        fi
    else
        warn "nginx.conf 文件不存在"
    fi

    # 检查.env.production
    if [[ -f ".env.production" ]]; then
        if grep -q "NODE_ENV=production" .env.production; then
            info "✓ .env.production 配置正确"
        else
            warn "✗ .env.production 缺少必要配置"
        fi
    else
        warn ".env.production 文件不存在"
    fi

    info "配置文件语法检查完成"
}

# 性能优化建议
generate_performance_recommendations() {
    log "生成性能优化建议..."

    # 基于服务器规模的建议
    if [[ $TOTAL_MEMORY -lt 2048 ]]; then
        recommend "小型服务器优化建议："
        recommend "  - 使用单个PM2实例减少内存开销"
        recommend "  - 启用Nginx压缩减少带宽使用"
        recommend "  - 定期清理日志文件"
        recommend "  - 考虑使用轻量级数据库如SQLite"
    elif [[ $TOTAL_MEMORY -lt 8192 ]]; then
        recommend "中型服务器优化建议："
        recommend "  - 使用PM2集群模式提高并发处理"
        recommend "  - 配置Redis缓存加速数据访问"
        recommend "  - 启用HTTP/2提高传输效率"
        recommend "  - 配置CDN加速静态资源"
    else
        recommend "大型服务器优化建议："
        recommend "  - 使用最大PM2实例数充分利用CPU"
        recommend "  - 配置分布式缓存集群"
        recommend "  - 使用负载均衡器分发请求"
        recommend "  - 启用数据库读写分离"
        recommend "  - 考虑微服务架构"
    fi

    # 基于CPU核心数的建议
    if [[ $CPU_CORES -ge 4 ]]; then
        recommend "多核CPU优化建议："
        recommend "  - 启用worker进程并行处理"
        recommend "  - 使用CPU密集型任务队列"
        recommend "  - 配置异步I/O操作"
    fi

    info "性能优化建议生成完成"
}

# 安全配置检查
validate_security_config() {
    log "检查安全配置..."

    # 检查是否使用root用户
    local run_user=$(jq -r '.project.run_user' $CONFIG_FILE 2>/dev/null || echo "root")
    if [[ "$run_user" == "root" ]]; then
        warn "使用root用户运行应用存在安全风险"
        recommend "创建专用用户运行应用程序"
    fi

    # 检查SSL配置
    local use_ssl=$(jq -r '.domain.use_ssl' $CONFIG_FILE 2>/dev/null || echo "n")
    if [[ "$use_ssl" != "y" ]]; then
        warn "未启用SSL加密"
        recommend "启用HTTPS保护数据传输安全"
    fi

    # 检查防火墙配置
    if command -v ufw &> /dev/null; then
        if ufw status | grep -q "Status: inactive"; then
            warn "防火墙未启用"
            recommend "启用防火墙并配置必要的端口规则"
        fi
    elif command -v firewall-cmd &> /dev/null; then
        if ! systemctl is-active --quiet firewalld; then
            warn "防火墙未启用"
            recommend "启用firewalld并配置安全规则"
        fi
    fi

    info "安全配置检查完成"
}

# 生成配置报告
generate_report() {
    local report_file="config-validation-report.md"

    log "生成配置验证报告..."

    cat > $report_file << EOF
# GMGN 配置验证报告

生成时间: $(date)
配置文件: $CONFIG_FILE

## 📊 系统信息

- **CPU核心数**: $CPU_CORES
- **总内存**: ${TOTAL_MEMORY}MB
- **可用内存**: ${AVAILABLE_MEMORY}MB
- **项目名称**: $PROJECT_NAME
- **运行端口**: $APP_PORT

## ⚙️ 性能配置

- **PM2实例数**: $PM2_INSTANCES
- **Node.js堆大小**: ${NODE_HEAP_SIZE}MB
- **健康检查间隔**: ${HEALTH_CHECK_INTERVAL}分钟
- **内存告警阈值**: ${MEMORY_THRESHOLD}%
- **CPU告警阈值**: ${CPU_THRESHOLD}%

## ✅ 验证结果

EOF

    if [[ $VALIDATION_PASSED == true ]]; then
        echo "**状态**: ✅ 配置验证通过" >> $report_file
    else
        echo "**状态**: ❌ 配置验证失败" >> $report_file
    fi

    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        echo "" >> $report_file
        echo "### ❌ 错误列表" >> $report_file
        echo "" >> $report_file
        for error in "${ERRORS[@]}"; do
            echo "- $error" >> $report_file
        done
    fi

    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        echo "" >> $report_file
        echo "### ⚠️ 警告列表" >> $report_file
        echo "" >> $report_file
        for warning in "${WARNINGS[@]}"; do
            echo "- $warning" >> $report_file
        done
    fi

    if [[ ${#RECOMMENDATIONS[@]} -gt 0 ]]; then
        echo "" >> $report_file
        echo "### 💡 优化建议" >> $report_file
        echo "" >> $report_file
        for recommendation in "${RECOMMENDATIONS[@]}"; do
            echo "- $recommendation" >> $report_file
        done
    fi

    cat >> $report_file << EOF

## 📋 配置文件清单

- [ ] ecosystem.config.js - PM2配置
- [ ] nginx.conf - Nginx配置
- [ ] .env.production - 环境变量
- [ ] health-check.sh - 健康检查脚本
- [ ] deploy-production.sh - 部署脚本

## 🚀 下一步操作

1. 修复所有错误项
2. 根据警告调整配置
3. 实施优化建议
4. 重新运行验证工具
5. 执行部署流程

---
*本报告由 GMGN 配置验证工具自动生成*
EOF

    info "配置验证报告已生成: $report_file"
}

# 显示验证结果
show_validation_result() {
    echo
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    if [[ $VALIDATION_PASSED == true ]]; then
        echo -e "${CYAN}║${GREEN}                   ✅ 配置验证通过！                        ${CYAN}║${NC}"
    else
        echo -e "${CYAN}║${RED}                   ❌ 配置验证失败！                        ${CYAN}║${NC}"
    fi
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo

    # 显示统计信息
    info "验证统计:"
    echo "  错误: ${#ERRORS[@]} 个"
    echo "  警告: ${#WARNINGS[@]} 个"
    echo "  建议: ${#RECOMMENDATIONS[@]} 个"

    if [[ $VALIDATION_PASSED == true ]]; then
        echo
        log "🎉 配置已优化，可以开始部署！"
        info "运行部署命令: ./deploy-production.sh"
    else
        echo
        error "⚠️ 请修复错误后重新验证"
        info "运行配置工具: ./configure-server.sh"
    fi
}

# 主验证流程
main() {
    show_header
    check_config_exists
    read_config

    log "开始配置验证..."
    echo

    validate_hardware
    validate_pm2_config
    validate_monitoring_config
    validate_port_config
    validate_config_files
    validate_security_config
    generate_performance_recommendations

    echo
    generate_report
    show_validation_result
}

# 脚本入口
case "${1:-validate}" in
    "validate"|"")
        main
        ;;
    "quick")
        # 快速验证 - 只检查关键配置
        check_config_exists
        read_config
        validate_hardware
        validate_pm2_config
        show_validation_result
        ;;
    "report")
        # 只生成报告
        if [[ -f "config-validation-report.md" ]]; then
            cat config-validation-report.md
        else
            error "报告文件不存在，请先运行验证"
        fi
        ;;
    "help"|"-h"|"--help")
        echo "GMGN 配置验证工具"
        echo
        echo "用法: $0 [选项]"
        echo
        echo "选项:"
        echo "  validate  完整验证 (默认)"
        echo "  quick     快速验证"
        echo "  report    显示最新报告"
        echo "  help      显示帮助信息"
        ;;
    *)
        error "未知参数: $1"
        echo "使用 $0 help 查看帮助"
        exit 1
        ;;
esac
