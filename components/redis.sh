#!/bin/bash
# components/redis.sh - Redis installation and uninstallation
# Redis 安装与卸载

install_redis() {
    if systemctl is-active --quiet redis-server; then
        log_warn "Redis is already installed, skipping."
        return 0
    fi

    log_step "Installing Redis ${REDIS_VERSION}..."

    # Add Redis official repository / 添加 Redis 官方仓库
    add_gpg_key "https://packages.redis.io/gpg" "redis-archive-keyring"
    add_apt_repo "redis" "https://packages.redis.io/deb noble main" "redis-archive-keyring"

    apt update
    apt install -y redis-server

    service_enable_start redis-server
    log_info "Redis installed successfully"
}

uninstall_redis() {
    log_step "Uninstalling Redis..."
    service_stop_disable redis-server
    apt purge -y redis-server || true
    apt autoremove -y
    remove_apt_repo "redis" "redis-archive-keyring"
    log_info "Redis uninstalled"
}
