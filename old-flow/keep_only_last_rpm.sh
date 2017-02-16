#!/bin/bash
cd $1
if [ -z "$1" ] ; then
        echo "no path !"
        exit 777
fi
NUMBER_TO_KEEP=$2
roles=$(ls -1 | awk -F- '{print $2}' | uniq)
for C_ROLE in $roles ;do
        ls -1 [Nn]ame-of-rpm -${C_ROLE}* | sort -t- -k 3 -n -r  | tail -n +${NUMBER_TO_KEEP} |xargs --no-run-if-empty rm -v
done
