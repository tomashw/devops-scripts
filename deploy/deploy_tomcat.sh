#!/bin/bash

export PATH=$PATH:/sbin

echo
echo PATH = $PATH
echo

echo deploying to $1
source $1

pwd
#echo Fetching war from $WAR_URL
#wget $WAR_URL -O $CONTEXT_NAME.war
#RET_VAL=$?
#if [ "$RET_VAL" -ne "0" ]; then		
#		echo  Failed to fetch WAR
#		exit 4
#fi

RET_VAL=$?
if [ "$RET_VAL" -ne "0" ]; then		
		echo  Failed to find source $1
		exit 5
fi

# Stop tomcat first
# There are issues with class unloading in tomcat - PermGen Space memory leak
echo going to stop tomcat by running $STOP_SCRIPT...
$STOP_SCRIPT


echo checking if tomcat is down...

i="0"
while [ $i -lt 10 ]
do
	#Since grep return the lines including the grep itself, we need to calculate it too.
    # So a good value is '1.
	t=`ps -ef | grep Bootstrap | wc -l`
	if [ "$t" -ne "1" ]; then
		i=$[$i+1]
		echo  Tomcat is still running, checking again in 5 seconds...
		sleep 5
	else
		echo  Tomcat is stopped.
		break;
	fi 
done

if [ -e "/var/run/$PID_FILE.pid" ]; then
    echo Killing brutally the process!
	kill -9 `cat /var/run/$PID_FILE.pid`
fi

#TODO add loop here to make sure tomcat is dead
$STATUS_SCRIPT
cat /var/run/$PID_FILE.pid

#echo Tomcat is stopped.
echo cleaning before redeploying...

echo cleaning tmp dir 
if [  ! -z "$TMP_DIR" -a "$TMP_DIR" != " " -a "$TMP_DIR" != "/" ]; then
	rm -rf $TMP_DIR/*
else	
    echo "Can't clean the directory. Parameter string is either empty or '/'"
fi

echo cleaning work dir 
if [  ! -z "$WORK_DIR" -a "$WORK_DIR" != " " -a "$WORK_DIR" != "/" ]; then
	rm -rf $WORK_DIR/*
else	
    echo "Can't clean the directory. Parameter string is either empty or '/'"
fi

echo cleaning old war from $WEBAPP_LOCATION/$CONTEXT_NAME
rm -rf $WEBAPP_LOCATION/$CONTEXT_NAME
rm -f $WEBAPP_LOCATION/$CONTEXT_NAME.war


echo copying war to Tomcat from $CONTEXT_NAME.war to $WEBAPP_LOCATION/...
mv $CONTEXT_NAME.war $WEBAPP_LOCATION/

echo starting Tomcat...
$START_SCRIPT

echo Tomcat was started

	
	




