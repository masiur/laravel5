#!/bin/bash

echo "Deploy Laravel on Ubuntu hassle-free | by masiursiddiki.com\n"
echo ""
read -p "Domain Name Eg. example.com:" DOMAIN_NAME

sudo mkdir -p /var/www/html/$domain_name
sudo chown -R $USER:$USER /var/www/html/$DOMAIN_NAME

cd /var/www/html/$DOMAIN_NAME

echo "Please enter Full URL of your Git Repository\n"
read -p 'Repository URL: ' GIT_URL
git clone $GIT_URL # Clone the repository 

# First directory on list meaning child directory under it
cd $(ls -d */|head -n 1) 

# Print Working Directory. It prints the path of the working directory, starting from the root
BASE_PATH=$PWD 

echo "Please enter the NAME of the new MySQL database! (example: database1)"
read -p "Project Database Name: " MAINDB
#echo "Please enter the MySQL database CHARACTER SET! (example: latin1, utf8, ...)"
#echo "Enter utf8 if you don't know what you are doing"
#read charset
echo "Creating new MySQL database..."

	
# create random password 12 character
PASSWDDB="$(openssl rand -base64 12)"

# If /root/.my.cnf exists then it won't ask for root password
if [ -f /root/.my.cnf ]; then

    mysql -e "CREATE DATABASE ${MAINDB} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
    mysql -e "CREATE USER ${MAINDB}@localhost IDENTIFIED BY '${PASSWDDB}';"
    mysql -e "GRANT ALL PRIVILEGES ON ${MAINDB}.* TO '${MAINDB}'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"

# If /root/.my.cnf doesn't exist then it'll ask for root password   
else
    echo "Please enter root user MySQL password!"
    echo "Note: password will be hidden when typing"
    read -s -p "Enter RooT Password(MySQL): " ROOT_PASSWORD
    mysql -uroot -p${ROOT_PASSWORD} -e "CREATE DATABASE ${MAINDB} /*\!40100 DEFAULT CHARACTER SET ${charset} */;"
    mysql -uroot -p${ROOT_PASSWORD} -e "CREATE USER ${MAINDB}@localhost IDENTIFIED BY '${PASSWDDB}';"
    mysql -uroot -p${ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON ${MAINDB}.* TO '${MAINDB}'@'localhost';"
    mysql -uroot -p${ROOT_PASSWORD} -e "FLUSH PRIVILEGES;"
fi

cp .env.example .env #copy .env.example file to new file .env
sed -i "/DB_DATABASE/c DB_DATABASE=$MAINDB" .env # this command find the keyword and replace entire line 
sed -i "/DB_USERNAME/c DB_USERNAME=$MAINDB//" .env
sed -i "/DB_PASSWORD/c DB_PASSWORD=$PASSWDDB" .env
composer update

php artisan key:generate # Laravel Key Generate
php artisan migrate --seed # Laravel Migration & Database Seed

#sudo touch /etc/apache2/sites-available/"$domain_name".conf
# Creating VirtualHost Configuration File for $domain_name
 {
 	echo "<VirtualHost *:80>"
	echo "	ServerName $DOMAIN_NAME"
	echo "	DocumentRoot $BASE_PATH/public"
	echo "	<Directory "$BASE_PATH/public">"
	echo "		AllowOverride All"
	echo "	</Directory>"
	echo "</VirtualHost>"
} > /etc/apache2/sites-available/"$DOMAIN_NAME".conf

sudo chgrp -R www-data storage bootstrap/cache # directory belongs to www-data group ( as it is apache)
sudo chmod -R ug+rwx storage bootstrap/cache 
sudo chmod -R 777 storage && sudo chmod -R 777 public && sudo chmod -R 777 bootstrap/cache

echo "Visit http://${DOMAIN_NAME}"
echo "MySQL Database Username: $MAINDB"
echo "MySQL Database Name: $MAINDB"
echo "MySQL DB Password: $PASSWDDB"
