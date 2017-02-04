#!/bin/bash

#sudo /tmp/deploy_rpm_per_version.sh /tmp/solo-server ${VERSION}-0

#Command line parameters
if [ -z "$2" ] 
then
	echo "Usage: $0 [CONF_FILE] [VERSION]"
	exit 1
fi
# Setting variables
CONF_FILE=$1
VERSION=$2

# test if there are variables
[ -f $CONF_FILE ] && source $CONF_FILE || ( echo "Could not source $CONF_FILE . Exiting!"; exit 1)
 
if [ -z "$SERVICE_NAME" ]
then
  echo "Parameter SERVICE_NAME is not defined"
  exit 1
else
	export SERVICE_NAME
fi

if [ -z "$RPM_NAME" ]
then
  echo "Parameter RPM_NAME is not defined"
  exit 1
else
	export RPM_NAME
fi

if [ -z "$PID_FILE" ]
then
  echo "Parameter PID_FILE is not defined"
  exit 1
else
	export PID_FILE
fi

echo
echo "Changing directory to /tmp"
cd /tmp
pwd
hostname
pwd
chmod +x /tmp/yum-install-upgrade-downgrade-per-version.sh
ls -l

echo "Starting job on $SERVICE_NAME"

date
pwd

echo
echo "Cleaning yum repo"
yum clean all

echo 
echo "Displaying yum repolist"
yum repolist

echo
echo "Displaying $RPM_NAME RPM list"
rpm -qa |grep $RPM_NAME

echo
echo "Displaying $SERVICE_NAME service status"
/sbin/service $SERVICE_NAME status

echo
echo "Stoping $SERVICE_NAME service"
/sbin/service $SERVICE_NAME stop

echo
echo "Displaying $SERVICE_NAME service status"
/sbin/service $SERVICE_NAME status
echo


echo "Checking if RPM service is down..."

if [ -e "/var/run/$PID_FILE.pid" ]; then
    echo "Killing brutally the process!"
	kill -9 `cat /var/run/$PID_FILE.pid`
fi

echo
/sbin/service $SERVICE_NAME status
cat /var/run/$PID_FILE.pid

echo
echo "Running install/update/downgrade script"
/tmp/yum-install-upgrade-downgrade-per-version.sh $RPM_NAME $VERSION

RET_VAL=$?
if [ "$RET_VAL" -ne "0" ]; then		
		echo  "Failed to deploy the RPM. Error: $RET_VAL"
		exit 3
fi

echo
/sbin/service $SERVICE_NAME start
echo
echo "Checking service status"
/sbin/service $SERVICE_NAME status

echo "Job on $SERVICE_NAME ended"
echo
