#!/bin/bash

parse_paramters() {
	for param in $* ; do
	        case $param in
	        --po_env=*)  PO_ENV=${param##*--po_env=} ;;
	        --path=*)    SVN_PATH=${param##*--path=} ;;
            *)           log_this ERROR "Unknow parameter !!!"
				         usage
	                     exit 5
	        ;;
	        esac
	done
	
	#validating
	if [ -z "$PO_ENV" ];then
		echo "ERROR::po_env flag is mandatory"
		usage
		exit 1
	fi
    
    if [ -z "$SVN_PATH" ];then
		echo "ERROR::path flag is mandatory"
		usage
		exit 1
	fi

}

usage() {
    echo -e  "\nUSAGE:\n$0 --po_env=production --path=/home/bar/foo/"
    exit 555
}

get_relevant_file_list() {
    #$1 = SVN_PATH $2 = CURRENT_DB_VER
    for file in $(ls -1 ${1}/*.sql ); do 
        svn info ${file}   --xml |xmlstarlet  sel -t   -v "//commit/@revision" -o " " -v "//entry/@path"
    done | sort -k 1 -n |awk "\$1 >= $2 { print \$2}"
}

get_file_revision() {
    svn info $1  --xml |xmlstarlet  sel -t   -v "//commit/@revision" | awk '{print $NF}'
}

get_author_email() {
    #$1 is the filename in the working copy
    URL_OF_TRUNK_FILE=$(svn info $1 --xml  | xmlstarlet sel -t -v //url | sed 's|branches/*[a-z A-Z]*/|trunk/|')
    AUTHOR_USERNAME=$(svn info $URL_OF_TRUNK_FILE --xml | xmlstarlet sel -t -v //author )
    AUTHOR_EMAIL=$(ldapsearch  -x  -LLL \
        -D "CN=admin-http,OU=System Users,OU=Users,OU=MyBusiness,DC=local" \
        -w ${LDAP_PASS} \
        -b "OU=MyBusiness,DC=local" \
        -s sub \
        -H ldap://${LDAP_SERVER} \
        "(&(objectClass=user)(sAMAccountName=${AUTHOR_USERNAME}))" mail |grep ^mail |awk '{print $NF}')
    if [ "$AUTHOR_EMAIL" == "" ] ; then
        AUTHOR_EMAIL="it_support@pageonce.com"
    fi
    echo $AUTHOR_EMAIL
}

run_sql_query() {
    if [ "$2" == "verbose" ] ; then
        mysql --defaults-extra-file=~/.${PO_ENV}.cnf --batch  -vvv --execute="$1" 2>"$SQL_ERROR"
    else
        mysql --defaults-extra-file=~/.${PO_ENV}.cnf --batch  --skip-column-names --execute="$1" 2>&1
    fi
}

run_sql_update_query() {
	${UPDATE_SQL_RUN_STRING}"$1" 2>&1
}


log_this() {
    #$1 is ERROR/DEBUGWARNNING/INFO $2 is message body
	echo -e "$(date   +%b\ %d\ %H:%M:%S) ${1}::$2"
}


check_if_file_was_run() {
    #$1 = file name, $2=file revision
    POSSIBLE_REV=$(run_sql_query "select file_revision from sql_deployed_files where file_name = '$1';")
    if [ -z "$POSSIBLE_REV" ]; then
        echo "No"
    else
        echo "Yes"
    fi
}

#################################
########## MAIN #################
#################################

parse_paramters $*
#source is for LDAP_PASS
source ~/ldap_pass.sh

DEFAULT_EMAIL="it_team@me.com"
SQL_RUN_STRING="mysql --defaults-extra-file=~/.${PO_ENV}.cnf --batch  --skip-column-names --execute="
UPDATE_SQL_RUN_STRING="mysql --defaults-extra-file=~/.${PO_ENV}.cnf --batch  -vvv --execute="

LDAP_SERVER="adsrv"

CURRENT_DB_VER="$(run_sql_query "select max(file_revision) - 1 from sql_deployed_files;")"
TMPFILE=/tmp/$(basename $0).$$
cat /dev/null > $TMPFILE

for SQL_SCRIPT_FILE in $(get_relevant_file_list $SVN_PATH $CURRENT_DB_VER);do
    SHORT_FILENAME=${SQL_SCRIPT_FILE##*/}
    FILE_REVISION=$(get_file_revision ${SQL_SCRIPT_FILE})
    if [ "$(check_if_file_was_run "$SHORT_FILENAME" "$FILE_REVISION" )" == "No" ] ;then
        log_this INFO "Starting $SHORT_FILENAME :"
	AUTHOR_EMAIL=$(get_author_email $SQL_SCRIPT_FILE)
	EMAILS_LIST="${AUTHOR_EMAIL},${DEFAULT_EMAIL}"
        run_sql_query "INSERT INTO sql_deployed_files (file_name,file_owner,file_revision,deploy_status) VALUES('$SHORT_FILENAME','${AUTHOR_EMAIL}','${FILE_REVISION}','started');"
	SQL_ERROR=$(mktemp)
        SQL_OUTPUT=$(run_sql_query "source $SQL_SCRIPT_FILE" "verbose")
        if [ $? -eq 0 ]; then
            run_sql_query "update sql_deployed_files set deploy_status='finished' where file_name = '${SHORT_FILENAME}' and file_revision = '${FILE_REVISION}';" 
            echo -e  "\n#####################################\n$SQL_OUTPUT\n#####################################\n"
            log_this INFO "$SHORT_FILENAME run successfully, notifing $EMAILS_LIST"
            SHORT_FILENAMES="$SHORT_FILENAMES $SHORT_FILENAME"
            echo "======================${SHORT_FILENAME}==============================================" >> $TMPFILE
            cat $SQL_SCRIPT_FILE >> $TMPFILE
            #echo " " | /bin/mail -s "SQLUPDATE: Successfully run $SHORT_FILENAME on $PO_ENV<EOM>" $EMAILS_LIST
        else
            run_sql_query "update sql_deployed_files set deploy_status='error' where file_name = '${SHORT_FILENAME}' and file_revision = '${FILE_REVISION}';" 
            echo -e  "\n#####################################\n$SQL_OUTPUT\n$(cat $SQL_ERROR)#####################################\n"
            log_this ERROR "$SHORT_FILENAME failed !!!!! notifing $EMAILS_LIST"
            SHORT_FILENAMES="$SHORT_FILENAMES $SHORT_FILENAME"
            echo "======================${SHORT_FILENAME}==============================================" >> $TMPFILE
            cat $SQL_SCRIPT_FILE >> $TMPFILE
            echo -e "$(cat $SQL_ERROR)\n see ${BUILD_URL}/console for full log"  | mail -s "SQLUPDATE: Failed(!) to run  $SHORT_FILENAME on $PO_ENV" $EMAILS_LIST
            exit 1
        fi
	rm -f $SQL_ERROR

    else
        log_this INFO "Skipping $SHORT_FILENAME :"
    fi

done

if [ -s $TMPFILE ]; then
	/bin/mail -s "SQLUPDATE: Contents of $SHORT_FILENAMES on $PO_ENV that where executed (successfully and failed) during this patch/build" CEG-CheckPlatDB@intuit.com,CEG-CheckIT@intuit.com < $TMPFILE
fi

test -a  $TMPFILE && rm  $TMPFILE
