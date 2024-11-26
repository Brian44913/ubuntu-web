#!/bin/bash

# 安装PHP
install_php() {
  if systemctl is-active --quiet php${PHP_VERSION}-fpm; then
    echo "PHP 已安装，跳过安装步骤。"
    return
  fi

  sudo apt install -y software-properties-common
  sudo add-apt-repository ppa:ondrej/php -y
  sudo apt update
  sudo apt install -y php${PHP_VERSION} php${PHP_VERSION}-fpm php${PHP_VERSION}-mysql php${PHP_VERSION}-redis php${PHP_VERSION}-fileinfo php${PHP_VERSION}-opcache php${PHP_VERSION}-curl php${PHP_VERSION}-mbstring
  # sudo apt install -y php${PHP_VERSION}-pgsql

  # 配置 PHP-FPM
  sudo tee /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf > /dev/null <<EOT
[www]
user = www
group = www
listen = /run/php/php${PHP_VERSION}-fpm.sock
listen.owner = www
listen.group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 4
pm.min_spare_servers = 2
pm.max_spare_servers = 6
EOT

  
  sudo systemctl restart php${PHP_VERSION}-fpm
  sudo systemctl enable php${PHP_VERSION}-fpm
}

