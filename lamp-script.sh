#!/bin/bash

####################################
#                                  #
# Copyright (c) 2022 fiXed.ovh     #
#                                  #
####################################

function start() {
	echo ""
	echo ""
	echo "LAMP quick install script | v1.0"
	echo ""
	echo "Copyright (c) 2022 fiXed.ovh"
	echo "https://github.com/ttv-fixed/lamp-script"
	echo ""
	echo "Release notes for installed packages:"
	echo "- Apache 2"
	echo "- PHP 8.1"
	echo "- MariaDB latest"
	echo "- phpMyAdmin latest"
	echo ""

	sleep 1

	read -p "Are you sure you want to enable the script? <y/n> " prompt

	if [ $prompt = y ]
	then
		sudo mkdir -p /var/lamp-script/
		echo "Starting the script."
		sleep 1
		echo "Starting the script.."
		sleep 1
		echo "Starting the script..."
		sleep 1
		installation1
	elif [ $prompt = n ]
	then
		echo "The script has been aborted!"
		exit 1
	else
		echo "You must use y or n in response!"
		sleep 1
		failresponse1
		fi
}

function installation1() {
	sudo apt-get update
	sudo apt-get upgrade -y
	sudo apt-get install zip nano wget software-properties-common -y
	sudo LC_ALL=C.UTF-8 sudo add-apt-repository ppa:ondrej/php -y
	sudo apt-get update
	sudo apt-get install apache2 php8.1 libapache2-mod-php8.1 php8.1-mysql php8.1-fpm php8.1-mbstring php8.1-curl -y
	sudo systemctl restart apache2
	sudo apt-get install mariadb-server mariadb-client -y
	mysql
}

function mysql() {
	read -p "Do you want the script to create a root account in the database? <y/n> " prompt

	if [ $prompt = y ]
	then
		sudo apt-get install expect -y

		echo $RANDOM | md5sum | head -c 20 > /var/lamp-script/mysql-root.txt;

		for PASSWORD in $(cat /var/lamp-script/mysql-root.txt)
		do
			echo "$PASSWORD"
		done

		expect -f - <<-EOF
		set timeout 15
		spawn mysql_secure_installation
		expect "Enter current password for root (enter for none):"
		send -- "\r"
		expect "Switch to unix_socket authentication"
		send -- "y\r"
		expect "Change the root password?"
		send -- "y\r"
		expect "New password:"
		send -- "$PASSWORD\r"
		expect "Re-enter new password:"
		send -- "$PASSWORD\r"
		expect "Remove anonymous users?"
		send -- "y\r"
		expect "Disallow root login remotely?"
		send -- "y\r"
		expect "Remove test database and access to it?"
		send -- "y\r"
		expect "Reload privilege tables now?"
		send -- "y\r"
		expect eof
		EOF

		apt-get purge expect -y
		echo "A root account has been successfully created and given a password!"
		sleep 1
		configmysql
	elif [ $prompt = n ]
	then
		echo "The account will not be created!"
		sleep 1
		configmysql
	else
		echo "You must use y or n in response!"
		sleep 1
		failresponse2
		fi
}

function configmysql() {
	read -p "Do you want to allow remote access to the database? <y/n> " prompt

	if [ $prompt = y ]
	then
		sed -i 's/bind-address            = 127.0.0.1/# bind-address            = 127.0.0.1/g' /etc/mysql/mariadb.conf.d/50-server.cnf
		
		echo "Successfully allowed remote access to the database!"
		sleep 1
		configapache2_1
	elif [ $prompt = n ]
	then
		echo "Remote access to the database has not been enabled!"
		sleep 1
		configapache2_1
	else
		echo "You must use y or n in response!"
		sleep 1
		failresponse3
		fi
}

function configapache2_1() {
	read -p "Do you want to allow .htaccess files? <y/n> " prompt

	if [ $prompt = y ]
	then
		line=172
		substitute="         AllowOverride All"
		sed -i "${line}s/.*/$substitute/" /etc/apache2/apache2.conf

		echo ".htaccess files have been successfully allowed!"
		sleep 1
		configapache2_2
	elif [ $prompt = n ]
	then
		echo ".htaccess files have not been successfully consented to!"
		sleep 1
		configapache2_2
	else
		echo "You must use y or n in response!"
		failresponse4
		fi
}

function configapache2_2() {
	read -p "Do you want to disable file and directory listing? <y/n> " prompt

	if [ $prompt = y ]
	then
		line=171
		substitute="         Options FollowSymLinks"
		sed -i "${line}s/.*/$substitute/" /etc/apache2/apache2.conf

		echo "Successfully disabled the display of files and folders!"
		sleep 1
		installation2
	elif [ $prompt = n ]
	then
		echo "You have successfully not agreed to disable the display of files and folders!"
		sleep 1
		installation2
	else
		echo "You must use y or n in response!"
		failresponse5
		fi
}

# TODO: Creating a new user account in MySQL

function installation2() {
	sudo mkdir -p /var/www/temp-phpmyadmin && cd /var/www/temp-phpmyadmin
	sudo wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.zip
	sudo unzip phpMyAdmin-*.zip
	sudo rm phpMyAdmin-*.zip
	sudo mv phpMyAdmin-* phpMyAdmin
	sudo mv phpMyAdmin ..
	cd ..
	sudo rm -r -d temp-phpmyadmin
	cd phpMyAdmin
	sudo cp config.sample.inc.php config.inc.php
	sudo mkdir tmp
	sudo chmod 777 tmp
	blowfish_secret
}

function blowfish_secret() {
	read -p "Do you want to automatically enter the generated blowfish_secret key into config.inc.php? (recommended y) <y/n> " prompt

	if [ $prompt = y ]
	then
		echo $RANDOM | md5sum | head -c 32 > /var/lamp-script/blowfish_secret.txt

		for KEY in $(cat /var/lamp-script/blowfish_secret.txt)
		do
			echo "Your generated blowfish_secret key:"
			echo "$KEY"
		done

		line=16
		substitute="\$cfg['blowfish_secret'] = '$KEY';"
		sed -i "${line}s/.*/$substitute/" config.inc.php

		echo "You have successfully entered the generated blowfish_secret key!"
		sleep 1
		end_script
	elif [ $prompt = n ]
	then
		echo "You have successfully not agreed to generate and assign a key blowfish_key!"
		sleep 1
		end_script
	else
		echo "You must use y or n in response!"
		failresponse6
		fi
}

function end_script() {
	sudo systemctl restart apache2
	sudo systemctl restart mariadb
	sudo systemctl restart mysql
	echo ""
	echo "The MySQL root password is located in /var/lamp-script/mysql-root.txt"
	echo ""
	echo "The script has finished its work!"
	echo "Thank you for using!"
	echo ""
	echo "Copyright (c) 2022 fiXed.ovh"
	echo "https://github.com/ttv-fixed/lamp-script"
	echo ""
}

function failresponse1() {
	read -p "Are you sure you want to enable the script? <y/n> " prompt

	if [ $prompt = y ]
	then
		echo "Starting the script."
		sleep 1
		echo "Starting the script.."
		sleep 1
		echo "Starting the script..."
		sleep 1
		installation1
	elif [ $prompt = n ]
	then
		echo "The script has been aborted!"
		exit 1
	else
		echo "You must use y or n in response!"
		failresponse1
		fi
}

function failresponse2() {
	read -p "Do you want the script to create a root account in the database? <y/n> " prompt

	if [ $prompt = y ]
	then
		sudo apt-get install expect -y

		echo $RANDOM | md5sum | head -c 20 > /var/lamp-script/mysql-root.txt;

		for PASSWORD in $(cat /var/lamp-script/mysql-root.txt)
		do
			echo "$PASSWORD"
		done

		expect -f - <<-EOF
		set timeout 5
		spawn mysql_secure_installation
		expect "Enter current password for root (enter for none):"
		send -- "\r"
		expect "Switch to unix_socket authentication"
		send -- "y\r"
		expect "Change the root password?"
		send -- "y\r"
		expect "New password:"
		send -- "$PASSWORD\r"
		expect "Re-enter new password:"
		send -- "$PASSWORD\r"
		expect "Remove anonymous users?"
		send -- "y\r"
		expect "Disallow root login remotely?"
		send -- "y\r"
		expect "Remove test database and access to it?"
		send -- "y\r"
		expect "Reload privilege tables now?"
		send -- "y\r"
		expect eof
		EOF

		apt-get purge expect -y
		configmysql
	elif [ $prompt = n ]
	then
		echo "The account will not be created!"
		sleep 1
		configmysql
	else
		echo "You must use y or n in response!"
		sleep 1
		failresponse2
		fi
}

function failresponse3() {
	read -p "Do you want to allow remote access to the database? <y/n> " prompt

	if [ $prompt = y ]
	then
		sed -i 's/bind-address            = 127.0.0.1/# bind-address            = 127.0.0.1/g' /etc/mysql/mariadb.conf.d/50-server.cnf
		
		echo "Successfully allowed remote access to the database!"
		sleep 1
		configapache2_1
	elif [ $prompt = n ]
	then
		echo "Remote access to the database has not been enabled!"
		sleep 1
		configapache2_1
	else
		echo "You must use y or n in response!"
		sleep 1
		failresponse3
		fi
}

function failresponse4() {
	read -p "Do you want to allow .htaccess files? <y/n> " prompt

	if [ $prompt = y ]
	then
		line=172
		substitute="         AllowOverride All"
		sed -i "${line}s/.*/$substitute/" /etc/apache2/apache2.conf

		echo ".htaccess files have been successfully allowed!"
		sleep 1
		configapache2_2
	elif [ $prompt = n ]
	then
		echo ".htaccess files have not been successfully consented to!"
		sleep 1
		configapache2_2
	else
		echo "You must use y or n in response!"
		failresponse4
		fi
}

function failresponse5() {
	read -p "Do you want to disable file and directory listing? <y/n> " prompt

	if [ $prompt = y ]
	then
		line=171
		substitute="         Options FollowSymLinks"
		sed -i "${line}s/.*/$substitute/" /etc/apache2/apache2.conf

		echo "Successfully disabled the display of files and folders!"
		sleep 1
		installation2
	elif [ $prompt = n ]
	then
		echo "You have successfully not agreed to disable the display of files and folders!"
		sleep 1
		installation2
	else
		echo "You must use y or n in response!"
		failresponse5
		fi
}

function failresponse6() {
	read -p "Do you want to automatically enter the generated blowfish_secret key into config.inc.php? (recommended y) <y/n> " prompt

	if [ $prompt = y ]
	then
		echo $RANDOM | md5sum | head -c 32 > /var/lamp-script/blowfish_secret.txt

		for KEY in $(cat /var/lamp-script/blowfish_secret.txt)
		do
			echo "Your generated blowfish_secret key:"
			echo "$KEY"
		done

		line=16
		substitute="\$cfg['blowfish_secret'] = '$KEY';"
		sed -i "${line}s/.*/$substitute/" config.inc.php

		echo "You have successfully entered the generated blowfish_secret key!"
		sleep 1
		end_script
	elif [ $prompt = n ]
	then
		echo "You have successfully not agreed to generate and assign a key blowfish_key!"
		sleep 1
		end_script
	else
		echo "You must use y or n in response!"
		failresponse6
		fi
}

####################################
#                                  #
# Copyright (c) 2022 fiXed.ovh     #
#                                  #
####################################

start