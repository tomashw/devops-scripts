#!/bin/bash

if [ -z "$1" ]
then
    echo
    echo "Script requires one parameter (IP or hostname)."
    echo "Usage example: trigger_puppet.sh 10.1.210.21"
    echo     
    exit 1
fi

echo "Running on host:  $i"

# Make sure to connest to target machine as jenkins user
# Make sure to run puppet as root on a target machine
ssh -i /var/lib/jenkins/.ssh/id_rsa_mlp_prod -o StrictHostKeyChecking=no jenkins@$i 'hostname;id;sudo -- bash -c "puppet agent -t; id";hostname;id'

exit $?
