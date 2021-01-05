#!/bin/bash

# Script will create mysql database for user.
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
        then echo "Please run as root: sudo $SCRIPT_FILENAME -u <db username> -p <db password> -n <db name>"
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
    SQL_COMMAND+="CREATE USER IF NOT EXISTS '${1}'@'%' IDENTIFIED BY '${2}';"
    SQL_COMMAND+="GRANT USAGE ON *.* TO '${1}'@'%';"
    SQL_COMMAND+="GRANT SELECT, EXECUTE, SHOW VIEW, ALTER, ALTER ROUTINE, CREATE, CREATE ROUTINE, CREATE TEMPORARY TABLES, CREATE VIEW, DELETE, DROP, EVENT, INDEX, INSERT, REFERENCES, TRIGGER, UPDATE  ON ${3}.* TO '${1}'@'%';"
    SQL_COMMAND+="FLUSH PRIVILEGES;"

    # Uncomment if you want to debug SQL command.
    # print_message "$SQL_COMMAND"

    mysql --execute="$SQL_COMMAND"
}

# ======================
# Main application start.
# ======================

# Read arguments and check mandatory input
while getopts ":u:p:n:" opt; do
    case $opt in
        u) username="$OPTARG"
        ;;
        p) password="$OPTARG"
        ;;
        n) dbname="$OPTARG"
        ;;
        \?) print_message "Invalid option -$OPTARG" >&2
        ;;
    esac
done

# Guard clauses check that skript is run with needed permissions.
guard_run_as_root

# Check that all mandatory arguments are given.
read_mandatory_input "$username" "Username not given: sudo $SCRIPT_FILENAME -u <db username>"
read_mandatory_input "$password" "Password not given: sudo $SCRIPT_FILENAME -u <db username> -p <db password>"
read_mandatory_input "$dbname" "Database name not given: sudo $SCRIPT_FILENAME -u <db username> -p <db password> -n <db name>"

db_username="$username"
db_password="$password"
db_name="$dbname"

print_message "Creating database for user"
create_database_with_user $db_username $db_password $db_name
