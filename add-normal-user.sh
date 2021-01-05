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

# Prevent creating user that already exists in system.
guard_user_exists "$username" "$username already exists. Script will skip this."

# Will create user with home directory (-m) define shell (-s).
# /etc/skel contains default home drectory structure.
# Home folder location is /home/<username>
useradd -m -s /bin/bash $username
print_message "$username:$password" | chpasswd

# Will create public web folder to user with simple index.html file.
mkdir /home/$username/public_html

cat > /home/$username/public_html/index.html << EOF
<html>
 <head>
 </head>
 <body>
   <h1>Hello $username<h1>
 </body>
</html>
EOF

# Change right permissions to created folder and files.
chmod 755 -R /home/$username/public_html/
chown $username:$username -R /home/$username/public_html
