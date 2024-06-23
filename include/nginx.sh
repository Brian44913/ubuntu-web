#!/bin/bash

# 安装Nginx
install_nginx() {
  if systemctl is-active --quiet nginx; then
    echo "Nginx 已安装，跳过安装步骤。"
    return
  fi

  sudo apt install -y nginx

  # 配置 Nginx
  sudo tee /etc/nginx/sites-available/default > /dev/null << EOL
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL

  # 启用 stream 模式
  sudo tee -a /etc/nginx/nginx.conf > /dev/null << EOL
stream {
    upstream mysql_backend {
        server 127.0.0.1:3306;
    }

    server {
        listen 33060;
        proxy_pass mysql_backend;
    }
}
EOL

  sudo systemctl restart nginx
  sudo systemctl enable nginx
}
