#!/bin/bash

# Script will create new user account with default configurations.

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
        then echo "Please run as root: sudo $SCRIPT_FILENAME -u <username> -p <password>"
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

guard_user_not_exists "$username" "Username not found. Create new user before running the script."

# Will create .htpasswd and .htaccess files  to protect
# publich_html folder.
/opt/bitnami/apache/bin/htpasswd -cb /home/$username/.htpasswd $username $password

cat > /home/$username/public_html/.htaccess << EOF
AuthType Basic
AuthName "Authentication required"
Require valid-user
AuthUserFile "/home/$username/.htpasswd"
EOF

# Change right permissions to created folder and files.
chmod 644 -R /home/$username/.htpasswd
chown $username:$username -R /home/$username/.htpasswd

chmod 770 -R /home/$username/public_html/
chown daemon:daemon -R /home/$username/public_html

print_message "Protected public_html with basic auth."
