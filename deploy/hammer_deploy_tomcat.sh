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
    
    scp $WORKSPACE/deploy/deploy_tomcat.sh $WORKSPACE/config/$APP_CONFIG $WORKSPACE/deploy/health_check.sh $WORKSPACE/deploy/fetch_war.sh jenkins@$i:/tmp
	
	echo "Deploying on host:  $i"
        RES=$(ssh -i /var/lib/jenkins/.ssh/id_rsa -o StrictHostKeyChecking=no jenkins@$i "hostname -f;    	
        chmod +x /tmp/deploy_tomcat.sh /tmp/fetch_war.sh /tmp/health_check.sh /tmp/$APP_CONFIG;
        echo Source the congiguration; 
        source  /tmp/$APP_CONFIG;
        export VERSION=${VERSION};
        echo Pulling artifact from Nexus...; 
        cd /tmp;
        pwd;
        rm -f /tmp/\${CONTEXT_NAME};
        bash -x /tmp/fetch_war.sh \${WAR_URL} \${CONTEXT_NAME} \${VERSION};
    	echo Running deployment script...; 
    	sudo bash -x /tmp/deploy_tomcat.sh /tmp/$APP_CONFIG;
    	echo Checking page status after deployment...; 
        sudo /tmp/health_check.sh $HTTP $i $PORT ${END_POINT} $RETRY_COUNT; ")
        
        exit $?
done
