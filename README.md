# ubuntu-web

适用于 **Ubuntu 24.04 LTS** 的 Nginx + PHP + MySQL + Redis Web 环境一键安装脚本。

所有组件均通过官方 APT 仓库安装。

## 快速开始

```bash
git clone https://github.com/Brian44913/ubuntu-web && \
cd ubuntu-web && \
bash install.sh nginx,php,mysql,redis --dbpasswd YourSecurePassword
```

## 组件与版本

| 组件 | 版本 | 安装源 |
|------|------|--------|
| Nginx | 1.28.x | nginx.org 官方仓库 |
| PHP | 8.4 | Ondrej PPA |
| MySQL | 8.4 LTS | MySQL 官方仓库 |
| Redis | 8.6 | redis.io 官方仓库 |
| phpMyAdmin | 5.2.3 | phpmyadmin.net |
| acme.sh | 最新版 | get.acme.sh |

## 安装

```bash
# 全栈安装
bash install.sh nginx,php,mysql,redis --dbpasswd YourSecurePassword

# 包含 phpMyAdmin
bash install.sh nginx,php,mysql,redis,phpmyadmin --dbpasswd YourSecurePassword

# 包含 SSL 证书
bash install.sh nginx,php,mysql,redis,acme --dbpasswd YourSecurePassword --ssl example.com --email admin@example.com

# 单组件安装
bash install.sh redis
```

### 可用组件

- `nginx` — Nginx Web 服务器
- `php` — PHP 8.4（含 FPM 及常用扩展）
- `mysql` — MySQL 8.4 LTS（需指定 `--dbpasswd`）
- `redis` — Redis 服务器
- `phpmyadmin` — phpMyAdmin 数据库管理界面
- `acme` — acme.sh SSL 证书客户端

### 参数说明

| 参数 | 说明 |
|------|------|
| `--dbpasswd PASSWORD` | MySQL root 密码（安装 mysql 时必填） |
| `--ssl DOMAIN` | 安装完成后自动为指定域名申请 SSL 证书 |
| `--email EMAIL` | SSL 证书注册邮箱 |
| `-h, --help` | 显示帮助信息 |

## 卸载

```bash
# 卸载指定组件
bash uninstall.sh nginx,php

# 卸载全部
bash uninstall.sh --all
```

> **注意：** 卸载时不会自动删除数据目录（`/data/wwwroot/`、`/var/lib/mysql`），以防止数据丢失。如不再需要，请手动删除。

## SSL 证书（acme.sh）

安装 `acme` 组件后，可以为其他域名申请 SSL 证书：

```bash
# 先加载组件脚本
source lib/common.sh && source lib/repo.sh && source components/acme.sh
export SCRIPT_DIR="$(pwd)" PHP_VERSION="8.4"
setup_ssl yourdomain.com your@email.com
```

acme.sh 会自动通过 cron 定时续期证书。

## 配置文件路径

#### Nginx
```
/etc/nginx/nginx.conf          # 主配置
/etc/nginx/vhost/*.conf         # 虚拟主机
/etc/nginx/ssl/                 # SSL 证书

systemctl restart nginx
```

#### PHP
```
/etc/php/8.4/fpm/php.ini       # PHP 配置
/etc/php/8.4/fpm/pool.d/       # FPM 进程池配置

systemctl restart php8.4-fpm
```

#### MySQL
```
/etc/mysql/mysql.conf.d/mysqld.cnf   # 主配置

systemctl restart mysql
```

#### Redis
```
/etc/redis/redis.conf           # 主配置

systemctl restart redis-server
```

## MySQL 说明

MySQL 8.4 LTS 默认且唯一使用 `caching_sha2_password` 认证插件，`mysql_native_password` 已不可用。

- 修改 root 密码：
```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_password';
FLUSH PRIVILEGES;
```

- 创建 root@127.0.0.1：
```sql
CREATE USER 'root'@'127.0.0.1' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```

- 修改监听地址（默认仅监听 127.0.0.1）：
```
vi /etc/mysql/mysql.conf.d/mysqld.cnf
# 将 bind-address = 127.0.0.1 改为 bind-address = 0.0.0.0
```

## 项目结构

```
ubuntu-web/
├── install.sh              # 安装入口
├── uninstall.sh            # 卸载入口
├── lib/
│   ├── common.sh           # 日志、错误处理、服务管理
│   ├── os.sh               # 操作系统检测（Ubuntu 24.04）
│   └── repo.sh             # APT 仓库管理（signed-by 方式）
├── components/
│   ├── nginx.sh            # Nginx 安装/卸载
│   ├── php.sh              # PHP 安装/卸载
│   ├── mysql.sh            # MySQL 安装/卸载
│   ├── redis.sh            # Redis 安装/卸载
│   ├── phpmyadmin.sh       # phpMyAdmin 安装/卸载
│   └── acme.sh             # acme.sh SSL 安装/卸载
└── config/
    ├── nginx.conf           # Nginx 配置模板
    ├── nginx-ssl-vhost.conf # SSL 虚拟主机模板
    └── mysql.cnf            # MySQL 8.4 配置
```

## 系统要求

- Ubuntu 24.04 LTS（建议全新安装）
- Root 权限
- 网络连接

## 许可证

MIT
