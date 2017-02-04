#!/bin/bash
SRC_DIR=/var/lib/jenkins/jobs/e2e-compile-and-deploy-monolith/workspace/
TARGET_DIR=/var/www/yum/
umask 0022

move_rpms() {
        # Moves the RPMS to the TARGET_DIR and creates repo
        if [ -d ${TARGET_DIR} ]
        then
                cd $SRC_DIR
                # Do we have new RPMs?
                if [ `find ./ -name '*.rpm' | wc -l` -gt 0 ]
                then
                        find ./ -name '*.rpm' -exec mv {} ${TARGET_DIR}/ \;
                fi
        else
                echo "Directory $TARGET_DIR does not exist"
                exit 1
        fi
        cd $TARGET_DIR
        chmod 755 *.rpm
        # clean old non needed rpms keeping last 2
        for i in `ls ${TARGET_DIR}/*rpm | awk -F- '{print $2}' | sort -u`;do
                echo +++++++ $i +++++++
                DELETE=$(ls -tr1 ${TARGET_DIR}/*$i*.rpm | head -n -2)
                if [ ! -z $DELETE ]; then
                        echo "Will remove :  ${DELETE}"
                        /bin/rm ${DELETE}
                fi
        done
        # create the new repo
        sudo createrepo .
}

deploy() {
        # Performs SSH and runs 'yum install'
        # Arguments: $1: component ; $2 and onwards: server list
        # Check variables
        if [ -z "$2" ]
        then
                echo "Failed to get server list"
                exit 1
        fi
##        PKG_NAME=pageonce-${1}-${REVISION}
        PKG_NAME=pageonce-${1}
        shift
        for j in $@
        do
                echo "output for yum upgrade -y ${PKG_NAME} on host ${j}:"
                ssh $j "sudo yum install -y ${PKG_NAME}"
                echo ""
        done
}

# Parse arguments
# Test
if [ -z "$2" ]
then
        echo "Not enough arguments"
        exit 1
fi
ROLES=$1
REVISION=$2

admin_SERVERS="hv1-4-7-admin"
collection_SERVERS="mp1-0-16-col-agent6"
management_SERVERS="hv1-3-44-mng mp3-0-12-mng mp3-0-13-mng mp5-0-3-mng"

if [ ${ROLES} == "ALL" ]
then
        ROLES="collection,management,admin"
fi

move_rpms

for i in `echo $ROLES | tr , ' '`
do
        VARNAME=${i}_SERVERS
        SERVERS=${!VARNAME}

        # Adjustments
        [ "$i" == "admin7" ] && i=admin
        [ "$i" == "collection_new" ] && i=collection

        deploy $i $SERVERS
done
