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

# Specific package version is already installed
if rpm -q ${PACKAGE_NAME}-${VERSION}
then
        echo "${PACKAGE_NAME}-${VERSION} is already installed. Exiting."
        exit 0
fi

# Check if any version of the package is installed
if rpm -q ${PACKAGE_NAME}
then
        # Another version of the package already exists
        echo "${PACKAGE_NAME} is already installed. Checking upgrade/downgrade"
        
        CURRENT_VERSION=$(rpm -q --qf "%{VERSION}" ${PACKAGE_NAME})
        
        # Upgrade if current version is smaller than one required, else downgrade
        if ( /tmp/version_compare.sh ${CURRENT_VERSION} ${VERSION} '<') ; then
                # Upgrade will delete obsolete packages, while update will preserve them. We want to use upgrade.
                yum -y upgrade ${PACKAGE_NAME}-${VERSION} --disablerepo=* --enablerepo=internal-snapshots,internal-releases,prod-nexus-releases
        else
                # Downgrade will delete obsolete package.
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
                echo "Package version stays $(rpm -qa | grep ${PACKAGE_NAME}-${CURRENT_VERSION})"
                exit 1
        fi
else
        echo ${PACKAGE_NAME}-${VERSION} is not installed
        echo going to install it...
        yum -y install ${PACKAGE_NAME}-${VERSION} --disablerepo=* --enablerepo=internal-snapshots,internal-releases,prod-nexus-releases
fi
