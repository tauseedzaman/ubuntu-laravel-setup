#!/bin/bash

# Database configuration
DB_HOST="127.0.0.1"
DB_PORT="3306"
DB_NAME="dbname"
DB_USER="dbname_user"
DB_PASS="dbname_pass"

# Set DEBIAN_FRONTEND to noninteractive
export DEBIAN_FRONTEND=noninteractive

# Update package list and upgrade installed packages
sudo apt update
sudo apt upgrade -y

# Install Apache, MySQL (or MariaDB), and PHP
sudo apt install -y apache2 mysql-server php php-mysql

# Enable Apache modules
sudo a2enmod rewrite
sudo systemctl restart apache2

# Install MySQL server and secure it
apt install mysql-server -y
mysql_secure_installation <<EOF

y
$DB_PASS
$DB_PASS
y
y
y
y
EOF
mysql -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost' WITH GRANT OPTION;"
mysql -e "FLUSH PRIVILEGES;"

# ready
sudo apt install composer -y
sudo apt-get install php8.3-xml
sudo apt-get install php8.3-gd

# Restart Apache to apply changes
systemctl enable apache2
systemctl reload apache2
systemctl restart apache2
