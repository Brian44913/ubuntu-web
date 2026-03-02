# ubuntu-web

One-click installation of Nginx + PHP + MySQL + Redis web environment for **Ubuntu 24.04 LTS**.

All components installed via official APT repositories.

## Quick Start

```bash
git clone https://github.com/Brian44913/ubuntu-web && \
cd ubuntu-web && \
bash install.sh nginx,php,mysql,redis --dbpasswd YourSecurePassword
```

## Components & Versions

| Component | Version | Source |
|-----------|---------|--------|
| Nginx | 1.28.x | nginx.org official repo |
| PHP | 8.4 | Ondrej PPA |
| MySQL | 8.4 LTS | MySQL official repo |
| Redis | 8.6 | redis.io official repo |
| phpMyAdmin | 5.2.3 | phpmyadmin.net |
| acme.sh | latest | get.acme.sh |

## Installation

```bash
# Full stack / 全栈安装
bash install.sh nginx,php,mysql,redis --dbpasswd YourSecurePassword

# With phpMyAdmin / 包含 phpMyAdmin
bash install.sh nginx,php,mysql,redis,phpmyadmin --dbpasswd YourSecurePassword

# With SSL / 包含 SSL 证书
bash install.sh nginx,php,mysql,redis,acme --dbpasswd YourSecurePassword --ssl example.com --email admin@example.com

# Single component / 单组件安装
bash install.sh redis
```

### Available Components

- `nginx` - Nginx web server
- `php` - PHP 8.4 with FPM and common extensions
- `mysql` - MySQL 8.4 LTS (requires `--dbpasswd`)
- `redis` - Redis server
- `phpmyadmin` - phpMyAdmin web interface
- `acme` - acme.sh SSL client

### Options

| Option | Description |
|--------|-------------|
| `--dbpasswd PASSWORD` | MySQL root password (required when installing mysql) |
| `--ssl DOMAIN` | Setup SSL certificate for domain after installation |
| `--email EMAIL` | Email for SSL certificate registration |
| `-h, --help` | Show help message |

## Uninstallation

```bash
# Uninstall specific components / 卸载指定组件
bash uninstall.sh nginx,php

# Uninstall everything / 卸载全部
bash uninstall.sh --all
```

> **Note:** Data directories (`/data/wwwroot/`, `/var/lib/mysql`) are NOT automatically removed during uninstallation to prevent data loss.

## SSL Certificate (acme.sh)

After installing with `acme` component, you can setup SSL for additional domains:

```bash
# In install.sh, source the components first, then:
source lib/common.sh && source lib/repo.sh && source components/acme.sh
export SCRIPT_DIR="$(pwd)" PHP_VERSION="8.4"
setup_ssl yourdomain.com your@email.com
```

acme.sh handles automatic certificate renewal via cron.

## Configuration Files

#### Nginx
```
/etc/nginx/nginx.conf          # Main config
/etc/nginx/vhost/*.conf         # Virtual hosts
/etc/nginx/ssl/                 # SSL certificates

systemctl restart nginx
```

#### PHP
```
/etc/php/8.4/fpm/php.ini       # PHP config
/etc/php/8.4/fpm/pool.d/       # FPM pool config

systemctl restart php8.4-fpm
```

#### MySQL
```
/etc/mysql/mysql.conf.d/mysqld.cnf   # Main config

systemctl restart mysql
```

#### Redis
```
/etc/redis/redis.conf           # Main config

systemctl restart redis-server
```

## MySQL Notes

MySQL 8.4 LTS uses `caching_sha2_password` as the default (and only) authentication plugin. `mysql_native_password` is no longer available.

- Change root password:
```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_password';
FLUSH PRIVILEGES;
```

- Create root@127.0.0.1:
```sql
CREATE USER 'root'@'127.0.0.1' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```

- Change bind address:
```
vi /etc/mysql/mysql.conf.d/mysqld.cnf
# bind-address = 0.0.0.0
```

## Project Structure

```
ubuntu-web/
├── install.sh              # Installation entry point
├── uninstall.sh            # Uninstallation entry point
├── lib/
│   ├── common.sh           # Logging, error handling, service management
│   ├── os.sh               # OS detection (Ubuntu 24.04)
│   └── repo.sh             # APT repository management (signed-by)
├── components/
│   ├── nginx.sh            # Nginx install/uninstall
│   ├── php.sh              # PHP install/uninstall
│   ├── mysql.sh            # MySQL install/uninstall
│   ├── redis.sh            # Redis install/uninstall
│   ├── phpmyadmin.sh       # phpMyAdmin install/uninstall
│   └── acme.sh             # acme.sh SSL install/uninstall
└── config/
    ├── nginx.conf           # Nginx configuration template
    ├── nginx-ssl-vhost.conf # SSL virtual host template
    └── mysql.cnf            # MySQL 8.4 configuration
```

## Requirements

- Ubuntu 24.04 LTS (fresh installation recommended)
- Root access
- Internet connection

## License

MIT
