# GMGN 生产环境部署文档

## 📋 概述

这是GMGN交易平台的完整生产环境部署文档。包含了从环境准备到上线运维的全流程指南。

## 🎯 部署架构

```
用户请求 → Nginx (反向代理/SSL) → Node.js/Next.js 应用 → CoinGecko API
                ↓
           PM2 (进程管理) → 健康检查/监控
```

## 🔧 系统要求

### 最低配置
- **CPU**: 2核心
- **内存**: 4GB RAM
- **存储**: 20GB SSD
- **操作系统**: Ubuntu 20.04+ / CentOS 8+
- **网络**: 公网IP（域名部署时）

### 推荐配置
- **CPU**: 4核心+
- **内存**: 8GB+ RAM
- **存储**: 50GB+ SSD
- **操作系统**: Ubuntu 22.04 LTS

## 🚀 快速部署

### 方法一：一键部署（推荐）

```bash
# 下载并运行一键部署脚本
chmod +x one-click-deploy.sh

# 本地部署（localhost）
./one-click-deploy.sh

# 域名部署
./one-click-deploy.sh your-domain.com admin@gmail.com
```

### 方法二：手动部署

#### 1. 环境准备

```bash
# 更新系统
apt update && apt upgrade -y

# 安装基础依赖
apt install -y curl wget git unzip jq bc nginx
```

#### 2. 安装Node.js 18

```bash
# 添加Node.js源
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -

# 安装Node.js
apt install -y nodejs

# 验证安装
node --version  # 应该是 v18.x.x
```

#### 3. 安装Bun

```bash
# 安装Bun
curl -fsSL https://bun.sh/install | bash
export PATH="$HOME/.bun/bin:$PATH"
echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.bashrc
```

#### 4. 安装PM2

```bash
# 全局安装PM2
npm install -g pm2@latest

# 设置PM2开机自启
pm2 startup ubuntu -u root --hp /root
```

#### 5. 部署应用

```bash
# 进入项目目录
cd /home/project/gmgn-clone

# 安装依赖
bun install

# 构建生产版本
bun run build

# 启动应用
pm2 start ecosystem.config.js --env production
pm2 save
```

#### 6. 配置Nginx

```bash
# 复制Nginx配置
cp nginx.conf /etc/nginx/sites-available/gmgn

# 启用站点
ln -sf /etc/nginx/sites-available/gmgn /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 测试配置并重启
nginx -t
systemctl reload nginx
```

#### 7. 配置SSL（可选）

```bash
# 安装Certbot
apt install -y certbot python3-certbot-nginx

# 获取SSL证书
certbot --nginx -d your-domain.com --email admin@gmail.com --agree-tos --non-interactive --redirect

# 设置自动续期
echo "0 12 * * * /usr/bin/certbot renew --quiet" | crontab -
```

## 📊 监控和管理

### 管理命令

安装完成后，可以使用以下命令管理应用：

```bash
# 启动应用
gmgn start

# 停止应用
gmgn stop

# 重启应用
gmgn restart

# 查看状态
gmgn status

# 查看日志
gmgn logs

# 重新部署
gmgn deploy

# 健康检查
gmgn health
```

### 手动管理

```bash
# PM2命令
pm2 status          # 查看所有进程状态
pm2 logs gmgn-app   # 查看应用日志
pm2 restart gmgn-app # 重启应用
pm2 reload gmgn-app  # 零停机重启
pm2 stop gmgn-app    # 停止应用
pm2 delete gmgn-app  # 删除进程

# 系统服务
systemctl status nginx    # Nginx状态
systemctl reload nginx    # 重载Nginx配置
systemctl restart nginx   # 重启Nginx
```

### 日志文件位置

```bash
# 应用日志
/var/log/pm2/gmgn-out.log      # 标准输出
/var/log/pm2/gmgn-error.log    # 错误日志
/var/log/pm2/gmgn-combined.log # 合并日志

# Nginx日志
/var/log/nginx/gmgn-access.log # 访问日志
/var/log/nginx/gmgn-error.log  # 错误日志

# 系统日志
/var/log/syslog               # 系统日志
/var/log/gmgn/health.log      # 健康检查日志
```

## 🔍 故障排除

### 常见问题

#### 1. 应用无法启动

```bash
# 检查Node.js版本
node --version

# 检查依赖安装
cd /home/project/gmgn-clone && npm list

# 检查PM2状态
pm2 status

# 查看详细错误
pm2 logs gmgn-app --lines 100
```

#### 2. 网站无法访问

```bash
# 检查应用是否运行
curl http://localhost:3000

# 检查Nginx状态
systemctl status nginx

# 检查防火墙
ufw status
iptables -L

# 检查端口占用
netstat -tlnp | grep :80
netstat -tlnp | grep :443
```

#### 3. SSL证书问题

```bash
# 检查证书状态
certbot certificates

# 手动续期
certbot renew

# 测试Nginx配置
nginx -t
```

#### 4. 性能问题

```bash
# 检查资源使用
pm2 monit

# 检查系统资源
htop
free -h
df -h

# 重启应用
pm2 restart gmgn-app
```

### 错误码含义

| 错误码 | 含义 | 解决方案 |
|--------|------|----------|
| 502 | 网关错误 | 检查应用是否运行，端口是否正确 |
| 503 | 服务不可用 | 检查Nginx配置，重启服务 |
| 504 | 网关超时 | 增加Nginx超时设置 |
| ECONNREFUSED | 连接被拒绝 | 检查应用端口和防火墙 |
| EADDRINUSE | 端口被占用 | 杀死占用进程或更换端口 |

## 📈 性能优化

### PM2集群模式

```javascript
// ecosystem.config.js 中启用集群
module.exports = {
  apps: [{
    name: 'gmgn-app',
    instances: 'max',  // 使用所有CPU核心
    exec_mode: 'cluster'
  }]
}
```

### Nginx缓存优化

```nginx
# 在nginx.conf中添加
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=gmgn_cache:10m max_size=100m;

location /api/ {
    proxy_cache gmgn_cache;
    proxy_cache_valid 200 5m;
}
```

### 内存优化

```bash
# 增加Node.js内存限制
export NODE_OPTIONS="--max-old-space-size=4096"

# PM2配置
pm2 start app.js --node-args="--max-old-space-size=4096"
```

## 🔒 安全配置

### 防火墙设置

```bash
# Ubuntu UFW
ufw enable
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp

# CentOS firewalld
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload
```

### Nginx安全头

```nginx
# 在nginx.conf中添加
add_header X-Frame-Options "DENY" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Strict-Transport-Security "max-age=63072000" always;
```

### 限制访问频率

```nginx
# 限制API访问频率
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;

location /api/ {
    limit_req zone=api burst=20 nodelay;
}
```

## 📋 运维检查清单

### 日常检查

- [ ] 应用状态正常
- [ ] 网站可以正常访问
- [ ] SSL证书有效
- [ ] 系统资源使用率正常
- [ ] 日志无严重错误
- [ ] 备份正常

### 周期维护

- [ ] 更新系统包
- [ ] 更新Node.js依赖
- [ ] 清理日志文件
- [ ] 检查磁盘空间
- [ ] 性能监控报告
- [ ] 安全扫描

### 应急预案

- [ ] 应用自动重启机制
- [ ] 备份恢复流程
- [ ] 回滚部署计划
- [ ] 紧急联系方式
- [ ] 故障上报流程

## 📞 技术支持

### 联系方式

- **技术文档**: 查看项目README.md
- **问题反馈**: 提交GitHub Issue
- **紧急联系**: admin@yourdomain.com

### 有用的链接

- [Next.js 文档](https://nextjs.org/docs)
- [PM2 文档](https://pm2.keymetrics.io/docs/)
- [Nginx 文档](https://nginx.org/en/docs/)
- [CoinGecko API](https://www.coingecko.com/en/api)

---

📝 **注意**: 本文档会持续更新，请定期检查最新版本。
