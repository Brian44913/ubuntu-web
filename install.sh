#!/bin/bash

# Check if user is root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }

# 设置非交互模式
export DEBIAN_FRONTEND=noninteractive

# include
. ./include/apache.sh
. ./include/nginx.sh
. ./include/mysql.sh
. ./include/php.sh
. ./include/redis.sh

# 定义版本
PHP_VERSION="8.3"
MYSQL_VERSION="8.0"
APACHE_VERSION="2.4"
NGINX_VERSION="1.26"
REDIS_VERSION="7.2"

# 检查是否提供了 --dbpasswd 参数
DB_PASSWORD=""
ARGS=()

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --dbpasswd)
    DB_PASSWORD="$2"
    shift 2
    ;;
    *)
    ARGS+=("$1")
    shift
    ;;
  esac
done

if [ -z "$DB_PASSWORD" ]; then
  echo "错误：必须指定 --dbpasswd 参数，例如 --dbpasswd 123456"
  exit 1
fi

# 更新系统
sudo apt update -y
sudo apt upgrade -y

# 安装必要的依赖
sudo apt install -y build-essential libpcre3 libpcre3-dev zlib1g-dev libssl-dev libxml2-dev libcurl4-openssl-dev libjpeg-dev libpng-dev libwebp-dev libfreetype6-dev libonig-dev libzip-dev cmake libncurses5-dev pkg-config wget

# 创建用户和组
id -u mysql >/dev/null 2>&1 || sudo useradd -M -s /sbin/nologin mysql
id -u www >/dev/null 2>&1 || sudo useradd -M -s /sbin/nologin www

# 检查服务状态
check_service_status() {
  services=("mysql" "php${PHP_VERSION}-fpm" "apache2" "nginx" "redis-server")

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
  if [ ${#ARGS[@]} -eq 0 ]; then
    echo "安装所有组件..."
    install_mysql "$DB_PASSWORD"
    install_php
    install_apache
    install_nginx
    install_redis
  else
    for arg in "${ARGS[@]}"; do
      case $arg in
        mysql)
          install_mysql "$DB_PASSWORD"
          ;;
        php)
          install_php
          ;;
        apache)
          install_apache
          ;;
        nginx)
          install_nginx
          ;;
        redis)
          install_redis
          ;;
        *)
          echo "无效的参数: $arg"
          echo "有效参数: mysql, php, apache, nginx, redis"
          ;;
      esac
    done
  fi

  echo "所有组件安装和配置完成。"
  check_service_status
}

main