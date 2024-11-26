#!/bin/bash

install_apache() {
  if systemctl is-active --quiet apache2; then
    echo "Apache 已安装，跳过安装步骤。"
    return
  fi
  
  if [ -f "/etc/apache2/apache2.conf" ]; then
    echo "/etc/apache2/apache2.conf 文件存在,请确认是否需要备份,如需继续安装,请删除该文件,并再次执行安装命令"
    return
  fi

  # 添加 ondrej/apache2 PPA 以获取较新的 Apache 版本
  sudo add-apt-repository ppa:ondrej/apache2 -y
  sudo apt update

  sudo apt install -y apache2 libapache2-mod-fcgid
  sudo a2enmod proxy_fcgi setenvif
  sudo a2enconf php${PHP_VERSION}-fpm
  sudo a2enmod mpm_event

  # 配置 Apache 使用 PHP-FPM
  sudo tee /etc/apache2/sites-available/000-default.conf > /dev/null <<EOT
<VirtualHost *:88>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    <FilesMatch \.php$>
        SetHandler "proxy:unix:/run/php/php${PHP_VERSION}-fpm.sock|fcgi://localhost/"
    </FilesMatch>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOT

  sudo sed -i 's/Listen 80/Listen 88/' /etc/apache2/ports.conf
  mkdir -p /etc/apache2/vhost /data/logs/apache_access /data/logs/apache_error
  mv /etc/apache2/apache2.conf /etc/apache2/apache2.conf.default
  cp config/apache2.conf /etc/apache2/

  sudo systemctl restart apache2
  sudo systemctl enable apache2
}
