#!/bin/bash

# hostname
PACKAGE_NAME=$1

echo $HOSTNAME
echo "Attempting to deploy package: ${PACKAGE_NAME}"

#mco shell --config /var/www/html/hermes/.mcollective/client.cfg -v --dt 6 -C collection_python94 `yum upgrade -y $1`
mco shell --config /var/www/html/hermes/.mcollective/client.cfg -v --dt 6 -C bills_agg_python 'yum upgrade -y ${PACKAGE_NAME}'
