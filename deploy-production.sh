#!/bin/bash

# GMGN 生产环境部署脚本
# 版本: 2.0
# 作者: AI Assistant

set -e # 遇到错误立即退出

# 配置变量
APP_NAME="gmgn-app"
APP_DIR="/home/project/gmgn-clone"
BACKUP_DIR="/home/project/backups"
LOG_FILE="/var/log/deploy.log"
HEALTH_CHECK_URL="http://localhost:3000"
MAX_DEPLOY_TIME=300 # 5分钟超时

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# 检查必要条件
check_prerequisites() {
    log "检查部署前置条件..."

    # 检查Node.js版本
    if ! command -v node &> /dev/null; then
        error "Node.js 未安装"
        exit 1
    fi

    local node_version=$(node --version | cut -d 'v' -f 2 | cut -d '.' -f 1)
    if [ $node_version -lt 18 ]; then
        error "Node.js 版本过低，需要 >= 18.0.0"
        exit 1
    fi

    # 检查PM2
    if ! command -v pm2 &> /dev/null; then
        error "PM2 未安装"
        exit 1
    fi

    # 检查Bun
    if ! command -v bun &> /dev/null; then
        error "Bun 未安装"
        exit 1
    fi

    # 检查目录权限
    if [ ! -w "$APP_DIR" ]; then
        error "应用目录无写权限: $APP_DIR"
        exit 1
    fi

    log "前置条件检查通过"
}

# 创建备份
create_backup() {
    log "创建备份..."

    local backup_name="gmgn-backup-$(date +%Y%m%d-%H%M%S)"
    local backup_path="$BACKUP_DIR/$backup_name"

    mkdir -p $BACKUP_DIR

    if [ -d "$APP_DIR/.next" ]; then
        cp -r $APP_DIR $backup_path
        log "备份创建成功: $backup_path"
        echo $backup_path > /tmp/gmgn_last_backup
    else
        warning "没有找到现有构建文件，跳过备份"
    fi
}

# 安装依赖
install_dependencies() {
    log "安装生产依赖..."

    cd $APP_DIR

    # 清理缓存
    bun pm cache clean || true
    rm -rf node_modules/.cache || true

    # 安装依赖
    if ! timeout 180 bun install --frozen-lockfile --production=false; then
        error "依赖安装失败"
        return 1
    fi

    log "依赖安装完成"
}

# 构建应用
build_application() {
    log "构建生产版本..."

    cd $APP_DIR

    # 设置生产环境变量
    export NODE_ENV=production
    export NEXT_TELEMETRY_DISABLED=1

    # 清理旧构建
    rm -rf .next

    # 构建应用
    if ! timeout 240 bun run build; then
        error "应用构建失败"
        return 1
    fi

    log "应用构建完成"
}

# 更新PM2配置
update_pm2_config() {
    log "更新PM2配置..."

    cd $APP_DIR

    # 停止现有应用（如果运行中）
    pm2 stop $APP_NAME 2>/dev/null || true
    pm2 delete $APP_NAME 2>/dev/null || true

    # 启动应用
    if ! pm2 start ecosystem.config.js --env production; then
        error "PM2启动失败"
        return 1
    fi

    # 保存PM2配置
    pm2 save
    pm2 startup ubuntu -u root --hp /root 2>/dev/null || true

    log "PM2配置更新完成"
}

# 健康检查
health_check() {
    log "执行健康检查..."

    local start_time=$(date +%s)
    local timeout_time=$((start_time + MAX_DEPLOY_TIME))

    while [ $(date +%s) -lt $timeout_time ]; do
        if curl -sf $HEALTH_CHECK_URL > /dev/null 2>&1; then
            log "健康检查通过"
            return 0
        fi

        log "等待应用启动..."
        sleep 10
    done

    error "健康检查失败 - 应用启动超时"
    return 1
}

# 回滚
rollback() {
    log "开始回滚..."

    if [ -f "/tmp/gmgn_last_backup" ]; then
        local backup_path=$(cat /tmp/gmgn_last_backup)
        if [ -d "$backup_path" ]; then
            pm2 stop $APP_NAME 2>/dev/null || true
            rm -rf $APP_DIR
            cp -r $backup_path $APP_DIR
            pm2 start ecosystem.config.js --env production
            log "回滚完成"
        else
            error "备份文件不存在，无法回滚"
        fi
    else
        error "没有可用的备份，无法回滚"
    fi
}

# 清理
cleanup() {
    log "清理临时文件..."

    # 保留最近5个备份
    if [ -d "$BACKUP_DIR" ]; then
        cd $BACKUP_DIR
        ls -t | tail -n +6 | xargs -r rm -rf
    fi

    # 清理日志
    if [ -f "$LOG_FILE" ] && [ $(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE") -gt 10485760 ]; then
        tail -n 1000 $LOG_FILE > ${LOG_FILE}.tmp
        mv ${LOG_FILE}.tmp $LOG_FILE
    fi

    log "清理完成"
}

# 显示部署信息
show_deploy_info() {
    log "=== 部署完成 ==="
    log "应用名称: $APP_NAME"
    log "应用目录: $APP_DIR"
    log "访问地址: $HEALTH_CHECK_URL"
    log "PM2状态:"
    pm2 list
    log "=================="
}

# 主部署流程
main() {
    log "开始GMGN生产环境部署..."

    # 创建必要目录
    mkdir -p /var/log/pm2
    mkdir -p $BACKUP_DIR

    # 执行部署步骤
    if ! check_prerequisites; then
        error "前置条件检查失败"
        exit 1
    fi

    create_backup

    if ! install_dependencies; then
        error "依赖安装失败"
        rollback
        exit 1
    fi

    if ! build_application; then
        error "应用构建失败"
        rollback
        exit 1
    fi

    if ! update_pm2_config; then
        error "PM2配置失败"
        rollback
        exit 1
    fi

    if ! health_check; then
        error "健康检查失败"
        rollback
        exit 1
    fi

    cleanup
    show_deploy_info

    log "GMGN生产环境部署成功完成！"
}

# 脚本入口
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "rollback")
        rollback
        ;;
    "health")
        health_check
        ;;
    "cleanup")
        cleanup
        ;;
    *)
        echo "用法: $0 {deploy|rollback|health|cleanup}"
        echo "  deploy  - 执行完整部署流程"
        echo "  rollback - 回滚到上一个版本"
        echo "  health  - 执行健康检查"
        echo "  cleanup - 清理临时文件"
        exit 1
        ;;
esac
