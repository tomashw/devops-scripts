#!/bin/bash 

#Compatibility check
if [ -z "$2" ]
then
        echo "Usage: $0 [RPM_PACKAGE_NAME] [VERSION]"
        exit 1
fi
# Setting variables
PACKAGE_NAME=$1
VERSION=$2
echo "Attempting to deploy ${PACKAGE_NAME} version ${VERSION}"
echo "Checking if ${PACKAGE_NAME}-${VERSION} is installed:"

if rpm -q ${PACKAGE_NAME}-${VERSION}
then
        # We handle versions
        echo "${PACKAGE_NAME}-${VERSION} is already installed. Attempting upgrade"
        # Upgrade will delete obsolete packages, while update will preserve them. We want to use upgrade.
        yum -y upgrade ${PACKAGE_NAME}-${VERSION} --disablerepo=* --enablerepo=internal-snapshots,internal-releases,prod-nexus-releases
        if rpm -q ${PACKAGE_NAME}-${VERSION}
        then
                echo ""
        else
                echo "Upgrade is not possible. Attempting downgrade"
                yum -y downgrade ${PACKAGE_NAME}-${VERSION} --disablerepo=* --enablerepo=internal-snapshots,internal-releases,prod-nexus-releases
        fi

        $(rpm -qa |grep ${PACKAGE_NAME} |grep -q ${VERSION})
        RESULT=$?
        if  [ "$RESULT" -eq "0" ]
        then
                echo "Package was changed to ${PACKAGE_NAME}-${VERSION}"
                exit 0
        else
                echo "Package couldn't change version to ${PACKAGE_NAME}-${VERSION}"
                echo "Package version stays $(rpm -qa | grep ${PACKAGE_NAME}-${VERSION})"
                exit 1
        fi
else
        echo ${PACKAGE_NAME}-${VERSION} is not installed
        echo going to install it...
        yum -y install ${PACKAGE_NAME}-${VERSION} --disablerepo=* --enablerepo=internal-snapshots,internal-releases,prod-nexus-releases
fi
