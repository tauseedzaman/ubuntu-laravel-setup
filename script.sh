#!/bin/bash

# Function to print messages in different colors
print_message() {
    COLOR=$1
    MESSAGE=$2
    case $COLOR in
    green)
        echo -e "\e[32m[+] $MESSAGE\e[0m"
        ;;
    red)
        echo -e "\e[31m[-] $MESSAGE\e[0m"
        ;;
    yellow)
        echo -e "\e[33m[*] $MESSAGE\e[0m"
        ;;
    *)
        echo -e "$MESSAGE"
        ;;
    esac
}

# Check for --interactive  flag
INTERACTIVE=false
for arg in "$@"; do
    if [ "$arg" == "--interactive" ]; then
        INTERACTIVE=true
        break
    fi
done

# Function to install packages
install_package() {
    PACKAGE=$1
    if $INTERACTIVE; then
        read -p "Do you want to install $PACKAGE? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_message "yellow" "Skipping $PACKAGE installation."
            return
        fi
    fi
    sudo apt install -y $PACKAGE && print_message "green" "$PACKAGE installed successfully." || print_message "red" "$PACKAGE installation failed."
}

# Database configuration
if $INTERACTIVE; then
    read -p "Enter database host: " DB_HOST
    read -p "Enter database port: " DB_PORT
    read -p "Enter database name: " DB_NAME
    read -p "Enter database user: " DB_USER
    read -sp "Enter database password: " DB_PASS
    echo
else
    DB_HOST="127.0.0.1"
    DB_PORT="3306"
    DB_NAME="laravel_db"
    DB_USER="laravel_db_user"
    DB_PASS="laravel_db_pass"
fi

# Set DEBIAN_FRONTEND to noninteractive
export DEBIAN_FRONTEND=noninteractive

# Update package list and upgrade installed packages
print_message "yellow" "Updating package list and upgrading installed packages..."
sudo apt update && sudo apt upgrade -y

# Install Apache, MySQL (or MariaDB), and PHP
install_package "apache2"
install_package "mysql-server"
install_package "php"
install_package "php-mysql"

# Enable Apache modules
print_message "yellow" "Enabling Apache rewrite module..."
sudo a2enmod rewrite
sudo systemctl restart apache2 && print_message "green" "Apache restarted successfully." || print_message "red" "Failed to restart Apache."

# Install MySQL server and secure it
print_message "yellow" "Installing and securing MySQL server..."
install_package "mysql-server"
mysql_secure_installation <<EOF

y
$DB_PASS
$DB_PASS
y
y
y
y
EOF
mysql -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;" && print_message "green" "Database $DB_NAME created." || print_message "red" "Failed to create database $DB_NAME."
mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';" && print_message "green" "User $DB_USER created." || print_message "red" "Failed to create user $DB_USER."
mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost' WITH GRANT OPTION;" && print_message "green" "Privileges granted to $DB_USER." || print_message "red" "Failed to grant privileges to $DB_USER."
mysql -e "FLUSH PRIVILEGES;" && print_message "green" "Privileges flushed." || print_message "red" "Failed to flush privileges."

# Install Node.js and npm
print_message "yellow" "Installing Node.js and npm..."
curl -sL https://deb.nodesource.com/setup_21.x | sudo -E bash -
install_package "nodejs"

# Install Certbot for SSL
print_message "yellow" "Installing Certbot for SSL..."
install_package "certbot"
install_package "python3-certbot-apache"

# Install Supervisor
print_message "yellow" "Installing Supervisor..."
install_package "supervisor"

# Install Redis
print_message "yellow" "Installing Redis..."
install_package "redis-server"
sudo systemctl enable redis-server.service && print_message "green" "Redis enabled." || print_message "red" "Failed to enable Redis."

# Ready
install_package "composer"
install_package "php8.3-xml"
install_package "php8.3-gd"

# Restart Apache to apply changes
print_message "yellow" "Enabling and restarting Apache to apply changes..."
sudo systemctl enable apache2
sudo systemctl reload apache2
sudo systemctl restart apache2 && print_message "green" "Apache restarted successfully." || print_message "red" "Failed to restart Apache."

# Install UFW firewall
print_message "yellow" "Installing UFW firewall..."
install_package "ufw"
sudo ufw allow 'Apache Full'
sudo ufw enable && print_message "green" "UFW firewall enabled." || print_message "red" "Failed to enable UFW firewall."
