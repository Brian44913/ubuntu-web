#!/bin/bash

install_redis() {
  if systemctl is-active --quiet redis-server; then
    echo "Redis 已安装，跳过安装步骤。"
    return
  fi

  sudo apt install -y redis-server
  sudo systemctl restart redis-server
  sudo systemctl enable redis-server
}
