#!/bin/bash
# lib/common.sh - Common utility functions
# 公共工具函数

# --- Strict mode / 严格模式 ---
set -euo pipefail

# --- Color constants / 颜色常量 ---
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# --- Logging functions / 日志函数 ---
log_info()  { echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] [WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $*" >&2; }
log_step()  { echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] [STEP]${NC} $*"; }

# --- Error handler / 错误处理器 ---
on_error() {
    local exit_code=$?
    local line_no=$1
    log_error "Script failed at line ${line_no} with exit code ${exit_code}"
    exit "${exit_code}"
}
trap 'on_error ${LINENO}' ERR

# --- Root check / Root 权限检查 ---
require_root() {
    if [[ $(id -u) -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# --- Service management / 服务管理 ---
service_enable_start() {
    local service_name="$1"
    systemctl enable "${service_name}"
    systemctl restart "${service_name}"
    if systemctl is-active --quiet "${service_name}"; then
        log_info "${service_name} is running"
    else
        log_error "${service_name} failed to start"
        return 1
    fi
}

service_stop_disable() {
    local service_name="$1"
    if systemctl is-active --quiet "${service_name}"; then
        systemctl stop "${service_name}"
    fi
    if systemctl is-enabled --quiet "${service_name}" 2>/dev/null; then
        systemctl disable "${service_name}"
    fi
    log_info "${service_name} stopped and disabled"
}

# --- Confirmation prompt / 确认提示 ---
confirm_action() {
    local message="$1"
    read -rp "${message} [y/N]: " response
    [[ "${response}" =~ ^[Yy]$ ]]
}

# --- Usage / 使用说明 ---
show_usage() {
    echo -e "${CYAN}Ubuntu Web Environment Installer${NC}"
    echo ""
    echo "Usage: bash install.sh <components> [options]"
    echo ""
    echo "Components (comma-separated):"
    echo "  nginx        Nginx web server"
    echo "  php          PHP ${PHP_VERSION} with FPM"
    echo "  mysql        MySQL ${MYSQL_VERSION} LTS"
    echo "  redis        Redis server"
    echo "  phpmyadmin   phpMyAdmin web interface"
    echo "  acme         acme.sh SSL client"
    echo ""
    echo "Options:"
    echo "  --dbpasswd PASSWORD    MySQL root password (required when installing mysql)"
    echo "  --ssl DOMAIN           Setup SSL certificate for domain (requires acme + nginx)"
    echo "  --email EMAIL          Email for SSL certificate registration"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  bash install.sh nginx,php,mysql,redis --dbpasswd MySecurePass123"
    echo "  bash install.sh nginx,php,acme --ssl example.com --email admin@example.com"
    echo "  bash install.sh redis"
}

show_uninstall_usage() {
    echo -e "${CYAN}Ubuntu Web Environment Uninstaller${NC}"
    echo ""
    echo "Usage: bash uninstall.sh <components> [options]"
    echo ""
    echo "Components (comma-separated):"
    echo "  nginx, php, mysql, redis, phpmyadmin, acme"
    echo ""
    echo "Options:"
    echo "  --all    Uninstall all components"
    echo "  -h, --help   Show this help message"
    echo ""
    echo "Examples:"
    echo "  bash uninstall.sh nginx,php"
    echo "  bash uninstall.sh --all"
}
