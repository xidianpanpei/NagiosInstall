#!/bin/bash

# Update the operation system
apt-get update

# Install Tools Packages
#apt-get install -y chkconfig

# Install Dependence Packages
apt-get install -y build-essential libssl0.9.8 libssl-dev openssl libgd2-noxpm libgd2-noxpm-dev apache2 php5 sendmail mailutils

# Add Nagios user and group
groupadd nagcmd
groupadd nagios
useradd -g nagios nagios

# Record the original path
install_path=$(pwd)

# Download Nagios Install Packages
cd /usr/local/src
wget http://prdownloads.sourceforge.net/sourceforge/nagios/nagios-3.2.3.tar.gz
wget http://nagios-plugins.org/download/nagios-plugins-2.0.3.tar.gz
wget http://prdownloads.sourceforge.net/sourceforge/nagios/nrpe-2.13.tar.gz

# Install nagios core package
tar zxf nagios-3.2.3.tar.gz
cd nagios-3.2.3
./configure --with-command-group=nagcmd --prefix=/usr/local/nagios
make all
make install
make install-init
make install-config
make install-commandmode
make install-webconf
cd ../

# Install nagios plugins package
tar zxf nagios-plugins-2.0.3.tar.gz
cd nagios-plugins-2.0.3
./configure --prefix=/usr/local/nagios --with-nagios-user=nagios
--with-nagios-group=nagios
make && make install
cd ../

# Install nagios client package
tar zxf nrpe-2.13.tar.gz
cd nrpe-2.13
ln -s /usr/lib/x86_64-linux-gnu/libssl.so /usr/lib/libssl.so
./configure
make all
make install-plugin
cd $install_path

# Set login user and password for the web page
touch /usr/local/nagios/etc/htpasswd.users
htpasswd -b -d /usr/local/nagios/etc/htpasswd.users nagiosadmin hengtian

chown -R nagios:nagios /usr/local/nagios/
mkdir -p /usr/local/nagios/etc/machines
chown nagios:nagios /usr/local/nagios/etc/machines
echo "cfg_dir=/usr/local/nagios/etc/machines/" >> /usr/local/nagios/etc/nagios.cfg

echo "# 'check_nrpe' command definition
define command{
    command_name check_nrpe
    command_line \$USER1\$/check_nrpe -H \$HOSTADDRESS\$ -c \$ARG1\$
    }" >> /usr/local/nagios/etc/objects/commands.cfg

# Check the install result
echo "alias nagioscheck='/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg' " >> /root/.bashrc
source /root/.bashrc

# Start the nagios service
service apache2 restart
service nagios start

# Config sendmail for mail the alert
sed -i "s/notification_timeout=30/notification_timeout=120/g" /usr/local/nagios/etc/nagios.cfg
cp ./contacts.cfg /usr/local/nagios/etc/objects/
ln -s /usr/bin/mail /bin/mail

# Config the clients configure files
bash ./nagios_clients_config.sh

service nagios restart
