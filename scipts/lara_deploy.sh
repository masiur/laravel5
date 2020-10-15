#!/bin/bash

echo "Deploy Laravel on Ubuntu hassle-free | by masiursiddiki.com\n"
echo ""
read -p "Domain name eg. example.com:" domain_name

sudo mkdir -p /var/www/html/$domain_name
sudo chown -R $USER:$USER /var/www/html/$domain_name

cd /var/www/html/$domain_name
read -p 'Git Repo Full Url:' git_url
git clone $git_url
cd $(ls -d */|head -n 1) #First directory on list
BASE_PATH=$PWD

echo "Please enter the NAME of the new MySQL database! (example: database1)"
read MAINDB
echo "Please enter the MySQL database CHARACTER SET! (example: latin1, utf8, ...)"
echo "Enter utf8 if you don't know what you are doing"
read charset
echo "Creating new MySQL database..."

	
# create random password
PASSWDDB="$(openssl rand -base64 12)"

# If /root/.my.cnf exists then it won't ask for root password
if [ -f /root/.my.cnf ]; then

    mysql -e "CREATE DATABASE ${MAINDB} /*\!40100 DEFAULT CHARACTER SET ${charset} */;"
    mysql -e "CREATE USER ${MAINDB}@localhost IDENTIFIED BY '${PASSWDDB}';"
    mysql -e "GRANT ALL PRIVILEGES ON ${MAINDB}.* TO '${MAINDB}'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"

# If /root/.my.cnf doesn't exist then it'll ask for root password   
else
    echo "Please enter root user MySQL password!"
    echo "Note: password will be hidden when typing"
    read -sp rootpasswd
    mysql -uroot -p${rootpasswd} -e "CREATE DATABASE ${MAINDB} /*\!40100 DEFAULT CHARACTER SET ${charset} */;"
    mysql -uroot -p${rootpasswd} -e "CREATE USER ${MAINDB}@localhost IDENTIFIED BY '${PASSWDDB}';"
    mysql -uroot -p${rootpasswd} -e "GRANT ALL PRIVILEGES ON ${MAINDB}.* TO '${MAINDB}'@'localhost';"
    mysql -uroot -p${rootpasswd} -e "FLUSH PRIVILEGES;"
fi

cp .env.example .env
sed -i "/DB_DATABASE/c DB_DATABASE=$MAINDB" .env
sed -i "/DB_USERNAME/c DB_USERNAME=$MAINDB//" .env
sed -i "/DB_PASSWORD/c DB_PASSWORD=$PASSWDDB" .env
composer update

php artisan key:generate
php artisan migrate --seed

 
 
 {
	<VirtualHost *:80>
		ServerName $domain_name
		DocumentRoot $BASE_PATH/public
		<Directory "$BASE_PATH/public">
			AllowOverride All
		</Directory>
	</VirtualHost>
} > /etc/apache2/sites-available/"$domain_name".conf

sudo chgrp -R www-data storage bootstrap/cache
sudo chmod -R ug+rwx storage bootstrap/cache
sudo chmod -R 777 storage && sudo chmod -R 777 public && sudo chmod -R 777 bootstrap/cache

echo "Visit http://${domain_name}"
echo "MySQL Database Username: {$USER_NAME}"
echo "MySQL Database Name: {$MAINDB}"
echo "MySQL DB Password: {$PASSWDDB}"
