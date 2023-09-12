#!/bin/bash

echo "   ____  _____                     _       ____              _           "
echo "  / __ \| ____|___ _ __   __ _  __| | __ _|  _ \ _   _ _ __ (_) ___ __ _ "
echo " / / _\` |  _| / __| '_ \ / _\` |/ _\` |/ _\` | |_) | | | | '_ \| |/ __/ _\` |"
echo "| | (_| | |___\__ \ |_) | (_| | (_| | (_| |  _ <| |_| | | | | | (_| (_| |"
echo " \ \__,_|_____|___/ .__/ \__,_|\__,_|\__,_|_| \_\__,__|_| |_|_|\___\__,_|"
echo "  \____/          |_|                                                    "

echo "\n"

echo "Le pedira una contraseña a lo largo de la instalación, puede presionar Enter simplemente"
echo "\n"
read -p "Ingrese su nombre de dominio (por ejemplo mintlatam.com): " DOMAIN_USER

DB_NAME="wp$(date +%s)"
DB_USER="$DB_NAME"
DB_PASSWORD=$(openssl rand -base64 12 | tr -d '+/' | head -c 1; openssl rand -base64 11)
DOMAIN="$DOMAIN_USER"


# Actualizar el sistema
#sudo apt update -y
#sudo apt upgrade -y

# Instalar Nginx
#apt install nginx -y
#systemctl enable nginx
#systemctl start nginx

# Instalar MySQL Server
#apt install mysql-server -y
mysql_secure_installation <<EOF

y
$DB_PASSWORD
$DB_PASSWORD
y
y
y
y
EOF

# Instalar PHP 8.1 y extensiones
#apt install php8.1-fpm php8.1 php8.1-common php8.1-mysql php8.1-xml php8.1-xmlrpc php8.1-curl php8.1-gd php8.1-imagick php8.1-cli php8.1-imap php8.1-mbstring php8.1-opcache php8.1-soap php8.1-zip php8.1-intl php8.1-bcmath unzip memcached php8.1-memcache redis php8.1-redis -y

# Configurar PHP
sed -i 's/upload_max_filesize =.*/upload_max_filesize = 1024M/' /etc/php/8.1/fpm/php.ini
sed -i 's/post_max_size =.*/post_max_size = 1200M/' /etc/php/8.1/fpm/php.ini
sed -i 's/memory_limit =.*/memory_limit = 512M/' /etc/php/8.1/fpm/php.ini
sed -i 's/max_execution_time =.*/max_execution_time = 600/' /etc/php/8.1/fpm/php.ini
sed -i 's/max_input_vars =.*/max_input_vars = 3000/' /etc/php/8.1/fpm/php.ini
sed -i 's/max_input_time =.*/max_input_time = 1000/' /etc/php/8.1/fpm/php.ini

# Reiniciar PHP-FPM
service php8.1-fpm restart

# Configurar Nginx
rm -rf /etc/nginx/sites-enabled/default
rm -rf /etc/nginx/sites-available/default

# Crear configuración de Nginx para WordPress y redirigirla al archivo
cat <<EOF | sudo tee /etc/nginx/sites-available/$DOMAIN > /dev/null
server {
    listen 80;
    listen [::]:80;
    root /var/www/html;
    index index.php index.html index.htm;
    server_name $DOMAIN www.$DOMAIN;

    client_max_body_size 500M;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
        expires max;
        log_not_found off;
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF

# Habilitar el sitio en Nginx
ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/

# Reiniciar Nginx
systemctl restart nginx

# Crear la base de datos y usuario de WordPress
mysql -u root -p <<MYSQL_SCRIPT
CREATE DATABASE $DB_NAME;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
exit
MYSQL_SCRIPT

# Descargar e instalar WordPress
cd /var/www/html
wget https://wordpress.org/latest.tar.gz
tar -zxvf latest.tar.gz --strip-components=1
rm -f latest.tar.gz
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/
rm /var/www/html/index.nginx-debian.html

# Configurar wp-config.php
mv /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sed -i "s/database_name_here/$DB_NAME/" /var/www/html/wp-config.php
sed -i "s/username_here/$DB_USER/" /var/www/html/wp-config.php
sed -i "s/password_here/$DB_PASSWORD/" /var/www/html/wp-config.php

# Mostrar las contraseñas generadas en el archivo de registro
echo "Aquí tus datos:"
echo "Database Name: $DB_NAME"
echo "Database User: $DB_USER"
echo "Database Password: $DB_PASSWORD"

echo "Instalación de WordPress completada. Accede a tu sitio en http://$DOMAIN"

echo "Gracias por utilizar el script de @EspadaRunica"
