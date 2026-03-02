#!/bin/bash
# uninstall.sh - Ubuntu Web Environment Uninstaller
# Ubuntu Web 环境卸载脚本

# --- Resolve script directory / 解析脚本绝对路径 ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR

# --- Load libraries / 加载公共库 ---
source "${SCRIPT_DIR}/lib/common.sh"
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
UNINSTALL_COMPONENTS=()
UNINSTALL_ALL=false

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --all)       UNINSTALL_ALL=true; shift ;;
        -h|--help)   show_uninstall_usage; exit 0 ;;
        *)
            IFS=',' read -ra ADDR <<< "$1"
            for i in "${ADDR[@]}"; do
                UNINSTALL_COMPONENTS+=("$i")
            done
            shift
            ;;
    esac
done

require_root

# --all: uninstall in reverse dependency order
# --all: 按依赖关系倒序卸载
if ${UNINSTALL_ALL}; then
    UNINSTALL_COMPONENTS=(acme phpmyadmin redis mysql php nginx)
fi

if [[ ${#UNINSTALL_COMPONENTS[@]} -eq 0 ]]; then
    show_uninstall_usage
    exit 0
fi

export DEBIAN_FRONTEND=noninteractive

for component in "${UNINSTALL_COMPONENTS[@]}"; do
    case "${component}" in
        nginx)      uninstall_nginx ;;
        php)        uninstall_php ;;
        mysql)      uninstall_mysql ;;
        redis)      uninstall_redis ;;
        phpmyadmin) uninstall_phpmyadmin ;;
        acme)       uninstall_acme ;;
        *)          log_warn "Unknown component: ${component}" ;;
    esac
done

echo ""
log_info "Uninstall completed"
