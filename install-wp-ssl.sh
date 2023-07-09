#!/bin/bash

# Check if running with root/sudo privileges
if [[ $EUID -ne 0 ]]; then
    echo "This script needs to be run with root/sudo privileges."
    exit 1
fi

# Check if a domain and email parameters are passed
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Please provide the domain and email address as parameters to the script."
    echo "Example: sudo ./wordpress_install.sh your_domain.com your_email@example.com"
    exit 1
fi

domain="$1"
email="$2"

# PHP version selection
php_version="${3:-8.1}"

# Email address validation
if ! [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    echo "Invalid email address format."
    exit 1
fi

# Update the system
apt update && apt upgrade -y

# Install dependencies (Apache, PHP, MySQL, and other required packages)
apt install -y apache2 php$php_version mysql-server php$php_version-mysql libapache2-mod-php$php_version php$php_version-curl php$php_version-gd php$php_version-mbstring php$php_version-xml php$php_version-xmlrpc php$php_version-soap php$php_version-intl php$php_version-zip unzip

# Enable Apache modules
a2enmod rewrite
a2enmod ssl

# Restart Apache
systemctl restart apache2

# Clear /var/www/html folder
rm -rf /var/www/html/*

# Download and extract the latest WordPress
wget -P /var/www/html/ https://wordpress.org/latest.tar.gz
tar -xzvf /var/www/html/latest.tar.gz -C /var/www/html/
mv /var/www/html/wordpress/* /var/www/html/
rm -rf /var/www/html/wordpress

# Set proper permissions
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/

# Create a random database name, username, and password
db_name="wordpress_$(openssl rand -hex 5)"
db_user="wpuser_$(openssl rand -hex 5)"
db_password="$(openssl rand -hex 10)"

# Create a new MySQL database
mysql -e "CREATE DATABASE $db_name;"
mysql -e "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_password';"
mysql -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Replace database credentials in wp-config.php
sed -i "s/database_name_here/$db_name/g" /var/www/html/wp-config-sample.php
sed -i "s/username_here/$db_user/g" /var/www/html/wp-config-sample.php
sed -i "s/password_here/$db_password/g" /var/www/html/wp-config-sample.php
mv /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

# Update PHP configuration
php_ini_file="/etc/php/$php_version/apache2/php.ini"
echo "upload_max_filesize = 256M" >> "$php_ini_file"
echo "post_max_size = 256M" >> "$php_ini_file"
echo "memory_limit = 512M" >> "$php_ini_file"
echo "max_execution_time = 180" >> "$php_ini_file"

# Restart Apache
systemctl restart apache2

# Clean up
apt autoremove -y

echo "WordPress installation and configuration completed successfully!"
echo "Domain: $domain"
echo "Email: $email"
echo "PHP Version: $php_version"
echo "Database Name: $db_name"
echo "Database User: $db_user"
echo "Database Password: $db_password"
