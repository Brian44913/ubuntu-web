#!/bin/bash
# install.sh - Ubuntu Web Environment Installer
# Ubuntu Web 环境一键安装脚本
# Supports: Nginx, PHP 8.4, MySQL 8.4 LTS, Redis 8.6, phpMyAdmin, acme.sh SSL
# Target: Ubuntu 24.04 LTS

# --- Resolve script directory / 解析脚本绝对路径 ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR

# --- Load libraries / 加载公共库 ---
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/os.sh"
source "${SCRIPT_DIR}/lib/repo.sh"

# --- Version definitions / 版本定义 ---
readonly PHP_VERSION="8.4"
readonly MYSQL_VERSION="8.4"
readonly NGINX_VERSION="1.28"
readonly REDIS_VERSION="8.6"
readonly PMA_VERSION="5.2.3"
export PHP_VERSION MYSQL_VERSION NGINX_VERSION REDIS_VERSION PMA_VERSION

# --- Load components / 加载组件 ---
source "${SCRIPT_DIR}/components/nginx.sh"
source "${SCRIPT_DIR}/components/php.sh"
source "${SCRIPT_DIR}/components/mysql.sh"
source "${SCRIPT_DIR}/components/redis.sh"
source "${SCRIPT_DIR}/components/phpmyadmin.sh"
source "${SCRIPT_DIR}/components/acme.sh"

# --- Parse arguments / 解析参数 ---
DB_PASSWORD=""
INSTALL_COMPONENTS=()
SSL_DOMAIN=""
SSL_EMAIL=""

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --dbpasswd)  DB_PASSWORD="$2";  shift 2 ;;
        --ssl)       SSL_DOMAIN="$2";   shift 2 ;;
        --email)     SSL_EMAIL="$2";    shift 2 ;;
        -h|--help)   show_usage; exit 0 ;;
        *)
            IFS=',' read -ra ADDR <<< "$1"
            for i in "${ADDR[@]}"; do
                INSTALL_COMPONENTS+=("$i")
            done
            shift
            ;;
    esac
done

# --- Validations / 参数验证 ---
require_root
check_os

if [[ ${#INSTALL_COMPONENTS[@]} -eq 0 ]]; then
    show_usage
    exit 0
fi

if [[ " ${INSTALL_COMPONENTS[*]} " =~ " mysql " ]] && [[ -z "${DB_PASSWORD}" ]]; then
    log_error "MySQL requires --dbpasswd parameter. Example: --dbpasswd YourSecurePassword"
    exit 1
fi

export DB_PASSWORD SSL_EMAIL

# --- Generate random code / 生成随机码 ---
RANDOM_CODE=$(head -c 100 /dev/urandom | tr -dc a-z0-9 | head -c 32)
export RANDOM_CODE

# --- System preparation / 系统准备 ---
export DEBIAN_FRONTEND=noninteractive

log_step "Updating system packages..."
apt update -y
apt upgrade -y

log_step "Installing build dependencies..."
apt install -y build-essential libpcre3 libpcre3-dev zlib1g-dev \
    libssl-dev libxml2-dev libcurl4-openssl-dev libjpeg-dev \
    libpng-dev libwebp-dev libfreetype6-dev libonig-dev \
    libzip-dev cmake libncurses5-dev pkg-config wget unzip \
    curl gnupg lsb-release

# --- Create system user / 创建系统用户 ---
id -u www >/dev/null 2>&1 || useradd -M -s /sbin/nologin www

# --- Service status check / 服务状态检查 ---
check_service_status() {
    local services=("nginx" "php${PHP_VERSION}-fpm" "mysql" "redis-server")
    echo ""
    log_info "=========================================="
    log_info "Service Status:"
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "${service}" 2>/dev/null; then
            log_info "  ${service}: running"
        else
            log_warn "  ${service}: not running (may not be installed)"
        fi
    done
    log_info "=========================================="
}

# --- Main installation / 主安装流程 ---
for component in "${INSTALL_COMPONENTS[@]}"; do
    case "${component}" in
        nginx)      install_nginx ;;
        php)        install_php ;;
        mysql)      install_mysql ;;
        redis)      install_redis ;;
        phpmyadmin) install_phpmyadmin ;;
        acme)       install_acme ;;
        *)
            log_warn "Unknown component: ${component}"
            log_info "Valid components: nginx, php, mysql, redis, phpmyadmin, acme"
            ;;
    esac
done

# --- Optional SSL setup / 可选 SSL 配置 ---
if [[ -n "${SSL_DOMAIN}" ]]; then
    setup_ssl "${SSL_DOMAIN}" "${SSL_EMAIL}"
fi

# --- Summary / 安装总结 ---
echo ""
log_info "=========================================="
log_info "Installation completed!"
log_info "Random phpdir code: ${RANDOM_CODE}"
log_info "=========================================="
check_service_status
