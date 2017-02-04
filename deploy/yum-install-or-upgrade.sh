#/bin/bash
echo checking if $1 is installed...
installed=`rpm -qa | grep $1 | wc -l`
if [ $installed == '0' ]
then
 echo $1 is not installed
 echo going to install it...
 yum -y install $1 --disablerepo=* --enablerepo=internal-snapshots,internal-releases,prod-nexus-releases
else
 echo $1 is  installed, going to update only...
 yum -y update $1
fi
#no downgrade option here 
