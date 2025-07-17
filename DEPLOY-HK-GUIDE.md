# GMGN 香港服务器专用部署指南

## 📋 服务器配置概览

**您的服务器配置**:
- **IP地址**: 45.194.37.150
- **CPU**: 4vCPUs
- **内存**: 4GB RAM
- **硬盘**: 50GB SSD
- **带宽**: 5Mbps
- **地域**: 香港云 (HK-CLS0)
- **系统**: Ubuntu 24.04 LTS

## 🎯 针对性优化策略

### 💡 配置分析
- **服务器等级**: 中型云服务器 ⭐⭐⭐
- **性能评估**: 适合中小企业应用
- **并发能力**: 预估支持 1000-2000 用户
- **优化重点**: 带宽效率、内存管理、香港网络

### 🚀 核心优化
1. **CPU优化**: 3个PM2实例 + 1核心预留系统
2. **内存优化**: 1.5GB Node.js堆 + 系统缓存
3. **带宽优化**: Gzip压缩 + 静态资源缓存
4. **地域优化**: 香港时区 + BBR拥塞控制

## 📦 部署包清单

### 🔧 专用配置文件
```
gmgn-clone/
├── deploy-hk.sh              # 香港专用一键部署脚本
├── ecosystem.config.hk.js    # PM2香港优化配置
├── nginx-hk.conf            # Nginx带宽优化配置
├── .env.hk                  # 香港环境变量
├── server-config-custom.json # 定制配置记录
└── DEPLOY-HK-GUIDE.md       # 本部署指南
```

### 📊 性能参数
```json
{
  "pm2_instances": 3,
  "node_heap_size": "1536MB",
  "max_connections": 2000,
  "gzip_level": 6,
  "cache_ttl": "30d",
  "health_check": "5min"
}
```

## 🚀 一键部署

### 方式一：香港专用脚本（推荐）

```bash
# 1. 连接到服务器
ssh root@45.194.37.150

# 2. 上传项目文件到服务器
# (在本地执行)
scp -r gmgn-clone/ root@45.194.37.150:/home/project/

# 3. 在服务器上执行一键部署
cd /home/project/gmgn-clone
chmod +x deploy-hk.sh
./deploy-hk.sh

# 4. 等待部署完成 (约10-15分钟)
# 部署成功后访问: http://45.194.37.150:3000
```

### 方式二：使用通用模板

```bash
# 1. 应用中型服务器模板
./apply-template.sh medium_server

# 2. 手动调整配置参数
./configure-server.sh

# 3. 验证配置
./validate-config.sh

# 4. 执行部署
./deploy-production.sh
```

## 📋 详细部署步骤

### 🔧 1. 系统准备

```bash
# 更新系统
apt update && apt upgrade -y

# 设置香港时区
timedatectl set-timezone Asia/Hong_Kong

# 检查系统资源
free -h && df -h && nproc
```

### 🌐 2. 网络优化

```bash
# 启用BBR拥塞控制
echo 'net.core.default_qdisc=fq' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf
sysctl -p

# 验证BBR启用
lsmod | grep bbr
sysctl net.ipv4.tcp_congestion_control
```

### 🔧 3. 安装Node.js和PM2

```bash
# 安装Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# 配置npm镜像源（加速）
npm config set registry https://registry.npmmirror.com

# 安装PM2
npm install -g pm2@latest
pm2 startup ubuntu -u root --hp /root
```

### 🚀 4. 部署应用

```bash
# 进入项目目录
cd /home/project/gmgn-clone

# 安装依赖
npm install

# 使用香港优化配置
cp ecosystem.config.hk.js ecosystem.config.js
cp .env.hk .env.production

# 构建应用（限制内存使用）
export NODE_OPTIONS="--max-old-space-size=1536"
npm run build

# 启动应用
pm2 start ecosystem.config.js --env production
pm2 save
```

### 🔧 5. 配置Nginx

```bash
# 安装Nginx
apt-get install -y nginx

# 使用香港优化配置
cp nginx-hk.conf /etc/nginx/nginx.conf

# 创建缓存目录
mkdir -p /var/cache/nginx/gmgn
chown -R www-data:www-data /var/cache/nginx

# 测试并启动
nginx -t
systemctl restart nginx
systemctl enable nginx
```

### 🛡️ 6. 配置防火墙

```bash
# 启用UFW
ufw --force enable
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp

# 安装fail2ban
apt-get install -y fail2ban
systemctl enable fail2ban
```

## 📊 性能监控

### 🔍 实时监控

```bash
# 查看应用状态
pm2 status
pm2 monit

# 查看系统资源
htop
iotop

# 查看网络状态
netstat -tlnp
ss -tuln
```

### 📈 性能指标

| 指标 | 目标值 | 当前值 | 状态 |
|------|--------|--------|------|
| CPU使用率 | < 75% | - | 监控中 |
| 内存使用率 | < 80% | - | 监控中 |
| 磁盘使用率 | < 85% | - | 监控中 |
| 响应时间 | < 2s | - | 监控中 |
| 并发连接 | < 2000 | - | 监控中 |

### 🔧 管理命令

```bash
# 应用管理
pm2 status                    # 查看状态
pm2 restart all              # 重启应用
pm2 logs                     # 查看日志
pm2 reload all               # 零停机重启

# Nginx管理
systemctl status nginx       # 查看状态
systemctl reload nginx       # 重载配置
nginx -t                     # 测试配置

# 系统监控
./deploy-hk.sh status        # 查看系统状态
./deploy-hk.sh monitor       # 查看监控日志
```

## 🛠️ 故障排除

### ❌ 常见问题

#### 1. 内存不足
```bash
# 症状：PM2进程频繁重启
# 解决：调整Node.js堆大小
export NODE_OPTIONS="--max-old-space-size=1024"
pm2 restart all
```

#### 2. 带宽瓶颈
```bash
# 症状：页面加载缓慢
# 解决：检查压缩配置
curl -H "Accept-Encoding: gzip" -I http://45.194.37.150:3000
# 应该看到 Content-Encoding: gzip
```

#### 3. 端口冲突
```bash
# 症状：应用启动失败
# 解决：检查端口占用
netstat -tlnp | grep :3000
# 杀死占用进程或更换端口
```

#### 4. 时区问题
```bash
# 症状：日志时间不正确
# 解决：设置正确时区
timedatectl set-timezone Asia/Hong_Kong
systemctl restart rsyslog
```

### 🔧 性能调优

#### CPU优化
```bash
# 如果CPU使用率过高
# 1. 减少PM2实例数
sed -i 's/instances: 3/instances: 2/' ecosystem.config.js
pm2 reload ecosystem.config.js

# 2. 启用cluster模式负载均衡
# 已在配置中启用
```

#### 内存优化
```bash
# 如果内存使用率过高
# 1. 减少Node.js堆大小
export NODE_OPTIONS="--max-old-space-size=1024"

# 2. 启用swap（紧急情况）
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
```

#### 带宽优化
```bash
# 验证压缩效果
curl -H "Accept-Encoding: gzip,deflate,br" -s http://45.194.37.150:3000 | wc -c

# 检查缓存命中率
tail -f /var/log/nginx/gmgn-access.log | grep "X-Cache-Status"
```

## 📈 扩展建议

### 🚀 性能提升
1. **CDN加速**: 使用香港CDN节点
2. **数据库优化**: 配置Redis缓存
3. **负载均衡**: 多服务器部署
4. **监控告警**: 集成钉钉/微信通知

### 🔒 安全加固
1. **SSL证书**: 配置HTTPS加密
2. **WAF防护**: 启用Web应用防火墙
3. **DDoS防护**: 配置流量清洗
4. **日志审计**: 详细访问日志分析

### 💾 备份策略
```bash
# 自动备份脚本
#!/bin/bash
BACKUP_DIR="/home/backup/gmgn"
DATE=$(date +%Y%m%d_%H%M%S)

# 备份应用代码
tar -czf $BACKUP_DIR/app_$DATE.tar.gz /home/project/gmgn-clone

# 备份配置文件
tar -czf $BACKUP_DIR/config_$DATE.tar.gz /etc/nginx /etc/pm2

# 清理旧备份（保留7天）
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
```

## 📞 技术支持

### 🆘 紧急联系
- **服务器商**: 香港云技术支持
- **监控告警**: 配置后自动通知
- **远程协助**: SSH访问 45.194.37.150:22

### 📋 检查清单

#### 部署前检查
- [ ] 服务器资源充足
- [ ] 网络连接正常
- [ ] 防火墙配置正确
- [ ] 域名解析设置（如使用）

#### 部署后验证
- [ ] 应用正常启动
- [ ] HTTP访问正常
- [ ] PM2状态健康
- [ ] Nginx配置正确
- [ ] 监控系统运行

#### 性能验证
- [ ] 内存使用率 < 80%
- [ ] CPU使用率 < 75%
- [ ] 响应时间 < 2秒
- [ ] 压缩功能正常
- [ ] 缓存命中正常

---

## 🎉 部署完成

恭喜！您的GMGN应用已成功部署在香港服务器上。

### 🌐 访问信息
- **应用地址**: http://45.194.37.150:3000
- **服务器IP**: 45.194.37.150
- **SSH端口**: 22
- **时区**: Asia/Hong_Kong

### 📱 下一步
1. 在浏览器中访问应用
2. 测试所有功能正常
3. 配置域名（可选）
4. 设置监控告警
5. 制定备份计划

**🚀 享受您的高性能GMGN交易平台！**
