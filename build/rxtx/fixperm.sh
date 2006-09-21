#!/bin/sh 
curruser=`sudo id -p | grep 'login' | sed 's/login.//'` 
echo $curruser 
if [ ! -d /var/lock ] 
then 
sudo mkdir /var/lock 
fi 
sudo chgrp uucp /var/lock 
sudo chmod 775 /var/lock 
if [ ! `sudo niutil -readprop / /groups/uucp users | grep $curruser  
> /dev/null` ] 
then 
sudo niutil -mergeprop / /groups/uucp users $curruser 
fi 
exit 0;
