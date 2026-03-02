#!/bin/bash
# components/phpmyadmin.sh - phpMyAdmin installation and uninstallation
# phpMyAdmin 安装与卸载

install_phpmyadmin() {
    local target_dir="/data/wwwroot/default/phpdir-${RANDOM_CODE}"
    local pma_version="${PMA_VERSION}"
    local pma_url="https://files.phpmyadmin.net/phpMyAdmin/${pma_version}/phpMyAdmin-${pma_version}-all-languages.zip"
    local pma_extracted="phpMyAdmin-${pma_version}-all-languages"

    if [[ -d "${target_dir}/phpmyadmin" ]]; then
        log_warn "phpMyAdmin is already installed at ${target_dir}/phpmyadmin, skipping."
        return 0
    fi

    log_step "Installing phpMyAdmin ${pma_version}..."

    mkdir -p "${target_dir}"

    wget -c "${pma_url}" -O /tmp/phpMyAdmin.zip
    unzip -o /tmp/phpMyAdmin.zip -d /tmp/
    # Move contents to target directory (avoid nested directory)
    # 移动文件到目标目录（避免嵌套子目录）
    mv /tmp/"${pma_extracted}" "${target_dir}/phpmyadmin"
    rm -f /tmp/phpMyAdmin.zip

    # Create tmp directory for template cache / 创建临时目录用于模板缓存
    mkdir -p "${target_dir}/phpmyadmin/tmp"
    chmod 777 "${target_dir}/phpmyadmin/tmp"

    # Generate config with blowfish_secret / 生成配置并设置 blowfish_secret
    local secret
    secret=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 32)
    cp "${target_dir}/phpmyadmin/config.sample.inc.php" "${target_dir}/phpmyadmin/config.inc.php"
    sed -i "s|\$cfg\['blowfish_secret'\] = ''|\$cfg['blowfish_secret'] = '${secret}'|" \
        "${target_dir}/phpmyadmin/config.inc.php"

    # Create phpinfo page / 创建 phpinfo 页面
    cat > "${target_dir}/phpinfo.php" <<'EOL'
<?php phpinfo();
EOL

    log_info "phpMyAdmin ${pma_version} installed at ${target_dir}/phpmyadmin"
}

uninstall_phpmyadmin() {
    log_step "Uninstalling phpMyAdmin..."
    log_warn "phpMyAdmin files are in /data/wwwroot/default/phpdir-*/"
    log_warn "Remove them manually to avoid accidental data loss."
    log_info "phpMyAdmin uninstall note displayed"
}
