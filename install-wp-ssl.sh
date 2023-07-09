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

# Email address validation
if ! [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    echo "Invalid email address format."
    exit 1
fi

# Update the system
apt update && apt upgrade -y

# Install dependencies (Apache, PHP, MySQL, and other required packages)
apt install -y apache2 php mysql-server php-mysql libapache2-mod-php php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip unzip

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

# Install Certbot and obtain SSL certificate
apt install -y certbot python3-certbot-apache
certbot --apache --non-interactive --agree-tos -d $domain --email $email

# Clean up
apt autoremove -y

echo "WordPress installation and configuration completed successfully!"
echo "Domain: $domain"
echo "Email: $email"
echo "Database Name: $db_name"
echo "Database User: $db_user"
echo "Database Password: $db_password"
