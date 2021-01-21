#!/bin/bash

# Script will add new user credentials into htpasswd file.

# =======================
# Define global variables
# =======================

SCRIPT_FILENAME="$0"

# ======================
# Define functions
# ======================

print_message() {
    echo "$1"
}

guard_run_as_root() {
    # Bash skript use some commands that need root permissions.
    if [ "$EUID" -ne 0 ]
        then echo "Please run as root: sudo $SCRIPT_FILENAME -u <username> -p <password> -f <path to csv file>"
        exit
    fi
}

guard_user_not_exists() {
    # $1 parameter is given username.
    # $2 parameter is description that should be printed if user not exists.
    if id "$1" >/dev/null 2>&1; 
    then
        echo "User $1 found."
    else
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

run_add_htpasswd_user_script() {
        global_username=$1
        global_password=$2
        # $3 argument ins the csv file that contain username and other information
        sites_in_file=$3

	# Read site information from csv file.
	# csv -file should have following columns.
	# username;password
	while IFS=';' read -r username password install_wp
	do
            print_message "Handling /home/$username/.htpasswd"
            if [ -z "$username" ]
            then
                print_message "Skip empty line ..."
                continue
            fi

            # Will create .htpasswd and .htaccess files  to protect
            # publich_html folder.
            /opt/bitnami/apache/bin/htpasswd -b /home/$username/.htpasswd $global_username $global_password

            printf "\n- - - - - - - - -\n"

	done < $sites_in_file
}

# ======================
# Main application start.
# ======================

# Read arguments and check mandatory input
while getopts ":u:p:f:" opt; do
    case $opt in
        u) username="$OPTARG"
        ;;
        p) password="$OPTARG"
        ;;
        f) csvfile="$OPTARG"
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
read_mandatory_input "$csvfile" "CSV file not found: sudo $SCRIPT_FILENAME -u <username> -p <password> -f <path to csv file>"

# guard_user_not_exists "$username" "Username not found. Create new user before running the script."

run_add_htpasswd_user_script $username $password $csvfile

print_message "htpasswd credentials created."
