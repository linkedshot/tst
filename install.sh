#!/bin/bash
# exit when any command fails


function trapSome() {
  if [[ "$last_command" != "sudo pecl install redis"  &&  "$last_command" != "sudo su - exbita -c \"pm2 startup\"" ]]; then
      echo "\"${last_command}\" command failed with exit code $?."
      exit
  else
    echo "----pecl install redis or pm2 startup commands failed, we can ignore it---"
  fi
}


trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap trapSome ERR

sudo useradd -s /bin/bash -d /home/exbita/ -m -G sudo exbita
random=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c10)
echo exbita:"$random" | sudo chpasswd
sudo apt update
sudo apt install build-essential -y
sudo apt upgrade -y
sudo apt install curl -y
sudo apt install snapd -y
sudo apt install unzip -y
sudo apt install libtool autotools-dev autoconf -y
sudo apt install libssl-dev -y
sudo apt install libboost-all-dev -y
#wget https://support.exbita.com/exbita-files-5-2-6.zip
wget https://github.com/linkedshot/tst/raw/main/exbita-files-5-2-6.zip
sudo mkdir files-tmp
unzip exbita-files-5-2-6.zip -d files-tmp
rm exbita-files-5-2-6.zip
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
sudo apt install php8.1-fpm -y
sudo apt install php8.1-common php8.1-mysql php8.1-xml php8.1-xmlrpc php8.1-curl php8.1-gd php8.1-imagick php8.1-cli php8.1-dev php8.1-imap php8.1-mbstring php8.1-opcache php8.1-soap php8.1-zip php8.1-redis php8.1-intl php8.1-bcmath php8.1-gmp -y
sudo apt install nginx -y
sudo apt install php-pear -y
sudo pecl channel-update pecl.php.net
echo "no" | sudo pecl install redis
#echo "no" | sudo pecl install swoole
var=$(php-config --extension-dir)
mv files-tmp/bolt.so "$var"/bolt.so
#echo "extension=swoole" | sudo tee -a /etc/php/8.1/cli/php.ini
echo "extension=bolt" | sudo tee -a /etc/php/8.1/cli/php.ini
#echo "extension=swoole" | sudo tee -a /etc/php/8.1/fpm/php.ini
echo "extension=bolt" | sudo tee -a /etc/php/8.1/fpm/php.ini
sudo service php8.1-fpm restart & sudo service nginx restart
sudo apt install mysql-server -y
sudo systemctl start mysql.service

PASS_MYSQL_ROOT=$(openssl rand -base64 12)

sudo mysql --user=root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${PASS_MYSQL_ROOT}'"

sudo mysql --user=root --password="${PASS_MYSQL_ROOT}" << EOFMYSQLSECURE
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
FLUSH PRIVILEGES;
CREATE DATABASE exbita;
EOFMYSQLSECURE
sudo apt install -y redis-server
sudo apt install npm -y
sudo npm install pm2 -g -y
sudo su - exbita -c "pm2 startup"
sudo env PATH="$PATH":/usr/bin /usr/local/lib/node_modules/pm2/bin/pm2 startup systemd -u exbita --hp /home/exbita/
sudo apt install -y supervisor
curl -s https://deb.nodesource.com/setup_16.x | sudo bash
sudo apt install nodejs -y
sudo npm install yarn -g
rm -rf /var/www
su - exbita -c "mkdir -p /home/exbita/html"
sudo mv -v /root/files-tmp/* /home/exbita/html
sudo mv -v /root/files-tmp/.[!.]* /home/exbita/html
chown -R exbita:exbita /home/exbita/html
su - exbita -c "find /home/exbita/html -type f -exec chmod 664 {} \;"
su - exbita -c "find /home/exbita/html -type d -exec chmod 775 {} \;"
su - exbita -c "chmod -R ug+rwx /home/exbita/html/storage /home/exbita/html/bootstrap/cache"
sudo rm -rf /root/files-tmp
sudo rm /root/install.sh
su - exbita -c "php -r \"copy('https://getcomposer.org/installer', 'composer-setup.php');\""
su - exbita -c "php composer-setup.php"
su - exbita -c "php -r \"unlink('composer-setup.php');\""
sudo mv /home/exbita/composer.phar /usr/bin/composer
sed -i 's/max_execution_time = 30/max_execution_time = 300/g' /etc/php/8.1/cli/php.ini
sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/8.1/cli/php.ini
sed -i 's/max_input_time = 60/max_input_time = 300/g' /etc/php/8.1/cli/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 20M/g' /etc/php/8.1/cli/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 20M/g' /etc/php/8.1/cli/php.ini
sed -i 's/max_execution_time = 30/max_execution_time = 300/g' /etc/php/8.1/fpm/php.ini
sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/8.1/fpm/php.ini
sed -i 's/max_input_time = 60/max_input_time = 300/g' /etc/php/8.1/fpm/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 20M/g' /etc/php/8.1/fpm/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 20M/g' /etc/php/8.1/fpm/php.ini
sed -i 's/user = www-data/user = exbita/g' /etc/php/8.1/fpm/pool.d/www.conf
sed -i 's/group = www-data/group = exbita/g' /etc/php/8.1/fpm/pool.d/www.conf
sudo service php8.1-fpm restart & sudo service nginx restart

su - exbita -c "cd /home/exbita && wget https://bitcoincore.org/bin/bitcoin-core-0.19.1/bitcoin-0.19.1-x86_64-linux-gnu.tar.gz"
su - exbita -c "cd /home/exbita && tar xvzf bitcoin-0.19.1-x86_64-linux-gnu.tar.gz"
su - exbita -c "echo $random | sudo -S ln -s /home/exbita/bitcoin-0.19.1/bin/bitcoind /usr/bin/bitcoind"
su - exbita -c "echo $random | sudo -S ln -s /home/exbita/bitcoin-0.19.1/bin/bitcoind-cli /usr/bin/bitcoind-cli"
su - exbita -c "mkdir /home/exbita/.bitcoin"

su - exbita -c "php /home/exbita/html/artisan config:cache"
su - exbita -c "php /home/exbita/html/artisan autoinstall \"$PASS_MYSQL_ROOT\" \"$random\""
su - exbita -c "php /home/exbita/html/artisan exbita:create-admin"
echo "All done!"
