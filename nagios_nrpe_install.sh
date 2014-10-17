#!/bin/bash

if [ -z "$1" ]; then
    echo 'Please input ip paramter like this:
sh nagios_nrpe_install.sh 8.8.8.8'
    exit
fi
# Update operation system
apt-get update

# Install Dependence Packages
apt-get install -y build-essential libssl0.9.8 libssl-dev openssl libgd2-noxpm libgd2-noxpm-dev apache2

# Restart apache2 for check_http service
service apache2 start

# Add Nagios user and group
groupadd nagios
useradd -g nagios -s /sbin/nologin nagios

# Record original path
install_path=$(pwd)

# Download Nagios Install Packages
cd /usr/local/src
wget http://nagios-plugins.org/download/nagios-plugins-2.0.3.tar.gz
wget http://prdownloads.sourceforge.net/sourceforge/nagios/nrpe-2.13.tar.gz

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
make install-daemon
make install-daemon-config
cd $install_path

chown -R nagios:nagios /usr/local/nagios/

# Config the nrpe for monitor
sed -i "s/allowed_hosts=127.0.0.1/allowed_hosts=127.0.0.1,$1/g" /usr/local/nagios/etc/nrpe.cfg
echo "command[check_procs]=/usr/local/nagios/libexec/check_procs -w 150 -c 200
command[check_disk]=/usr/local/nagios/libexec/check_disk -w 20% -c 10% -p /
command[check_http]=/usr/local/nagios/libexec/check_http -H 127.0.0.1 -w 5 -c 10
command[check_ping]=/usr/local/nagios/libexec/check_ping -H 127.0.0.1 -w 3000.0,80% -c 5000.0,100% -p 5
command[check_ssh]=/usr/local/nagios/libexec/check_ssh -4 127.0.0.1
command[check_swap]=/usr/local/nagios/libexec/check_swap  -w 30% -c 10%" >> /usr/local/nagios/etc/nrpe.cfg

# Restart NRPE daemon
killall nrpe
/usr/local/nagios/bin/nrpe -c /usr/local/nagios/etc/nrpe.cfg -d
echo "/usr/local/nagios/bin/nrpe -c /usr/local/nagios/etc/nrpe.cfg -d" >> /etc/rc.local
