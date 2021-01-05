#!/bin/bash

# 
# Script to install multiple Wordpress instances into single web server.
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
	while IFS=';' read -r username password install_wp
	do
            print_message "Handling $username"
            if [ -z "$username" ]
            then
                print_message "Skip empty line ..."
                continue
            fi

            ./add-normal-user.sh -u $username -p $password

            if [ -z "$install_wp" ]
            then
                # variable install_wp was empty
                print_message "Skip wp installation ..."
            else
		if [ "$install_wp" == "wp" ]; then
                    print_message "Install wp for user ..."
                    ./add-wp-for-user.sh -u $username -p $password
                fi
    	    fi

            printf "\n- - - - - - - - -\n"

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
