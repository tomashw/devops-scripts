#!/bin/bash

prod_source="$1"

if [ -z "$1" ] ; then
  echo "Please specify the Prod build directory path." >&2
  exit 1
fi

if [ -z "$2" ] ; then
  echo "Please specify the Prod deployment configuration file." >&2
  exit 1
fi

declare -A server_table

parse_server_table() {

   while read key value  ; do

       server_table["$key"]="$value"
       echo key = $key value = $value
   done < $1
}

parse_server_table "$2"

for server in ${!server_table[@]} ; do
   for package in ${server_table[$server]} ; do
      package=$(find $prod_source -name ${package}-*.rpm)
      echo "********************************************"
      echo "scp ${package} jenkins@${server}:"
      scp -o LogLevel=FATAL ${package} jenkins@${server}:
      echo "ssh jenkins@${server} sudo yum -y --nogpg  localinstall $(basename $package)"
      ssh -o LogLevel=FATAL jenkins@${server} sudo yum -y --nogpg  localinstall $(basename $package)
      echo "ssh jenkins@${server} rm pageonce-\*"
      ssh -o LogLevel=FATAL jenkins@${server} 'rm pageonce-*'
      echo "********************************************"
   done
done


echo ; echo
for server in ${!server_table[@]} ; do
   echo "$server:"
   for package in ${server_table[$server]} ; do
      ssh -o LogLevel=FATAL jenkins@${server} sudo rpm -q "$package"
   done
   echo "*********************************"
done