#!/bin/bash
## Source variable ##
export IPADDR=$(ip addr show eth0 | awk '/inet / { print $2 }' | sed 's/...$//')
export HOSTNAME=$(cat /etc/hostname)

## Echo and push ip in /etc/hosts ##
sed -i -e "/127.0.0.1/a $IPADDR $HOSTNAME" /etc/hosts



## Go in profile directory and generate new profile ##
##_PF = $(DIR_PROFILE)/WD1_W00_wdserver line is removed from image

cd /sapmnt/WD1/profile
cp WD1_W00_wdserver WD1_W00_${HOSTNAME}
echo _PF = /sapmnt/WD1/profile/WD1_W00_${HOSTNAME} >> WD1_W00_${HOSTNAME}



## Start SAP as different user ##
## changed user with WD1
runuser -l wd1adm -c 'startsap'
