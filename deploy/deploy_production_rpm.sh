#!/bin/bash -x
###############################################################################################################
#
# script to deploy to production machines via mco shell
# works on new prod jenkins server only.
# any application that is added is required to have a puppet class of it's own to work.
# new applications should be added in the case statement prior to running.
#
# Written by Ronen Amity        ronen_amity@intuit.com
# Ver 1.0                       9/6/2016
# Ver 1.1       Ronen Amity     9/8/2016
# Ver 1.2       Ronen Amity     9/20/2016       fixed ssh & scp issues
#
##############################################################################################################

#Compatibility check
if [ -z "$3" ]
then
        echo "Usage: $0 [RPM_PACKAGE_NAME] [VERSION] [WORKSPACE]"
        exit 1
fi
# Setting variables
PACKAGE_NAME=$1
VERSION=$2
WORKSPACE=$3
BATCH=1

# what class to check per package
case ${PACKAGE_NAME} in
        collection-rpm)
                CLASS=bills_agg_python
                BATCH=5
                VER_FILE=/opt/collection/collection-version.txt
                ;;
        apollo-rpm)
                CLASS=apollo-svc
                VER_FILE=/opt/apollo-svc/apollo-version.txt
                ;;
        postoffice-rpm)
                CLASS=postoffice-server
                VER_FILE=/opt/postoffice-server/postoffice-version.txt
                ;;
        *)
                echo "No package is defined"
                exit 99
                ;;
esac

# make sure /tmp is 1777 permision
/usr/bin/mco shell --dt 6  -C ${CLASS} --config /var/lib/jenkins/.mcollective -v "chmod 1777 /tmp"
# get list of machines per class and copy the deployment script to /tmp on that machine
for Machine in `mco find --config /var/lib/jenkins/.mcollective -C bills_agg_python | xargs`;do 
    /bin/su - jenkins -c "/usr/bin/scp ${WORKSPACE}/deploy/yum-install-upgrade-downgrade.sh ${Machine}:/tmp"
done
# give run permission to the script on all machines
/usr/bin/mco shell --dt 6 -C ${CLASS} --config /var/lib/jenkins/.mcollective -v "chmod 755 /tmp/yum-install-upgrade-downgrade.sh"
# run upgrade/downgrade per machine
/usr/bin/mco shell --config /var/lib/jenkins/.mcollective --batch ${BATCH} --batch-sleep 5 --dt 6 -C ${CLASS} -v "/tmp/yum-install-upgrade-downgrade.sh ${PACKAGE_NAME} ${VERSION}"
/usr/bin/mco shell --config /var/lib/jenkins/.mcollective -C ${CLASS} "echo ${VERSION} > ${VER_FILE}"
