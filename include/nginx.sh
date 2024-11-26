#!/bin/bash

# 安装Nginx
install_nginx() {
  if systemctl is-active --quiet nginx; then
    echo "Nginx 已安装，跳过安装步骤。"
    return
  fi
  
  if [ -f "/etc/nginx/nginx.conf" ]; then
    echo "/etc/nginx/nginx.conf 文件存在,请确认是否需要备份,如需继续安装,请删除该文件,并再次执行安装命令"
    return
  fi
  
  # 添加官方 Nginx 仓库
  echo "deb http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
  curl -fsSL https://nginx.org/keys/nginx_signing.key | sudo apt-key add -
  sudo apt update
  sudo apt install -y nginx

  mkdir -p /etc/nginx/vhost /etc/nginx/ssl /data/logs/nginx_access /data/logs/nginx_error /data/wwwroot/default/phpdir-${randomCode}
  mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.default
  cp config/nginx.conf /etc/nginx/
  sed -i "s|/phpdir/|/phpdir-${randomCode}/|g" /etc/nginx/nginx.conf
  # phpinfo
  sudo tee /data/wwwroot/default/phpdir-${randomCode}/phpinfo.php > /dev/null << EOL
<?php
phpinfo();
EOL

  # phpmyadmin
  wget -c https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip -O /tmp/phpMyAdmin.zip && sudo unzip -o /tmp/phpMyAdmin.zip -d /data/wwwroot/default/phpdir-${randomCode}
  # 生成默认的监听证书,避免默认请求暴露真实域名
  openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/nginx/ssl/dummy.key -out /etc/nginx/ssl/dummy.crt -subj "/CN=localhost"
  
  sudo systemctl restart nginx
  sudo systemctl enable nginx
}
