#!/bin/bash
# components/acme.sh - acme.sh SSL client installation and SSL setup
# acme.sh SSL 客户端安装与证书管理

readonly ACME_HOME="/root/.acme.sh"

install_acme() {
    if [[ -f "${ACME_HOME}/acme.sh" ]]; then
        log_warn "acme.sh is already installed, skipping."
        return 0
    fi

    log_step "Installing acme.sh..."

    curl https://get.acme.sh | sh -s email="${SSL_EMAIL:-}"

    # Set default CA to Let's Encrypt / 设置默认 CA 为 Let's Encrypt
    "${ACME_HOME}/acme.sh" --set-default-ca --server letsencrypt

    log_info "acme.sh installed successfully"
    log_info "Use 'setup_ssl <domain>' to issue and deploy SSL certificates"
}

# Issue and deploy SSL certificate for a domain
# 为指定域名申请并部署 SSL 证书
# Usage: setup_ssl <domain> [email]
setup_ssl() {
    local domain="$1"
    local email="${2:-}"

    if [[ -z "${domain}" ]]; then
        log_error "Usage: setup_ssl <domain> [email]"
        return 1
    fi

    # Validate domain format / 校验域名格式
    if [[ ! "${domain}" =~ ^[a-zA-Z0-9]([a-zA-Z0-9.-]*[a-zA-Z0-9])?$ ]]; then
        log_error "Invalid domain format: ${domain}"
        return 1
    fi

    if ! systemctl is-active --quiet nginx; then
        log_error "Nginx is not running. Please install and start Nginx first."
        return 1
    fi

    if [[ ! -f "${ACME_HOME}/acme.sh" ]]; then
        log_error "acme.sh is not installed. Install it first: bash install.sh acme"
        return 1
    fi

    log_step "Setting up SSL for ${domain}..."

    # Create certificate directory / 创建证书目录
    mkdir -p "/etc/nginx/ssl/${domain}"

    # Issue certificate using webroot mode / 使用 webroot 模式申请证书
    local webroot="/data/wwwroot/default"
    if [[ -d "/data/wwwroot/${domain}" ]]; then
        webroot="/data/wwwroot/${domain}"
    fi

    "${ACME_HOME}/acme.sh" --issue \
        -d "${domain}" \
        --webroot "${webroot}" \
        ${email:+--accountemail "${email}"}

    # Install certificate to Nginx directory / 安装证书到 Nginx 目录
    "${ACME_HOME}/acme.sh" --install-cert -d "${domain}" \
        --key-file "/etc/nginx/ssl/${domain}/privkey.pem" \
        --fullchain-file "/etc/nginx/ssl/${domain}/fullchain.pem" \
        --reloadcmd "systemctl reload nginx"

    # Deploy SSL vhost configuration / 部署 SSL 虚拟主机配置
    local vhost_conf="/etc/nginx/vhost/${domain}.conf"
    if [[ -f "${vhost_conf}" ]]; then
        log_warn "Vhost config ${vhost_conf} already exists, skipping template deployment."
    else
        mkdir -p "/data/wwwroot/${domain}"
        cp "${SCRIPT_DIR}/config/nginx-ssl-vhost.conf" "${vhost_conf}"
        sed -i "s|__DOMAIN__|${domain}|g" "${vhost_conf}"
        sed -i "s|__PHP_VERSION__|${PHP_VERSION}|g" "${vhost_conf}"
    fi

    nginx -t && systemctl reload nginx

    log_info "SSL configured for ${domain}"
    log_info "Certificate: /etc/nginx/ssl/${domain}/fullchain.pem"
    log_info "Private key: /etc/nginx/ssl/${domain}/privkey.pem"
    log_info "Auto-renewal is handled by acme.sh cron job"
}

uninstall_acme() {
    log_step "Uninstalling acme.sh..."

    if [[ -f "${ACME_HOME}/acme.sh" ]]; then
        "${ACME_HOME}/acme.sh" --uninstall
    fi

    rm -rf "${ACME_HOME}"

    log_warn "SSL certificates in /etc/nginx/ssl/ were NOT removed."
    log_info "acme.sh uninstalled"
}
