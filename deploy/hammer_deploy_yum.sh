#!/bin/bash

HOSTS=$(hammer host list --hostgroup $HAMMER_GROUP --per-page 256 | grep ^[0-9] | awk '{print $3}')
echo +++++++++++++++++++++++++++++++++++
echo
echo Hosts list: $HOSTS
echo
echo +++++++++++++++++++++++++++++++++++

for i in $(hammer host list --hostgroup $HAMMER_GROUP --per-page 256 | grep ^[0-9] | awk '{print $3}')
do	
    echo 
    echo "Working on host: $i"
    echo "Copying scripts to the target machine: $i"
    echo
    
    scp -i /var/lib/jenkins/.ssh/id_rsa -o StrictHostKeyChecking=no $WORKSPACE/deploy/yum-install-or-upgrade.sh $WORKSPACE/deploy/deploy_rpm.sh $WORKSPACE/config/$APP_CONFIG jenkins@$i:/tmp
	
	echo "Deploying on host:  $i"
        RES=$(ssh -i /var/lib/jenkins/.ssh/id_rsa -o StrictHostKeyChecking=no jenkins@$i "hostname -f;    	
        chmod +x /tmp/yum-install-or-upgrade.sh /tmp/deploy_rpm.sh /tmp/$APP_CONFIG;
        echo Source the congiguration; 
        source  /tmp/$APP_CONFIG;
        export VERSION=${VERSION};
        cd /tmp;
        pwd;
    	echo Running deployment script...; 
    	sudo bash -x /tmp/deploy_rpm.sh /tmp/$APP_CONFIG;
    	echo Checking page status after deployment...; ")
     
        exit $?
done
