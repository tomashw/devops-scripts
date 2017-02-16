#!/bin/bash

monolith_source="$1"

if [ -z "$1" ] ; then
  echo "You must specify a build dir!!!" >&2
  exit 1
fi

if [ -z "$2" ] ; then
  echo "You must specify a deployment configuration!!!" >&2
  exit 1
fi

declare -A server_table

parse_server_table() {

   while read key value  ; do
       
       server_table["$key"]="$value"
   done < $1
}

parse_server_table "$2"

for server in ${!server_table[@]} ; do
   for package in ${server_table[$server]} ; do
      package=$(find $monolith_source -name ${package}-*.rpm)
      echo "********************************************"
      echo "scp ${package} dev_user@${server}:"
      scp -o LogLevel=FATAL ${package} dev_user@${server}:
      echo "ssh dev_user@${server} sudo yum -y --nogpg  localinstall $(basename $package)"
      ssh -o LogLevel=FATAL dev_user@${server} sudo yum -y --nogpg  localinstall $(basename $package)
      echo "ssh dev_user@${server} rm pageonce-\*"
      ssh -o LogLevel=FATAL dev_user@${server} 'rm pageonce-*'
      echo "********************************************"
   done
done


echo ; echo
for server in ${!server_table[@]} ; do
   echo "$server:"
   for package in ${server_table[$server]} ; do
      ssh -o LogLevel=FATAL dev_user@${server} sudo rpm -q "$package"
   done
   echo "*********************************"
done
