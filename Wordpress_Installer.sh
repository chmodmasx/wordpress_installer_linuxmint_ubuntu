#!/bin/bash

echo "   ____  _____                     _       ____              _           "
echo "  / __ \| ____|___ _ __   __ _  __| | __ _|  _ \ _   _ _ __ (_) ___ __ _ "
echo " / / _\` |  _| / __| '_ \ / _\` |/ _\` |/ _\` | |_) | | | | '_ \| |/ __/ _\` |"
echo "| | (_| | |___\__ \ |_) | (_| | (_| | (_| |  _ <| |_| | | | | | (_| (_| |"
echo " \ \__,_|_____|___/ .__/ \__,_|\__,_|\__,_|_| \_\__,__|_| |_|_|\___\__,_|"
echo "  \____/          |_|                                                    "

echo "\n"

install_dir="/var/www/html"
#Creando credenciales de base de datos aleatorias
db_name="wp`date +%s`"
db_user=$db_name
db_password=$(date | md5sum | cut -c '1-12')
mysqlrootpass=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 12)

# Configuramos las respuestas para phpmyadmin
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $mysqlrootpass" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $db_password" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $db_password" | debconf-set-selections

#### Instalar paquetes para https y mysql
apt-get update && apt-get upgrade -y
apt-get install -y apache2 memcached php php-bz2 php-mysqli php-curl php-gd php-intl php-common php-mbstring php-xml php-zip php-imagick php-memcache redis-server php-redis mysql-server phpmyadmin

a2enmod rewrite

# Configuramos Apache para phpMyAdmin
echo "Configurando Apache para phpMyAdmin..."
echo "Include /etc/phpmyadmin/apache.conf" >> /etc/apache2/apache2.conf

#### Borra el directorio html por defecto y habilitamos apache
rm /var/www/html/index.html
systemctl enable apache2
systemctl start apache2

#### iniciamos mysql y seteamos un password
systemctl enable mysql
systemctl start mysql

/usr/bin/mysql -e "USE mysql;"
/usr/bin/mysql -e "UPDATE user SET Password=PASSWORD('$mysqlrootpass') WHERE user='root';"
/usr/bin/mysql -e "FLUSH PRIVILEGES;"
touch /root/.my.cnf
chmod 640 /root/.my.cnf
echo "[client]">>/root/.my.cnf
echo "user=root">>/root/.my.cnf
echo "password="$mysqlrootpass>>/root/.my.cnf

sed -i '0,/AllowOverride\ None/! {0,/AllowOverride\ None/ s/AllowOverride\ None/AllowOverride\ All/}' /etc/apache2/apache2.conf #Allow htaccess usage
sudo sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

systemctl restart apache2

#### Descargamos el último paquete de Wordpress y lo descomprimimos
if test -f /tmp/latest.tar.gz
then
    echo "WP se descargó correctamente."
else
    echo "Descargando WordPress"
    cd /tmp/ && wget "http://wordpress.org/latest.tar.gz"
fi

/bin/tar -C $install_dir -zxf /tmp/latest.tar.gz --strip-components=1
chown www-data: $install_dir -R

#### Creamos una configuración de WP y seteamos las credenciales de la base de datos.
/bin/mv $install_dir/wp-config-sample.php $install_dir/wp-config.php

/bin/sed -i "s/database_name_here/$db_name/g" $install_dir/wp-config.php
/bin/sed -i "s/username_here/$db_user/g" $install_dir/wp-config.php
/bin/sed -i "s/password_here/$db_password/g" $install_dir/wp-config.php

cat << EOF >> $install_dir/wp-config.php
define('FS_METHOD', 'direct');
EOF

cat << EOF >> $install_dir/.htaccess
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index.php$ – [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
EOF

chown www-data: $install_dir -R

##### Configurando WP
grep -A50 'table_prefix' $install_dir/wp-config.php > /tmp/wp-tmp-config
/bin/sed -i '/**#@/,/$p/d' $install_dir/wp-config.php
/usr/bin/lynx --dump -width 200 https://api.wordpress.org/secret-key/1.1/salt/ >> $install_dir/wp-config.php
/bin/cat /tmp/wp-tmp-config >> $install_dir/wp-config.php && rm /tmp/wp-tmp-config -f
/usr/bin/mysql -u root -e "CREATE DATABASE $db_name"
/usr/bin/mysql -u root -e "CREATE USER '$db_user'@'localhost' IDENTIFIED WITH mysql_native_password BY '$db_password';"
/usr/bin/mysql -u root -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';"

### Algunos limites de PHP y WP que recomiendo
sudo sed -i "/define( 'DB_COLLATE', '' );/a define( 'WP_MEMORY_LIMIT', '512M' );" /var/www/html/wp-config.php
sudo sed -i 's/memory_limit = .*/memory_limit = 512M/' /etc/php/8.1/apache2/php.ini
sudo sed -i 's/upload_max_filesize = .*/upload_max_filesize = 4192M/' /etc/php/8.1/apache2/php.ini
sudo sed -i 's/post_max_size = .*/post_max_size = 4192M/' /etc/php/8.1/apache2/php.ini
sudo systemctl restart apache2

######Display generated passwords to log file.
echo "\n"
echo "Aquí tus datos"

echo "Database Name: " $db_name
echo "Database User: " $db_user
echo "Database Password: " $db_password
echo "Mysql root password: " $mysqlrootpass

echo "\n"
echo "Datos phpmyadmin"

echo "User: " $db_user
echo "Password" $db_password

echo "\n"

echo "Ingrese a: http://localhost o bien introduzca su dirección web"
echo "Gracias por utilizar el script de @EspadaRunica"
