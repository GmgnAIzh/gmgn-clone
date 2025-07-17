#!/bin/bash

# GMGN 健康检查脚本
# 版本: 1.0

set -e

# 配置
APP_NAME="gmgn-app"
HEALTH_URL="http://localhost:3000"
ALERT_EMAIL="admin@yourdomain.com"
LOG_FILE="/var/log/gmgn-health.log"
MEMORY_THRESHOLD=80  # 内存使用率阈值 (%)
CPU_THRESHOLD=90     # CPU使用率阈值 (%)
RESPONSE_THRESHOLD=5000  # 响应时间阈值 (ms)

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 日志函数
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a $LOG_FILE
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a $LOG_FILE
}

warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a $LOG_FILE
}

# 发送告警
send_alert() {
    local subject="$1"
    local message="$2"

    # 发送邮件告警 (需要配置邮件服务)
    if command -v mail &> /dev/null; then
        echo "$message" | mail -s "$subject" $ALERT_EMAIL
    fi

    # 写入系统日志
    logger -p user.err "GMGN Alert: $subject - $message"

    error "ALERT: $subject - $message"
}

# 检查进程状态
check_process() {
    log "检查应用进程状态..."

    local pm2_status=$(pm2 jlist | jq -r ".[] | select(.name==\"$APP_NAME\") | .pm2_env.status" 2>/dev/null || echo "stopped")

    if [ "$pm2_status" != "online" ]; then
        send_alert "应用进程异常" "应用 $APP_NAME 状态: $pm2_status"
        return 1
    fi

    log "进程状态正常: $pm2_status"
    return 0
}

# 检查HTTP响应
check_http_response() {
    log "检查HTTP响应..."

    local start_time=$(date +%s%N)
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 $HEALTH_URL 2>/dev/null || echo "000")
    local end_time=$(date +%s%N)
    local response_time=$(( (end_time - start_time) / 1000000 ))  # 转换为毫秒

    if [ "$http_code" != "200" ]; then
        send_alert "HTTP响应异常" "HTTP状态码: $http_code, URL: $HEALTH_URL"
        return 1
    fi

    if [ $response_time -gt $RESPONSE_THRESHOLD ]; then
        warning "响应时间过长: ${response_time}ms (阈值: ${RESPONSE_THRESHOLD}ms)"
    else
        log "HTTP响应正常: ${http_code}, 响应时间: ${response_time}ms"
    fi

    return 0
}

# 检查内存使用率
check_memory_usage() {
    log "检查内存使用率..."

    # 获取应用内存使用情况
    local app_memory=$(pm2 jlist | jq -r ".[] | select(.name==\"$APP_NAME\") | .monit.memory" 2>/dev/null || echo "0")
    local app_memory_mb=$(( app_memory / 1024 / 1024 ))

    # 获取系统内存使用情况
    local mem_info=$(free | grep Mem)
    local total_mem=$(echo $mem_info | awk '{print $2}')
    local used_mem=$(echo $mem_info | awk '{print $3}')
    local mem_usage=$(( used_mem * 100 / total_mem ))

    log "应用内存使用: ${app_memory_mb}MB, 系统内存使用: ${mem_usage}%"

    if [ $mem_usage -gt $MEMORY_THRESHOLD ]; then
        warning "系统内存使用率过高: ${mem_usage}% (阈值: ${MEMORY_THRESHOLD}%)"
    fi

    # 检查应用内存是否超过1GB
    if [ $app_memory_mb -gt 1024 ]; then
        warning "应用内存使用过高: ${app_memory_mb}MB"
    fi

    return 0
}

# 检查CPU使用率
check_cpu_usage() {
    log "检查CPU使用率..."

    # 获取应用CPU使用情况
    local app_cpu=$(pm2 jlist | jq -r ".[] | select(.name==\"$APP_NAME\") | .monit.cpu" 2>/dev/null || echo "0")

    # 获取系统CPU使用情况
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')

    log "应用CPU使用: ${app_cpu}%, 系统CPU使用: ${cpu_usage}%"

    if (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l) )); then
        warning "系统CPU使用率过高: ${cpu_usage}% (阈值: ${CPU_THRESHOLD}%)"
    fi

    return 0
}

# 检查磁盘空间
check_disk_space() {
    log "检查磁盘空间..."

    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

    log "磁盘使用率: ${disk_usage}%"

    if [ $disk_usage -gt 85 ]; then
        warning "磁盘使用率过高: ${disk_usage}%"

        # 清理日志文件
        find /var/log -name "*.log" -mtime +7 -exec rm {} \;
        find /home/project/gmgn-clone/.next -name "*.log" -mtime +3 -exec rm {} \;
    fi

    return 0
}

# 检查错误日志
check_error_logs() {
    log "检查错误日志..."

    local error_log="/var/log/pm2/gmgn-error.log"

    if [ -f "$error_log" ]; then
        local recent_errors=$(tail -n 100 $error_log | grep -E "(ERROR|FATAL|Exception)" | wc -l)

        if [ $recent_errors -gt 10 ]; then
            warning "发现 $recent_errors 个最近错误"
        else
            log "错误日志检查正常"
        fi
    fi

    return 0
}

# 生成状态报告
generate_status_report() {
    local status_file="/tmp/gmgn-status.json"

    cat > $status_file << EOF
{
    "timestamp": "$(date -Iseconds)",
    "app_name": "$APP_NAME",
    "process_status": "$(pm2 jlist | jq -r ".[] | select(.name==\"$APP_NAME\") | .pm2_env.status" 2>/dev/null || echo "unknown")",
    "uptime": "$(pm2 jlist | jq -r ".[] | select(.name==\"$APP_NAME\") | .pm2_env.pm_uptime" 2>/dev/null || echo "0")",
    "restarts": "$(pm2 jlist | jq -r ".[] | select(.name==\"$APP_NAME\") | .pm2_env.restart_time" 2>/dev/null || echo "0")",
    "memory_mb": $(( $(pm2 jlist | jq -r ".[] | select(.name==\"$APP_NAME\") | .monit.memory" 2>/dev/null || echo "0") / 1024 / 1024 )),
    "cpu_percent": $(pm2 jlist | jq -r ".[] | select(.name==\"$APP_NAME\") | .monit.cpu" 2>/dev/null || echo "0"),
    "system_memory_percent": $(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}'),
    "disk_usage_percent": $(df -h / | awk 'NR==2 {print $5}' | sed 's/%//'),
    "health_check_passed": true
}
EOF

    log "状态报告已生成: $status_file"
}

# 自动恢复
auto_recovery() {
    log "尝试自动恢复..."

    # 重启应用
    pm2 restart $APP_NAME

    sleep 10

    # 再次检查
    if check_http_response; then
        log "自动恢复成功"
        return 0
    else
        error "自动恢复失败"
        return 1
    fi
}

# 主检查函数
main_check() {
    log "开始健康检查..."

    local check_passed=true

    # 执行各项检查
    if ! check_process; then
        check_passed=false
    fi

    if ! check_http_response; then
        check_passed=false
        # 尝试自动恢复
        if auto_recovery; then
            check_passed=true
        fi
    fi

    check_memory_usage
    check_cpu_usage
    check_disk_space
    check_error_logs

    # 生成状态报告
    generate_status_report

    if [ "$check_passed" = true ]; then
        log "健康检查通过"
        return 0
    else
        error "健康检查失败"
        return 1
    fi
}

# 脚本入口
case "${1:-check}" in
    "check")
        main_check
        ;;
    "process")
        check_process
        ;;
    "http")
        check_http_response
        ;;
    "memory")
        check_memory_usage
        ;;
    "cpu")
        check_cpu_usage
        ;;
    "disk")
        check_disk_space
        ;;
    "logs")
        check_error_logs
        ;;
    "report")
        generate_status_report && cat /tmp/gmgn-status.json
        ;;
    *)
        echo "用法: $0 {check|process|http|memory|cpu|disk|logs|report}"
        echo "  check   - 执行完整健康检查"
        echo "  process - 检查进程状态"
        echo "  http    - 检查HTTP响应"
        echo "  memory  - 检查内存使用"
        echo "  cpu     - 检查CPU使用"
        echo "  disk    - 检查磁盘空间"
        echo "  logs    - 检查错误日志"
        echo "  report  - 生成状态报告"
        exit 1
        ;;
esac
