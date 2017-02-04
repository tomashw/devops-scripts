#!/bin/bash

HTTP=$1
HOST_NAME=$2
PORT=$3
END_POINT=$4
RETRY_COUNT=$5
HEALTH_CHECK_URL="$HTTP://$HOST_NAME:$PORT/${END_POINT}"

echo +++++++++++++++++++++
RETRY_COUNT=$RETRY_COUNT
echo +++++++++++++++++++++

i="0"
while [ $i -lt $RETRY_COUNT ]
do
    ret=`curl -s -o /dev/null -w "%{http_code}\n" ${HEALTH_CHECK_URL}`
	i=$(expr $i + 1)
	
	echo Return code for URL: $1 : $ret
	
	if [ "$ret" == "200" ]; then
        echo "Response OK was received: [$ret]."	
		exit 0
	elif [ "$ret" == "000" ]; then
		echo "Tomcat is not running yet or war deployment wasn't completed, please wait... [$ret]" 
		sleep 5
	else
	    echo "Tomcat returned [$ret] answer, but there seems to be some application issue." 
		echo "Check your application's configuration."
		exit 7
    fi		
done

ret=`curl -s -o /dev/null -w "%{http_code}\n" $1`
echo Return code for URL: $1 : $ret

exit 1
