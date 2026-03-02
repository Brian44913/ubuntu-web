#!/bin/bash
# components/php.sh - PHP installation and uninstallation
# PHP 安装与卸载

install_php() {
    if systemctl is-active --quiet "php${PHP_VERSION}-fpm"; then
        log_warn "PHP ${PHP_VERSION} is already installed, skipping."
        return 0
    fi

    log_step "Installing PHP ${PHP_VERSION}..."

    # Ondrej PPA (uses modern signed-by internally on Ubuntu 24.04)
    # Ondrej PPA（在 Ubuntu 24.04 上已内部使用 signed-by 方式）
    apt install -y software-properties-common
    add-apt-repository ppa:ondrej/php -y
    apt update

    apt install -y \
        "php${PHP_VERSION}" \
        "php${PHP_VERSION}-fpm" \
        "php${PHP_VERSION}-mysql" \
        "php${PHP_VERSION}-redis" \
        "php${PHP_VERSION}-fileinfo" \
        "php${PHP_VERSION}-opcache" \
        "php${PHP_VERSION}-curl" \
        "php${PHP_VERSION}-mbstring" \
        "php${PHP_VERSION}-bcmath" \
        "php${PHP_VERSION}-xml" \
        "php${PHP_VERSION}-zip" \
        "php${PHP_VERSION}-gd" \
        "php${PHP_VERSION}-intl"

    # Configure PHP-FPM pool / 配置 PHP-FPM 进程池
    mkdir -p /var/log/php-fpm
    cat > "/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf" <<EOT
[www]
user = www
group = www
listen = /run/php/php${PHP_VERSION}-fpm.sock
listen.owner = www
listen.group = www

pm = dynamic
; Adjust pm.max_children based on available RAM: available_memory / 50MB per process
; 根据可用内存调整：可用内存 / 每进程约 50MB
pm.max_children = 20
pm.start_servers = 8
pm.min_spare_servers = 4
pm.max_spare_servers = 12

; Restart worker after N requests to prevent memory leaks
; 每个 worker 处理 N 个请求后重启，防止内存泄漏
pm.max_requests = 500

; Kill worker if single request exceeds this timeout (seconds)
; 单个请求超时则终止 worker（秒）
request_terminate_timeout = 300

; Error logging / 错误日志
php_admin_flag[log_errors] = on
php_admin_value[error_log] = /var/log/php-fpm/www-error.log
EOT

    service_enable_start "php${PHP_VERSION}-fpm"
    log_info "PHP ${PHP_VERSION} installed successfully"
}

uninstall_php() {
    log_step "Uninstalling PHP ${PHP_VERSION}..."
    service_stop_disable "php${PHP_VERSION}-fpm"
    apt purge -y "php${PHP_VERSION}"* || true
    apt autoremove -y
    log_info "PHP ${PHP_VERSION} uninstalled"
}
