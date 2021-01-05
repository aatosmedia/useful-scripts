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

# ======================
# Define functions
# ======================

print_message() {
    echo "$1"
}

guard_run_as_root() {
    # Bash skript use some commands that need root permissions.
    if [ "$EUID" -ne 0 ]
        then echo "Please run as root: sudo $SCRIPT_FILENAME -f <path to csv file>"
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

run_add_normal_user_script() {
        # $1 argument ins the csv file that contain username and other information
        sites_in_file=$1

	# Read site information from csv file.
	# csv -file should have following columns.
	# username;password
	while IFS=';' read -r username password 
	do
            print_message "Handling $username"
            if [ -z "$username" ]
            then
                print_message "Skip empty line ..."
                continue
            fi

            ./add-normal-user.sh -u $username -p $password

	done < $sites_in_file
}

# ======================
# Main application start.
# ======================

# Guard checks that prevent running skript without root permissions.
guard_run_as_root

# Read arguments and check mandatory input
while getopts ":f:" opt; do
    case $opt in
    f) csvfile="$OPTARG"
    ;;
    \?) print_message "Invalid option -$OPTARG" >&2
    ;;
    esac
done

# Check all mandatory inputs.
read_mandatory_input "$csvfile" "CSV file not found: sudo $SCRIPT_FILENAME -f <path to csv file>"

# Run the main part of bash script that will create new users using list of usernames in csv file.
run_add_normal_user_script $csvfile

print_message "Script $SCRIPT_FILENAME finished."
