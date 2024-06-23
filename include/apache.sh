#!/bin/bash

install_apache() {
  if systemctl is-active --quiet apache2; then
    echo "Apache 已安装，跳过安装步骤。"
    return
  fi

  sudo apt install -y apache2 libapache2-mod-fcgid
  sudo a2enmod proxy_fcgi setenvif
  sudo a2enconf php${PHP_VERSION}-fpm
  sudo a2enmod mpm_event

  # 配置 Apache 使用 PHP-FPM
  sudo tee /etc/apache2/sites-available/000-default.conf > /dev/null <<EOT
<VirtualHost *:8080>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    <FilesMatch \.php$>
        SetHandler "proxy:unix:/run/php/php${PHP_VERSION}-fpm.sock|fcgi://localhost/"
    </FilesMatch>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOT

  sudo sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf

  sudo systemctl restart apache2
  sudo systemctl enable apache2
}
