#!/bin/bash
# components/nginx.sh - Nginx installation and uninstallation
# Nginx 安装与卸载

install_nginx() {
    if systemctl is-active --quiet nginx; then
        log_warn "Nginx is already installed, skipping."
        return 0
    fi

    if [[ -f "/etc/nginx/nginx.conf" ]]; then
        log_error "/etc/nginx/nginx.conf already exists. Back it up and remove it before reinstalling."
        return 1
    fi

    log_step "Installing Nginx ${NGINX_VERSION}..."

    # Add official Nginx repository with modern GPG key management
    # 使用现代 GPG key 管理方式添加 Nginx 官方仓库
    add_gpg_key "https://nginx.org/keys/nginx_signing.key" "nginx-archive-keyring"
    add_apt_repo "nginx" "http://nginx.org/packages/ubuntu noble nginx" "nginx-archive-keyring"

    apt update
    apt install -y nginx

    # Create directory structure / 创建目录结构
    mkdir -p /etc/nginx/{vhost,ssl}
    mkdir -p /data/logs/{nginx_access,nginx_error}
    mkdir -p "/data/wwwroot/default/phpdir-${RANDOM_CODE}"

    # Deploy configuration / 部署配置
    [[ -f /etc/nginx/nginx.conf ]] && mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.default
    cp "${SCRIPT_DIR}/config/nginx.conf" /etc/nginx/
    sed -i "s|__PHPDIR_CODE__|${RANDOM_CODE}|g" /etc/nginx/nginx.conf
    sed -i "s|__PHP_VERSION__|${PHP_VERSION}|g" /etc/nginx/nginx.conf

    # No dummy certificate needed: default server uses ssl_reject_handshake
    # 无需自签名证书：默认服务器使用 ssl_reject_handshake 直接拒绝未匹配的 SSL 握手

    service_enable_start nginx
    log_info "Nginx installed successfully"
}

uninstall_nginx() {
    log_step "Uninstalling Nginx..."
    service_stop_disable nginx
    apt purge -y nginx || true
    apt autoremove -y
    remove_apt_repo "nginx" "nginx-archive-keyring"

    log_warn "Data directories (/data/wwwroot, /data/logs/nginx_*) were NOT removed."
    log_warn "Remove them manually if no longer needed."
    log_info "Nginx uninstalled"
}
