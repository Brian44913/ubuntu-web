#!/bin/bash

# Check if user is root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }

# 设置非交互模式
export DEBIAN_FRONTEND=noninteractive

# include
. ./include/nginx.sh
. ./include/mysql.sh
. ./include/php.sh
. ./include/redis.sh

# 定义版本
PHP_VERSION="8.3"
MYSQL_VERSION="8.0"
NGINX_VERSION="1.26.2"
REDIS_VERSION="7.2"

# 初始化参数
DB_PASSWORD=""
INSTALL_COMPONENTS=()

# 生成随机MD5值
randomCode=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 | md5sum | awk '{print $1}')

# 解析参数
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --dbpasswd)
    DB_PASSWORD="$2"
    shift 2
    ;;
    *)
    IFS=',' read -ra ADDR <<< "$1"
    for i in "${ADDR[@]}"; do
      INSTALL_COMPONENTS+=("$i")
    done
    shift
    ;;
  esac
done

# 如果未指定组件，给出提示
if [ ${#INSTALL_COMPONENTS[@]} -eq 0 ]; then
  echo "Usage: $0 [components] [--dbpasswd PASSWORD]"
  echo "Components: nginx, mysql, php, redis"
  exit 0
fi

# 检查是否需要安装 MySQL 且是否提供了 --dbpasswd 参数
if [[ " ${INSTALL_COMPONENTS[@]} " =~ " mysql " ]] && [ -z "$DB_PASSWORD" ]; then
  echo "错误：必须指定 --dbpasswd 参数，例如 --dbpasswd 123456"
  exit 1
fi

# 更新系统
sudo apt update -y
sudo apt upgrade -y

# 安装必要的依赖
sudo apt install -y build-essential libpcre3 libpcre3-dev zlib1g-dev libssl-dev libxml2-dev libcurl4-openssl-dev libjpeg-dev libpng-dev libwebp-dev libfreetype6-dev libonig-dev libzip-dev cmake libncurses5-dev pkg-config wget unzip

# 创建用户和组
id -u mysql >/dev/null 2>&1 || sudo useradd -M -s /sbin/nologin mysql
id -u www >/dev/null 2>&1 || sudo useradd -M -s /sbin/nologin www

# 检查服务状态
check_service_status() {
  services=("mysql" "php${PHP_VERSION}-fpm" "nginx" "redis-server")

  for service in "${services[@]}"; do
    systemctl is-active --quiet ${service}
    if [ $? -eq 0 ]; then
      echo "${service} is running."
    else
      echo "${service} is not running or failed to start."
    fi
  done
}

# 主程序
main() {
  for component in "${INSTALL_COMPONENTS[@]}"; do
    case $component in
      mysql)
        install_mysql "$DB_PASSWORD"
        ;;
      php)
        install_php
        ;;
      nginx)
        install_nginx
        ;;
      redis)
        install_redis
        ;;
      *)
        echo "无效的组件: $component"
        echo "有效组件: mysql, php, nginx, redis"
        ;;
    esac
  done

  echo "所有组件安装和配置完成。"
  echo "随机生成的MD5值为: $randomCode"
  check_service_status
}

main
