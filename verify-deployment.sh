#!/bin/bash

# GMGN 部署完整性一键检测脚本
# 版本: 1.1
# 功能: 验证服务器环境、应用配置和运行状态

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 状态变量
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# --- Helper Functions ---
print_header() {
    echo -e "${CYAN}"
    echo "=================================================================="
    echo "    GMGN 部署完整性检测 - $1"
    echo "=================================================================="
    echo -e "${NC}"
}

check_result() {
    ((TOTAL_CHECKS++))
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ OK${NC}: $1"
        ((PASSED_CHECKS++))
    else
        echo -e "${RED}✗ FAILED${NC}: $2"
        echo -e "${YELLOW}  ↳ 修复建议: $3${NC}"
        ((FAILED_CHECKS++))
    fi
}

# --- Check Functions ---

check_os() {
    print_header "1. 操作系统"
    grep -q "Ubuntu 24.04" /etc/os-release
    check_result "操作系统为 Ubuntu 24.04" "操作系统不匹配" "脚本专为 Ubuntu 24.04 优化, 其他系统可能需要调整。"
}

check_nodejs() {
    print_header "2. Node.js 环境"

    command -v node &> /dev/null
    check_result "Node.js 已安装" "Node.js 未安装" "运行 one-click-deploy.sh 或 deploy-hk.sh 脚本重新安装。"

    if command -v node &> /dev/null; then
        local node_version=$(node -v)
        [[ "$node_version" == v18* ]]
        check_result "Node.js 版本为 v18.x.x (当前: $node_version)" "Node.js 版本不正确 (需要 v18)" "请卸载当前版本并安装 Node.js v18。"
    fi
}

check_pm2() {
    print_header "3. PM2 进程管理器"

    command -v pm2 &> /dev/null
    check_result "PM2 已安装" "PM2 未安装" "执行 npm install -g pm2 安装。"

    if command -v pm2 &> /dev/null; then
        pm2 jlist | jq -e '.[] | select(.name=="gmgn-app")' &> /dev/null
        check_result "PM2 中存在 gmgn-app 应用" "gmgn-app 未在 PM2 中运行" "进入项目目录执行 pm2 start ecosystem.config.js"

        local status=$(pm2 jlist | jq -r '.[] | select(.name=="gmgn-app") | .pm2_env.status' 2>/dev/null)
        [ "$status" == "online" ]
        check_result "gmgn-app 状态为 online (当前: $status)" "gmgn-app 状态异常" "执行 pm2 logs gmgn-app 查看错误日志并重启。"

        local instances=$(pm2 jlist | jq -r '[.[] | select(.name=="gmgn-app")] | length' 2>/dev/null)
        [ "$instances" -eq 3 ]
        check_result "PM2 实例数为 3 (当前: $instances)" "PM2 实例数不符合优化配置" "执行 pm2 scale gmgn-app 3"
    fi
}

check_nginx() {
    print_header "4. Nginx 反向代理"

    systemctl is-active --quiet nginx
    check_result "Nginx 服务正在运行" "Nginx 服务未运行" "执行 systemctl start nginx && systemctl enable nginx"

    nginx -t &> /dev/null
    check_result "Nginx 配置文件语法正确" "Nginx 配置文件错误" "执行 nginx -t 查看详细错误信息并修复。"

    grep -q "proxy_pass http://gmgn_backend" /etc/nginx/sites-enabled/gmgn 2>/dev/null || grep -q "proxy_pass http://127.0.0.1:3000" /etc/nginx/nginx.conf
    check_result "Nginx 已配置到上游应用" "Nginx 未配置反向代理" "请检查 /etc/nginx/sites-available/gmgn 或 nginx-hk.conf 是否正确。"
}

check_firewall() {
    print_header "5. 防火墙配置"

    if command -v ufw &> /dev/null; then
        ufw status | grep -q "Status: active"
        check_result "UFW 防火墙已启用" "UFW 防火墙未启用" "执行 ufw enable"

        ufw status | grep -q "80/tcp"
        check_result "端口 80 (HTTP) 已开放" "端口 80 未开放" "执行 ufw allow 80/tcp"

        ufw status | grep -q "3000/tcp"
        check_result "端口 3000 (Node.js) 已开放" "端口 3000 未开放" "执行 ufw allow 3000/tcp"
    else
        echo -e "${YELLOW}i SKIPPED${NC}: UFW not found, assuming other firewall is used."
    fi
}

check_app_health() {
    print_header "6. 应用健康状态"

    curl -s --max-time 5 http://localhost:3000 &> /dev/null
    check_result "本地应用端口 3000 响应正常" "本地应用端口 3000 无响应" "检查 PM2 日志排查应用启动失败原因。"

    local status_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80)
    [[ "$status_code" =~ ^(200|301|302)$ ]]
    check_result "通过 Nginx 访问应用正常 (HTTP Code: $status_code)" "通过 Nginx 访问应用失败" "检查 Nginx 日志 /var/log/nginx/gmgn-error.log"
}

check_system_optimization() {
    print_header "7. 香港地域系统优化"

    sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"
    check_result "TCP BBR 拥塞控制已启用" "TCP BBR 未启用" "检查 /etc/sysctl.conf 配置并执行 sysctl -p"

    timedatectl | grep -q "Asia/Hong_Kong"
    check_result "系统时区为 Asia/Hong_Kong" "系统时区不正确" "执行 timedatectl set-timezone Asia/Hong_Kong"
}

print_summary() {
    echo
    echo "=================================================================="
    print_header "检测完成"
    echo -e "  ${CYAN}总计检查项: $TOTAL_CHECKS${NC}"
    echo -e "  ${GREEN}通过: $PASSED_CHECKS${NC}"
    echo -e "  ${RED}失败: $FAILED_CHECKS${NC}"
    echo "=================================================================="
    echo

    if [ $FAILED_CHECKS -eq 0 ]; then
        echo -e "${GREEN}🎉 恭喜！您的服务器部署非常完整，所有关键配置均已生效。${NC}"
        echo -e "${CYAN}您的GMGN应用正在最佳状态下运行！${NC}"
    else
        echo -e "${RED}⚠️ 检测到 $FAILED_CHECKS 个问题。${NC}"
        echo -e "${YELLOW}请根据上面的修复建议逐一排查，以确保应用稳定运行。${NC}"
    fi
    echo
}


# --- Main Execution ---
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}请使用 root 用户运行此脚本。${NC}"
    exit 1
fi

clear
check_os
check_nodejs
check_pm2
check_nginx
check_firewall
check_app_health
check_system_optimization
print_summary
