#!/bin/bash

SCRIPT_FILENAME=$0

# Read arguments and check mandatory input
while getopts ":p:" opt; do
    case $opt in
    p) password="$OPTARG"
    ;;
    \?) print_message "Invalid option -$OPTARG" >&2
    ;;
    esac
done

print_message() {
	echo "$1"	
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

guard_run_as_root() {
    # Bash skript use some commands that need root permissions.
    if [ "$EUID" -ne 0 ]
        then echo "Please run as root: sudo $SCRIPT_FILENAME -p <password>"
        exit
    fi
}

guard_run_as_root

read_mandatory_input "$password" "Bitnami password not given. See https://docs.bitnami.com/azure/faq/get-started/find-credentials/"

# Enable userdir module for public_html folders
sed -i -e "/#LoadModule userdir_module/c\LoadModule userdir_module modules/mod_userdir.so" /home/bitnami/stack/apache2/conf/httpd.conf
sed -i -e "/httpd-userdir.conf/c\Include conf/extra/httpd-userdir.conf" /home/bitnami/stack/apache2/conf/httpd.conf
sed -i -e "/UserDir public_html/a\UserDir disabled root bitnami $USER" /home/bitnami/stack/apache2/conf/extra/httpd-userdir.conf

# Configure default mysql user that is used to connect database.
sudo echo "[client]" >> /home/bitnami/stack/mysql/conf/my.cnf
sudo echo "user=root" >> /home/bitnami/stack/mysql/conf/my.cnf
sudo echo "password=$password" >> /home/bitnami/stack/mysql/conf/my.cnf

# Configure apache
sudo echo "" >> /home/bitnami/stack/apache2/conf/httpd.conf
sudo echo "# My own configurations" >> /home/bitnami/stack/apache2/conf/httpd.conf
sudo echo "ServerSignature Off" >> /home/bitnami/stack/apache2/conf/httpd.conf
sudo echo "ServerTokens Prod" >> /home/bitnami/stack/apache2/conf/httpd.conf
sudo echo "FileETag None" >> /home/bitnami/stack/apache2/conf/httpd.conf
sudo echo "" >> /home/bitnami/stack/apache2/conf/httpd.conf

# Configure apache mod_evasive module

git clone https://github.com/jzdziarski/mod_evasive/
cd mod_evasive
cp mod_evasive{20,24}.c
sed s/remote_ip/client_ip/g -i mod_evasive24.c
sudo apxs -i -a -c mod_evasive24.c
echo Include conf/modevasion.conf | sudo tee -a /opt/bitnami/apache2/conf/httpd.conf

sudo tee /opt/bitnami/apache2/conf/modevasion.conf <<EOF
#increases size of hash table. Good, but uses more RAM."
DOSHashTableSize    3097"
#Interval, in seconds, of the page interval."
DOSPageInterval     1"
#Interval, in seconds, of the site interval."
DOSSiteInterval     1"
#period, in seconds, a client is blocked.  The counter is reset to 0 with every access within this interval."
DOSBlockingPeriod   10"
#threshold of requests per page, per page interval.  If hit == block."
DOSPageCount        2"
#threshold of requests for any object by the same ip, on the same listener, per site interval."
DOSSiteCount        50"
#locking mechanism prevents repeated calls.  email can be sent when host is blocked (leverages the following by default "/bin/mail -t %s")"
DOSEmailNotify      mbrown@domainy.com"
#locking mechanism prevents repeated calls.  A command can be executed when a host is blocked.  %s is the host IP."
#DOSSystemCommand    \"su - someuser -c \'/sbin/... %s ...\'\""
#DOSLogDir           \"/var/lock/mod_evasive\""
#whitelist an IP., leverage wildcards, not CIDR, like 127.0.0.*"
#DOSWhiteList 127.0.0.1"
EOF

# Restart all services
sudo /opt/bitnami/ctlscript.sh restart
sudo /opt/bitnami/ctlscript.sh restart apache

