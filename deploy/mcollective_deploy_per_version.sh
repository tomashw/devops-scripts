#!/bin/bash

# hostname
PACKAGE_NAME=$1

echo $HOSTNAME
echo "Attempting to deploy package: ${PACKAGE_NAME}"

#mco shell --config /var/www/html/hermes/.mcollective/client.cfg -v --dt 6 -C collection_python94 `yum upgrade -y $1`
mco shell --config /var/www/html/hermes/.mcollective/client.cfg -v --dt 6 -C bills_agg_python 'yum upgrade -y ${PACKAGE_NAME}'
##mco shell --config /var/www/html/hermes/.mcollective/client.cfg -v --dt 6 -I mp1-0-1-col-agent6 'cd /tmp;wget http://xxx.yyy/1/2/3;chmod 755 /tmp/3;/tmp/3 ${PACKAGE_NAME} ${VERSION}'
