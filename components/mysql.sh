#!/bin/bash
# components/mysql.sh - MySQL installation and uninstallation
# MySQL 安装与卸载

install_mysql() {
    if systemctl is-active --quiet mysql; then
        log_warn "MySQL is already installed, skipping."
        return 0
    fi

    log_step "Installing MySQL ${MYSQL_VERSION} LTS..."

    # Add MySQL official APT repository / 添加 MySQL 官方仓库
    add_gpg_key "https://repo.mysql.com/RPM-GPG-KEY-mysql-2025" "mysql-archive-keyring"
    add_apt_repo "mysql" "http://repo.mysql.com/apt/ubuntu noble mysql-8.4-lts" "mysql-archive-keyring"

    apt update
    apt install -y mysql-server

    # Deploy configuration file / 部署配置文件
    cp "${SCRIPT_DIR}/config/mysql.cnf" /etc/mysql/mysql.conf.d/mysqld.cnf

    systemctl restart mysql

    # Set root password (MySQL 8.4 uses caching_sha2_password by default)
    # 设置 root 密码（MySQL 8.4 默认使用 caching_sha2_password）
    # Escape single quotes in password to prevent SQL injection
    # 转义密码中的单引号，防止 SQL 注入
    local escaped_password="${DB_PASSWORD//\'/\'\'}"
    mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${escaped_password}';"

    service_enable_start mysql
    log_info "MySQL ${MYSQL_VERSION} LTS installed successfully"
}

uninstall_mysql() {
    log_step "Uninstalling MySQL..."

    if ! confirm_action "WARNING: This will remove MySQL server. Databases in /var/lib/mysql will be preserved. Continue?"; then
        log_info "MySQL uninstall cancelled"
        return 0
    fi

    service_stop_disable mysql
    apt purge -y mysql-server mysql-client mysql-common || true
    apt autoremove -y
    remove_apt_repo "mysql" "mysql-archive-keyring"

    log_warn "MySQL data directory (/var/lib/mysql) was NOT removed."
    log_warn "Remove it manually if no longer needed: rm -rf /var/lib/mysql"
    log_info "MySQL uninstalled"
}
