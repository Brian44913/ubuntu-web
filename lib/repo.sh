#!/bin/bash
# lib/repo.sh - Modern APT repository management using signed-by
# 使用 signed-by 方式管理 APT 仓库（替代已废弃的 apt-key add）

readonly KEYRINGS_DIR="/usr/share/keyrings"

# Add GPG key to keyring / 添加 GPG key 到 keyring
# Usage: add_gpg_key <key_url> <keyring_name>
add_gpg_key() {
    local key_url="$1"
    local keyring_name="$2"
    local keyring_path="${KEYRINGS_DIR}/${keyring_name}.gpg"

    if [[ -f "${keyring_path}" ]]; then
        log_info "GPG keyring already exists: ${keyring_path}"
        return 0
    fi

    log_step "Adding GPG key: ${keyring_name}"
    curl -fsSL "${key_url}" | gpg --dearmor -o "${keyring_path}"
    chmod 644 "${keyring_path}"
}

# Add APT repository with signed-by / 添加 APT 仓库源
# Usage: add_apt_repo <repo_name> <repo_line> <keyring_name>
add_apt_repo() {
    local repo_name="$1"
    local repo_line="$2"
    local keyring_name="$3"
    local keyring_path="${KEYRINGS_DIR}/${keyring_name}.gpg"
    local list_path="/etc/apt/sources.list.d/${repo_name}.list"

    log_step "Adding APT repository: ${repo_name}"
    echo "deb [signed-by=${keyring_path}] ${repo_line}" > "${list_path}"
}

# Remove APT repository and keyring / 移除 APT 仓库源和 keyring
# Usage: remove_apt_repo <repo_name> <keyring_name>
remove_apt_repo() {
    local repo_name="$1"
    local keyring_name="$2"

    rm -f "/etc/apt/sources.list.d/${repo_name}.list"
    rm -f "${KEYRINGS_DIR}/${keyring_name}.gpg"
    log_info "Removed repository: ${repo_name}"
}
