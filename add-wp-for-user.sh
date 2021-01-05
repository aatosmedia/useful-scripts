#!/bin/bash

# Script to install multiple Wordpress instances into single web server.
# 
# TODO: If using bitnami lamp stack, disable pagespeed module because can confuse students when js/css files are cached.
# https://docs.bitnami.com/bch/apps/wordpress/administration/use-pagespeed/
#
# REQUIREMENTS 
# 
# LAMP environment installed. Script is tested with Bitnami LAMP stack.
# https://bitnami.com/stack/lamp
# 
# Script will contain one Bitnami specific step. The last line, 'set_directory_permissions'
# is optional and work only in Bitnami environment.
#
# EXAMPLE OF USAGE
#
# Run script in working directory that will hold the public wordpress sites.
# htdocs or www -folder for example.
#
# > wp.sh -f mycsvfile.csv
#
# mycsvfile should have following content without header columns. Script will
# read all rows and create multiple sites.
#
# username,password 
#
# Given information is used to create all credentials for website and database.
#
# IMPORTANT
#
# When script connect to database, it use mysql command. It will use current session
# user. You should create my.cnf file in to home directory and set mysql credentials
# that have rights to create new users and databases.
#
# my.cnf content:
#
# [client]
# user=dbuser
# password=dbpass
#
# MOTIVATION
# 
# Script was made for set up multiple Wordpress instances for students. It should be easy
# to configurate any needs. You only need single web server and then environments is
# ready for teaching Wordpress. The script is not for production usage.
# 
# AUTHOR
#
# Turo Nylund (turo.nylund@outlook.com) 
#

# =======================
# Define global variables
# =======================

SCRIPT_FILENAME=$0
CURRENT_DIR=$(pwd)
MACHINE_PUBLIC_IP=$(curl -s https://api.ipify.org)

# ======================
# Define functions
# ======================

print_message() {
	echo "$1"
}

guard_run_as_root() {
    # Bash skript use some commands that need root permissions.
    if [ "$EUID" -ne 0 ]
        then echo "Please run as root: sudo $SCRIPT_FILENAME -u <username> -p <password>"
        exit
    fi
}

guard_user_exists() {
    # $1 parameter is given username.
    # $2 parameter is description that should be printed if user exists.
    if id "$1" >/dev/null 2>&1; then
        echo "$2"
        exit
    fi
}

read_mandatory_input() {
    # $1 parameter is given username.
    # $2 parameter is description that should be printed if input not given.
    if [ -z "$1" ]
    then
        print_message "$2"
        exit
    fi
}

create_database_with_user() {
    # $1 is user to create
    # $2 is password for user
    # $3 is database name
    SQL_COMMAND="CREATE DATABASE ${3} /*!40100 COLLATE \"utf8_general_ci\" */;"
    SQL_COMMAND+="CREATE USER '${1}'@'%' IDENTIFIED BY '${2}';"
    SQL_COMMAND+="GRANT USAGE ON *.* TO '${1}'@'%';"
    SQL_COMMAND+="GRANT SELECT, EXECUTE, SHOW VIEW, ALTER, ALTER ROUTINE, CREATE, CREATE ROUTINE, CREATE TEMPORARY TABLES, CREATE VIEW, DELETE, DROP, EVENT, INDEX, INSERT, REFERENCES, TRIGGER, UPDATE  ON ${3}.* TO '${1}'@'%';"
    SQL_COMMAND+="FLUSH PRIVILEGES;"

    # Uncomment if you want to debug SQL command.
    # print_message "$SQL_COMMAND"

    mysql --execute="$SQL_COMMAND"
}

wordpress_modify_configs() {
	site=$1
        dbuser=$2 
        dbpass=$3 
        dbname=$4

	#create wp config
	cp ./$site/wp-config-sample.php ./$site/wp-config.php

	# will define FS_METHOD type.
	# FS_METHOD This setting forces the filesystem (or connection) method.
	# direct means that plugins can be installed without ftp connection 
	sed -i -e "/DB_COLLATE/a\define(\'FS_METHOD\', \'direct\');" ./$site/wp-config.php 
}

install_wordpress_site() {
    # $1 argument is site admin username
    # $2 argument is password for site
    # $3 argument is site path
    # $4 argument is site name
    # $5 argument is database name
    # $6 argument is database username
    # $7 argument is database password

    run_as_user="$1"
    site_admin_username="$1"
    site_admin_password="$2"
    site_name="$3"
    site_path="$4"
    dbname="$5"
    dbusername="$6"
    dbpassword="$7"

    # Bash script for checking whether WordPress is installed or not
    if ! $(sudo -u $run_as_user -i -- wp-cli core is-installed --path="$site_path")
    then
        create_database_with_user $dbusername $dbpassword $dbname

        print_message "Database \"$dbname\" created"

        sudo -u $run_as_user -i -- wp-cli core download --path="$site_path"
        sudo -u $run_as_user -i -- wp-cli config create --path="$site_path" --dbname="$dbname" --dbuser="$dbusername" --dbhost="127.0.0.1" --dbpass="$dbpassword"
        sudo -u $run_as_user -i -- wp-cli core install --path="$site_path" --url="http://$MACHINE_PUBLIC_IP/~$site_name/wp" --title="My Wordpress site" --admin_user="$site_admin_username" --admin_email="$site_admin_username@mailinator.com" --admin_password="$site_admin_password" --skip-email

        print_message "Wordpress installation for $username completed. Site url is http://$MACHINE_PUBLIC_IP/~$site_name/wp"
    else
        print_message "Wordpress installation found in $site_path. Skip installation."
    fi

}

# ======================
# Main application start.
# ======================

# Read arguments and check mandatory input
while getopts ":u:p:" opt; do
    case $opt in
        u) username="$OPTARG"
        ;;
        p) password="$OPTARG"
        ;;
        \?) print_message "Invalid option -$OPTARG" >&2
        ;;
    esac
done

# Guard clauses check that skript is run with needed permissions.
guard_run_as_root

# Check that all mandatory arguments are given.
read_mandatory_input "$username" "Username not given: sudo $SCRIPT_FILENAME -u <username>"
read_mandatory_input "$password" "Password not given: sudo $SCRIPT_FILENAME -u <username> -p <password>"

site_admin_username="$username"
site_admin_password="$password"
site_name="$username"
site_path="/home/$username/public_html/wp"
dbname="wp_$username"
dbusername="$username"
dbpassword="$password"

if ! command -v wp-cli &> /dev/null
then
    print_message "wp-cli command not found. Check that the tool is installed and can be executed using command wp-cli."
    print_message "INFO: Trying to install WP-CLI tool now. Read more https://wp-cli.org/"
    wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    sudo mv wp-cli.phar /usr/local/bin/wp-cli
    sudo chmod +x /usr/local/bin/wp-cli
fi

print_message "A robot is now installing WordPress sites for you."

#download_wordpress_and_unzip
install_wordpress_site $site_admin_username $site_admin_password $site_name $site_path $dbname $dbusername $dbpassword
