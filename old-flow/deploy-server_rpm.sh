#!/bin/bash
# This script will run remotely a deploy script on each of the vm servers (roles on a server)
# Parameters: --build=build_number --server=phy_server (--server=phy_server2 ...) (roles)
# Written by Etzion Bar-Noy
#	Opal Systems. 054-6511123

# Check if we have parameters at all. If not, we will run on all machines
# on this physical host
if [ -z "$1" ]; then
	echo "No parameters given"
	echo "Usage: $0 [--build=build] [--type=deployment_type]  [--roles=web,app,collection,management,admin,management-new,solo,horizon,keymanager,hasky_admin  ]"
	exit 1
fi

env|grep roles2deploy

# Zero variables
ROLES=""
#FULL_ROLE_LIST="web app collection management admin solo postoffice rdb horizon keyManager haskyAdmin"
##RR FULL_ROLE_LIST="web app collection management admin solo rdb horizon keyManager haskyAdmin"
FULL_ROLE_LIST="web app collection management admin solo rdb keyManager haskyAdmin admin7"

FAIL_FLAG=0

# Zero log file

for i in $* ; do
	case $i in


		--roles=*)
			ROLES="${i##*--roles=}"
			


		;;
		--po_env=*)
			PO_ENV="${i##*--po_env=}"
		
		;;	
		*)
			echo "Unknow parameter !!!"
			exit 555
		;;
	esac
done

if [ "$PO_ENV" != "production" ]; then 
        if [ "$PO_ENV" != "staging" ]; then
                echo "--po_env must be production or staging"
                exit 1
        fi
fi


if [[  $ROLES = *ALL* ]]; then
	ROLES=$FULL_ROLE_LIST

fi

if [ -z "$ROLES" ]; then
	ROLES=$FULL_ROLE_LIST
fi

deploy_user="it_admin"
ssh_command="ssh  -ti /var/lib/jenkins/.ssh/jenkins_jenkins"
#yum_command="sudo yum install -y --verbose -d 3"
yum_command="sudo -i yum install -y --verbose -d 3"
#yum_command="sudo id"



for C_ROLE in $(echo $ROLES  |sed 's/\,/\n/g')  ;do
echo -e "\n\n"
echo -e " $C_ROLE"| tr  '[a-z]' '[A-Z]'
echo -e "#################################"
case $C_ROLE in

	web)
	class_name=web
	rpm_name=pageonce-web
	echo -n "$SVN_REVISION" > /var/lib/jenkins/odd/config/${PO_ENV}_web_desiered_version.txt
	;;

	app)
	class_name=app
	rpm_name=pageonce-app
	echo -n "$SVN_REVISION" > /var/lib/jenkins/odd/config/${PO_ENV}_app_desiered_version.txt
	;;

	horizon)
	class_name=horizon
	rpm_name=pageonce-horizon
	echo -n "$SVN_REVISION" > /var/lib/jenkins/odd/config/${PO_ENV}_horizon_desiered_version.txt
	;;

	keyManager)
	class_name=keymanager
	rpm_name=pageonce-keyManager
	echo -n "$SVN_REVISION" > /var/lib/jenkins/odd/config/${PO_ENV}_keymanager_desiered_version.txt
	;;

	haskyAdmin)
	class_name=hasky_admin
	rpm_name=pageonce-haskyAdmin
	echo -n "$SVN_REVISION" > /var/lib/jenkins/odd/config/${PO_ENV}_hasky_admin_desiered_version.txt
	;;

	admin)
	class_name=admin
	rpm_name=pageonce-admin
	echo -n "$SVN_REVISION" > /var/lib/jenkins/odd/config/${PO_ENV}_admin_desiered_version.txt
	;;


	collection)
	class_name=collection_python
        rpm_name=pageonce-collection
	if [ -z "$SVN_REVISION" ] ;then 
		echo SVN_REVISION is missing
		exit 665
	fi
	echo -n "$SVN_REVISION" > /var/lib/jenkins/odd/config/${PO_ENV}_collection_desiered_version.txt
	#echo update  netgate_properties set VALUE = \'${SVN_REVISION}\' where PROPERTY = \'PythonMinCodeRevision\'\; |mysql --defaults-extra-file=/centralStorage/oded/.python_${PO_ENV}_ops.cnf
        if [ "$?" -ne 0 ]; then FAIL_FLAG=1 ; fi
	
	#echo update  netgate_properties set VALUE = \'$(svn info Project/|grep ^Revision|awk '{print $NF}')\' where PROPERTY = \'PythonMinCodeRevision\'\;
        #if [ "$?" -ne 0 ]; then FAIL_FLAG=1 ; fi
	
	;;


	management)
	class_name=management_new
	rpm_name=pageonce-management
	echo -n "$SVN_REVISION" > /var/lib/jenkins/odd/config/${PO_ENV}_management_desiered_version.txt
	;;

        solo)
	class_name=solo
	rpm_name=pageonce-solo
	echo -n "$SVN_REVISION" > /var/lib/jenkins/odd/config/${PO_ENV}_solo_desiered_version.txt
        ;;

        postoffice)
	class_name=kaka
        # We run this script localy and push the build to the server (it's hardcoded
        # into the script) because this server has no nfs access
        #/centralStorage/scripts/deploy_build/po_deploy.sh staging staging pageonce
	if [ "$PO_ENV" = "staging" ] ; then
		po_server='10.1.107.1'
	elif [  "$PO_ENV" = "production" ] ; then
		po_server='10.1.107.10'
	else
   		echo "build type must be staging or production"
   		exit 1
	fi
	scp  -i ~jenkins/.ssh/jenkins_jenkins /var/www/html/yum/${PO_ENV}/pageonce-postoffice-${SVN_REVISION}-*.x86_64.rpm it_admin@${po_server}:~/
	#IK ssh it_admin@${po_server} -ti ~jenkins/.ssh/jenkins_jenkins "sudo yum localinstall -y --nogpg --verbose -d 3  ~/pageonce-postoffice-${SVN_REVISION}-*.x86_64.rpm  && rm ~/pageonce-postoffice-${SVN_REVISION}-*.x86_64.rpm -v"
	ssh it_admin@${po_server} -t -ti ~jenkins/.ssh/jenkins_jenkins "sudo yum localinstall -y --nogpg --verbose -d 3  ~/pageonce-postoffice-${SVN_REVISION}-*.x86_64.rpm  && rm ~/pageonce-postoffice-${SVN_REVISION}-*.x86_64.rpm -v"
	if [ "$?" -ne 0 ]; then FAIL_FLAG=1 ; fi

	;;

        rdb)
	class_name=kaka
	if [  "$PO_ENV" = "production" ] ; then
		#server_name='10.1.109.107'
		server_name='HV1-3-43'
		rpm_name="pageonce-rdb"
		echo -n "# deploying ${rpm_name} to ${server_name}:"
		ssh_output=$($ssh_command ${deploy_user}@${server_name} $yum_command ${rpm_name} 2>&1)
        	if [ "$?" -ne 0 ]; then 
			FAIL_FLAG=1
			echo "$ssh_output"
		else
			echo " Done"
		fi

	fi
	;;
	*)

	echo "Uknown comp"
	exit 666
	;;


esac
	
for server_name in $(~jenkins/foreman_host_query.rb "class = $class_name and  environment =  ${PO_ENV}"); do
	echo -n "# deploying ${rpm_name} to ${server_name}:"
	ssh_output=$($ssh_command ${deploy_user}@${server_name} $yum_command ${rpm_name} 2>&1)
        if [ "$?" -ne 0 ]; then 
		FAIL_FLAG=1
		echo "$ssh_output"
	else
		echo " Done"
	fi

done


#/usr/local/bin/mc-package.jenkins --config ~/mcollective_client.cfg --with-class=$class_name --with-fact=pageonce_environment=${PO_ENV} status ${rpm_name}



done

exit $FAIL_FLAG

