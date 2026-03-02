#!/bin/bash
# lib/os.sh - OS detection and validation
# 操作系统检测与验证

readonly REQUIRED_OS="ubuntu"
readonly REQUIRED_VERSION="24.04"
readonly REQUIRED_CODENAME="noble"

check_os() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot detect OS: /etc/os-release not found"
        exit 1
    fi

    # shellcheck source=/dev/null
    source /etc/os-release

    if [[ "${ID}" != "${REQUIRED_OS}" ]]; then
        log_error "This script only supports Ubuntu. Detected: ${ID}"
        exit 1
    fi

    if [[ "${VERSION_ID}" != "${REQUIRED_VERSION}" ]]; then
        log_error "This script requires Ubuntu ${REQUIRED_VERSION} (${REQUIRED_CODENAME}). Detected: ${VERSION_ID}"
        exit 1
    fi

    log_info "OS check passed: ${PRETTY_NAME}"
}
