#!/bin/bash

WAR_URL=$1
CONTEXT_NAME=$2
VERSION=$3

pwd
echo 
echo Fetching war from $WAR_URL
echo CONTEXT_NAME = $CONTEXT_NAME
echo WAR_URL = $WAR_URL
echo VERSION = $VERSION
echo Downloadable WAR URL = $WAR_URL$VERSION
echo 

wget --no-check-certificate -v $WAR_URL$VERSION -O $CONTEXT_NAME.war

RET_VAL=$?
if [ "$RET_VAL" -ne "0" ]; then		
		echo  "Failed to fetch WAR: [$RET_VAL]"
		exit 4
fi
