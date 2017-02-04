#!/bin/bash

echo Deploying to $1
source $1

echo Fetching new war from $WAR_URL
wget $WAR_URL -O $CONTEXT_NAME.war

echo Printing war size:
ls -lah ./tmp/ |grep $CONTEXT_NAME.war


echo Going to stop tomcat by running $STOP_SCRIPT...
$STOP_SCRIPT

echo Current tomcat status:
$STATUS_SCRIPT

i="0"

while [ $i -lt 5 ]
do
	if [ -e "/var/run/$PID_FILE.pid" ]; then
		i=$[$i+1]
		echo Tomcat is still running, checking again in 5 seconds...
		sleep 5
	else
		echo Cool! no PID file found; tomcat is stopped.
		break;
	fi 
done

if [ -e "/var/run/$PID_FILE.pid" ]; then
    echo Killing brutally the process!
	kill -9 `cat /var/run/$PID_FILE.pid`
fi

echo Checking tomcat status:
$STATUS_SCRIPT

echo Cleaning before redeploying...


echo Cleaning tmp dir: $TMP_DIR 

if [  ! -z "$TMP_DIR" -a "$TMP_DIR" != " " -a "$TMP_DIR" != "/" ] then
	rm -rf $TMP_DIR/*
else	
    echo "Can't clean the directory. Parameter string is either empty or '/'"
fi

echo Cleaning work dir: $WORK_DIR 

if [  ! -z "$TMP_DIR" -a "$TMP_DIR" != " " -a "$TMP_DIR" != "/" ] then
	rm -rf $WORK_DIR/*
else
    echo "Can't clean the directory. Parameter string is either empty or '/'"
fi

echo Cleaning old war: $WEBAPP_LOCATION/$CONTEXT_NAME.war
rm -rf $WEBAPP_LOCATION/$CONTEXT_NAME
rm -rf $WEBAPP_LOCATION/$CONTEXT_NAME.war


echo Copying war to tomcat at $WEBAPP_LOCATION...
mv $CONTEXT_NAME.war $WEBAPP_LOCATION/

echo Starting Tomcat...
$START_SCRIPT

echo Tomcat was started.
	
	




