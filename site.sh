#!/bin/bash

# echo -n "Enter a domain name: "
# read domain

# The main (entry) function.
main() {
	checkRoot
	outputMenu
}

# Output the main menu and prompt user to select an item.
outputMenu() {
	clear
	welcome
	echo "How can I help you?"
	outputLine
	echo "1. Install the system (Apache, MariaDB, PHP, Git, WP-CLI)
2. Add a domain"
	outputLine
	echo ""

	read -p "Enter a choice [1-2]: " choice
	echo ""

	case $choice in
		1)
			install
			backToMenu
			;;
		2)
			echo "Two"
			;;
		*)
			echo "Invalid choice"
			;;
	esac
}

# Go back to the main menu.
backToMenu() {
	# -n: Defines the required character count to stop reading
	# -s: Hide the user's input
	# -r: Cause the string to be interpreted "raw" (without considering backslash escapes)
	read -rsn1 -p "Press any key to go back to the main menu or Ctrl-C to exit..."
	outputMenu
}

# Install the system: Apache, MariaDB, PHP, Git, WP-CLI.
install() {
	echo "# Installing the system"
	echo "  - Updating the system"
	# -qq: Don't output anything excepts errors.
	apt-get -qq update

	echo "  - Installing Apache, MariaDB, PHP, Git, WP-CLI"
	# -y: Automatic yes to prompts.
	apt-get install -qqy apache2 libapache2-mod-fcgid php-fpm mariadb-server mariadb-client libmysqlclient-dev php-mysql php-mysqli php-imap php-json php-gd php-curl php-mbstring php-xml php-zip mailutils unzip git
	# -s: Silent mode, -O: write output to file
	curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	chmod +x wp-cli.phar
	mv wp-cli.phar /usr/local/bin/wp

	echo "  - Enabling Apache modules"
	# -q: Quiet mode.
	a2enmod -q rewrite expires headers proxy_fcgi setenvif
	a2enconf -q php7.4-fpm

	echo "  - Restarting Apache"
	service apache2 restart
	# -e: Enable interpretation of backslash escapes.
	echo -e "\nDONE\n"
}

createVhost() {
	echo "Creating vỉrtual host..."

	echo "<VirtualHost *:80>
		ServerName $domain
		DocumentRoot /var/www/$domain
		LogLevel error
		<Directory /var/www/$domain>
			Options FollowSymLinks
			AllowOverride All
		</Directory>
	</VirtualHost>" > "/etc/apache2/sites-available/$domain.conf"

	a2ensite $domain > /dev/null

	mkdir -p "/var/www/$domain"

	service apache2 restart
}

createDb() {
	echo "Creating database..."

	echo -n "Enter MySQL root password (optional): "
	read root_pwd

	db=${domain/./_}
	user_pwd=$(echo $RANDOM | base64)

	if [ -n $root_pwd ]
	then
		mysql -u root -p"$root_pwd" -e "CREATE DATABASE $db;" > /dev/null
		mysql -u root -p"$root_pwd" -e "CREATE USER '$db'@'localhost' IDENTIFIED BY '$user_pwd';" > /dev/null
		mysql -u root -p"$root_pwd" -e "GRANT ALL PRIVILEGES ON $db.* TO '$db'@'localhost';"
	else
		mysql -u root -e "CREATE DATABASE $db;" > /dev/null
		mysql -u root -e "CREATE USER '$db'@'localhost' IDENTIFIED BY '$user_pwd';" > /dev/null
		mysql -u root -e "GRANT ALL PRIVILEGES ON $db.* TO '$db'@'localhost';"
	fi
}

installWp() {
	echo "Installing WordPress..."
}

# Output a message and die.
die() {
	echo "ERROR: $*" >&2
	exit 1
}

# Output the welcome message.
welcome() {
	echo -e "Welcome to eLightUp VPS management script v0.0.1.\n"
}

# Output a horizontal line with 80 characters width.
outputLine() {
	echo "--------------------------------------------------------------------------------"
}

# Check if the current user is a super user.
checkRoot() {
	if [ `id -u` -ne 0 ]; then
		die "You should have superuser privileges to continue. Try to run the script again with sudo."
	fi
}

main