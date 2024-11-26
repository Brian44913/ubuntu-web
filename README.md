# ubuntu-web
One-click installation of php+mysql+nginx+mysql+redis environment for Ubuntu22.04, all installed through apt

```
git clone https://github.com/Brian44913/ubuntu-web && \
cd ubuntu-web && \
bash install.sh nginx,php,mysql,redis --dbpasswd 123456
```
#### nginx
```
/etc/nginx/nginx.conf
/etc/nginx/vhost/

systemctl restart nginx
```
#### php
```
/etc/php/8.3/fpm/php.ini
/etc/php/8.3/cli/php.ini

systemctl restart php8.3-fpm
```
#### mysql
```
!includedir /etc/mysql/conf.d/
!includedir /etc/mysql/mysql.conf.d/

```
* mysql 默认无密码可以直接登录
* 查看用户列表
```
use mysql;
SELECT user, host, plugin FROM mysql.user;
```
* 修改root密码
```
ALTER USER 'root'@'localhost' IDENTIFIED BY '<new_password>';
FLUSH PRIVILEGES;
```
* 取消免密登录
```
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'your_password';
FLUSH PRIVILEGES;
```
* 创建 root@127.0.0.1
```
CREATE USER 'root'@'127.0.0.1' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```
