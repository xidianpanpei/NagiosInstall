#!/bin/bash

# File suffix name
suffix='.cfg'

# Generate Linux Group's IP string
linuxGroup=''
while read LINE
do
    linuxGroup=$linuxGroup$LINE','
done < ./monitor_clients.conf

sublen=`expr ${#linuxGroup} - 1`
linuxGroup=`expr substr "$linuxGroup" 1 $sublen`

# Function for generating the cfg file from template
function gen_config_files()
{
    local file=$1$suffix
    cp ./linux_machine_temp.cfg /usr/local/nagios/etc/machines/$file
    #cp ./linux_machine_temp.cfg ./$file
    sed -i "s/0.0.0.0/$1/g" /usr/local/nagios/etc/machines/$file
    sed -i "s/linux-machineX/$1/g" /usr/local/nagios/etc/machines/$file
    sed -i "s/linux-machineG/$linuxGroup/g" /usr/local/nagios/etc/machines/$file
}

while read LINE
do
    gen_config_files $LINE
done < ./monitor_clients.conf

service nagios restart
