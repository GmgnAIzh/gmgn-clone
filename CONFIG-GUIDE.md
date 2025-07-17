# GMGN 服务器配置工具使用指南

## 📋 工具概述

本指南介绍GMGN项目的服务器环境配置工具套件，帮助您快速适配不同的服务器环境并优化部署配置。

### 🔧 工具套件

| 工具名称 | 功能描述 | 使用场景 |
|----------|----------|----------|
| **configure-server.sh** | 交互式配置收集 | 自定义服务器配置 |
| **apply-template.sh** | 快速应用预设模板 | 标准化配置部署 |
| **validate-config.sh** | 配置验证和优化 | 配置质量检查 |
| **server-templates.json** | 预设配置模板 | 参考标准配置 |

## 🚀 快速开始

### 方式一：使用预设模板（推荐）

```bash
# 1. 查看可用模板
./apply-template.sh list

# 2. 获取推荐模板
./apply-template.sh recommend

# 3. 交互式应用模板
./apply-template.sh

# 4. 直接应用模板
./apply-template.sh medium_server example.com admin@example.com
```

### 方式二：自定义配置

```bash
# 1. 交互式配置
./configure-server.sh

# 2. 自动配置（使用检测值）
./configure-server.sh auto

# 3. 验证配置
./validate-config.sh

# 4. 部署应用
./deploy-production.sh
```

## 📊 预设模板详解

### Small Server (小型服务器)
```json
{
  "适用场景": "个人项目、小型应用",
  "硬件要求": "1-2核心, 2-4GB内存, 20GB硬盘",
  "配置特点": {
    "PM2实例": 1,
    "Node堆大小": "1GB",
    "并发连接": 500,
    "请求频率": "10r/s"
  }
}
```

### Medium Server (中型服务器)
```json
{
  "适用场景": "中小企业应用",
  "硬件要求": "4核心, 8GB内存, 100GB硬盘",
  "配置特点": {
    "PM2实例": 3,
    "Node堆大小": "2GB",
    "并发连接": 2000,
    "请求频率": "50r/s"
  }
}
```

### Large Server (大型服务器)
```json
{
  "适用场景": "高并发企业应用",
  "硬件要求": "8+核心, 16+GB内存, 500GB硬盘",
  "配置特点": {
    "PM2实例": 6,
    "Node堆大小": "4GB",
    "并发连接": 10000,
    "请求频率": "200r/s"
  }
}
```

### Cloud Optimized (云服务器优化)
```json
{
  "适用场景": "AWS、阿里云、腾讯云等云平台",
  "配置特点": {
    "自动扩展": "支持",
    "负载均衡": "支持",
    "CDN集成": "支持",
    "自动备份": "启用"
  }
}
```

### Development (开发环境)
```json
{
  "适用场景": "开发和测试环境",
  "配置特点": {
    "热重载": "启用",
    "调试模式": "启用",
    "性能要求": "低",
    "监控频率": "降低"
  }
}
```

### Production Optimized (生产环境优化)
```json
{
  "适用场景": "高性能生产环境",
  "配置特点": {
    "安全强化": "启用",
    "性能最大化": "启用",
    "监控告警": "全面",
    "备份策略": "完整"
  }
}
```

## 🔍 配置工具详解

### configure-server.sh - 交互式配置工具

#### 功能特点
- 🔍 自动检测系统信息
- 💬 交互式配置收集
- ⚙️ 智能推荐最佳值
- 📁 生成完整配置文件

#### 使用方法

```bash
# 交互式配置
./configure-server.sh

# 自动配置（使用默认值）
./configure-server.sh auto

# 查看帮助
./configure-server.sh help
```

#### 配置流程

1. **系统检测阶段**
   - CPU核心数和型号
   - 内存总量和可用量
   - 硬盘空间和使用率
   - 网络和IP信息

2. **项目配置阶段**
   - 项目名称和路径
   - 运行用户和端口
   - 基础安全设置

3. **域名配置阶段**
   - 域名设置
   - SSL证书配置
   - 管理员邮箱

4. **性能配置阶段**
   - PM2实例数量
   - Node.js堆大小
   - 监控阈值设置

5. **配置生成阶段**
   - 生成所有配置文件
   - 创建部署脚本
   - 设置系统服务

### apply-template.sh - 模板应用工具

#### 功能特点
- 📋 预设配置模板
- 🎯 智能模板推荐
- ⚡ 快速配置部署
- 🔧 自动参数调整

#### 使用方法

```bash
# 列出所有模板
./apply-template.sh list

# 获取推荐模板
./apply-template.sh recommend

# 交互式选择模板
./apply-template.sh

# 直接应用模板
./apply-template.sh small_server

# 域名部署
./apply-template.sh medium_server example.com admin@example.com
```

#### 模板选择指南

| 服务器规格 | 推荐模板 | 适用场景 |
|------------|----------|----------|
| 1核1GB | small_server | 个人博客、测试环境 |
| 2核2GB | small_server | 小型网站、开发环境 |
| 2核4GB | medium_server | 中小企业网站 |
| 4核8GB | medium_server | 电商网站、论坛 |
| 8核16GB+ | large_server | 高并发应用、企业级系统 |
| 云服务器 | cloud_optimized | 弹性扩展、高可用 |

### validate-config.sh - 配置验证工具

#### 功能特点
- ✅ 配置合理性检查
- ⚠️ 潜在问题警告
- 💡 性能优化建议
- 📊 详细验证报告

#### 使用方法

```bash
# 完整验证
./validate-config.sh

# 快速验证
./validate-config.sh quick

# 查看最新报告
./validate-config.sh report
```

#### 验证项目

1. **硬件配置验证**
   - CPU核心数合理性
   - 内存容量充足性
   - 硬盘空间检查

2. **PM2配置验证**
   - 实例数与CPU核心匹配
   - 内存分配合理性
   - 重启策略配置

3. **监控配置验证**
   - 健康检查频率
   - 告警阈值设置
   - 日志配置完整性

4. **端口配置验证**
   - 端口范围合法性
   - 端口占用检查
   - 防火墙规则

5. **安全配置验证**
   - SSL证书配置
   - 用户权限设置
   - 防火墙状态

## 📈 性能优化建议

### 内存优化策略

#### 小内存服务器 (< 2GB)
```bash
# 推荐配置
PM2_INSTANCES=1
NODE_HEAP_SIZE=1024
MAX_MEMORY_RESTART=1G

# 优化措施
- 启用 swap 交换空间
- 定期清理日志文件
- 使用轻量级监控
- 禁用不必要服务
```

#### 中等内存服务器 (2-8GB)
```bash
# 推荐配置
PM2_INSTANCES=cores-1
NODE_HEAP_SIZE=2048
MAX_MEMORY_RESTART=2G

# 优化措施
- 启用集群模式
- 配置内存缓存
- 使用连接池
- 启用压缩功能
```

#### 大内存服务器 (> 8GB)
```bash
# 推荐配置
PM2_INSTANCES=max
NODE_HEAP_SIZE=4096
MAX_MEMORY_RESTART=4G

# 优化措施
- 启用 Redis 缓存
- 配置数据库集群
- 使用 CDN 加速
- 启用负载均衡
```

### CPU优化策略

#### 单核/双核服务器
```bash
# 配置重点
- 减少并发处理
- 优化代码性能
- 使用异步操作
- 降低监控频率

# 推荐设置
PM2_INSTANCES=1
HEALTH_CHECK_INTERVAL=15min
CPU_THRESHOLD=95%
```

#### 多核服务器 (4+核心)
```bash
# 配置重点
- 充分利用多核
- 启用集群模式
- 并行处理任务
- 负载均衡分发

# 推荐设置
PM2_INSTANCES=max
HEALTH_CHECK_INTERVAL=5min
CPU_THRESHOLD=85%
```

## 🛠️ 故障排除

### 常见配置问题

#### 1. 内存不足错误
```bash
# 症状
PM2进程频繁重启
应用响应缓慢
系统swap使用率高

# 解决方案
./validate-config.sh
# 根据建议调整 NODE_HEAP_SIZE
# 减少 PM2_INSTANCES 数量
# 启用内存监控告警
```

#### 2. 端口冲突
```bash
# 症状
应用启动失败
端口绑定错误

# 解决方案
netstat -tlnp | grep :3000
# 查找并终止占用进程
# 修改 app_port 配置
./configure-server.sh
```

#### 3. SSL证书问题
```bash
# 症状
HTTPS访问失败
证书过期警告

# 解决方案
certbot certificates
certbot renew
# 检查域名DNS解析
# 更新nginx配置
```

#### 4. 权限问题
```bash
# 症状
文件访问被拒绝
服务启动失败

# 解决方案
# 检查文件权限
ls -la /home/project/gmgn-clone
# 修正所有者和权限
chown -R user:group /home/project/gmgn-clone
chmod +x *.sh
```

### 性能问题诊断

#### 高内存使用
```bash
# 诊断命令
pm2 monit
free -h
top -p $(pgrep node)

# 优化措施
- 减少PM2实例数
- 降低Node.js堆大小
- 启用内存监控
- 定期重启应用
```

#### 高CPU使用
```bash
# 诊断命令
pm2 logs --lines 100
htop
iotop

# 优化措施
- 优化代码逻辑
- 减少同步操作
- 使用缓存机制
- 增加服务器规格
```

## 📚 最佳实践

### 1. 配置管理
- 🔒 使用版本控制管理配置
- 📋 记录配置变更历史
- 🧪 在测试环境验证配置
- 📊 定期审查和优化配置

### 2. 监控告警
- 📈 设置合理的监控阈值
- 📧 配置多渠道告警通知
- 📝 建立故障处理流程
- 🔍 定期检查监控数据

### 3. 安全加固
- 🔐 定期更新系统和依赖
- 🛡️ 启用防火墙和入侵检测
- 🔑 使用强密码和密钥认证
- 📊 启用详细的安全日志

### 4. 备份策略
- 💾 制定完整的备份计划
- 🔄 定期测试备份恢复
- 📁 多地点存储备份文件
- ⏰ 自动化备份流程

## 🎯 部署工作流

### 标准部署流程

```bash
# 1. 环境准备
git clone <repository>
cd gmgn-clone

# 2. 配置生成
./apply-template.sh recommend
./apply-template.sh medium_server

# 3. 配置验证
./validate-config.sh
# 根据报告修复问题

# 4. 部署执行
./deploy-production.sh

# 5. 验证部署
./health-check.sh
curl http://localhost:3000

# 6. 监控启动
crontab crontab-config
```

### CI/CD集成

```yaml
# .github/workflows/deploy.yml
name: Deploy GMGN
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Apply Configuration
        run: |
          ./apply-template.sh production_optimized

      - name: Validate Configuration
        run: |
          ./validate-config.sh

      - name: Deploy Application
        run: |
          ./deploy-production.sh
```

## 📞 技术支持

### 获取帮助

```bash
# 查看工具帮助
./configure-server.sh help
./apply-template.sh help
./validate-config.sh help

# 生成诊断报告
./validate-config.sh report

# 健康检查
./health-check.sh
```

### 常用资源

- 📖 [完整部署文档](./DEPLOYMENT.md)
- 🔧 [故障排除指南](./DEPLOYMENT.md#故障排除)
- 📊 [性能优化建议](./DEPLOYMENT.md#性能优化)
- 🛡️ [安全配置指南](./DEPLOYMENT.md#安全配置)

---

💡 **提示**: 建议在生产环境部署前，先在测试环境中验证所有配置和流程。
