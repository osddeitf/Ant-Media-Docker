#!/bin/bash

usage() {
  echo ""
  echo "This script change server mode to cluster or standalone"
  echo "Please use the script as follows."
  echo ""
  echo "Usage: "
  echo "Change server mode to cluster"
  echo "$0  cluster {MONGO_DB_SERVER}"
  echo "$0  cluster {MONGO_DB_SERVER} {MONGO_DB_USERNAME} {MONGO_DB_PASSWORD}"
  echo ""
  echo "Change server mode to standalone"
  echo "$0  standalone"
  echo ""
  echo "If you have any question, send e-mail to contact@antmedia.io"
}

MODE=$1
if [ -z "$MODE" ]; then
  echo "No server mode specified. Missing parameter"
  usage
  exit 1
fi

AMS_INSTALL_LOCATION=/usr/local/antmedia
USE_GLOBAL_IP="false"

if [ $MODE = "cluster" ]; then
  echo "Mode: cluster"
  DB_TYPE=mongodb
  MONGO_SERVER_IP=$2
    if [ -z "$MONGO_SERVER_IP" ]; then
      echo "No Mongo DB Server specified. Missing parameter"
      usage
      exit 1
    fi

  sed -i -E -e  's/(<!-- cluster start|<!-- cluster start -->)/<!-- cluster start -->/g' $AMS_INSTALL_LOCATION/conf/jee-container.xml
  sed -i -E -e  's/(cluster end -->|<!-- cluster end -->)/<!-- cluster end -->/g' $AMS_INSTALL_LOCATION/conf/jee-container.xml

else
  echo "Mode: standalone"
  DB_TYPE=mapdb
  MONGO_SERVER_IP=localhost
  sed -i -E -e  's/(<!-- cluster start -->|<!-- cluster start)/<!-- cluster start /g' $AMS_INSTALL_LOCATION/conf/jee-container.xml
  sed -i -E -e 's/(<!-- cluster end -->|cluster end -->)/cluster end -->/g' $AMS_INSTALL_LOCATION/conf/jee-container.xml
fi


LIST_APPS=`ls -d $AMS_INSTALL_LOCATION/webapps/*/`

sed -i 's#clusterdb.host=.*#clusterdb.host='$MONGO_SERVER_IP'#' $AMS_INSTALL_LOCATION/conf/red5.properties
sed -i 's/useGlobalIp=.*/useGlobalIp='$USE_GLOBAL_IP'/' $AMS_INSTALL_LOCATION/conf/red5.properties
sed -i 's/clusterdb.user=.*/clusterdb.user='$3'/' $AMS_INSTALL_LOCATION/conf/red5.properties
sed -i 's/clusterdb.password=.*/clusterdb.password='$4'/' $AMS_INSTALL_LOCATION/conf/red5.properties

for i in $LIST_APPS; do
  target=$i/WEB-INF/red5-web.properties
  sed -i 's/db.type=.*/db.type='$DB_TYPE'/' $target
  sed -i 's#db.host=.*#db.host='$MONGO_SERVER_IP'#' $target
  sed -i 's/db.user=.*/db.user='$3'/' $target
  sed -i 's/db.password=.*/db.password='$4'/' $target
done


if [ $ANT_MEDIA_IPV4_IFNAME ]; then
  # Fail if not found
  set -o pipefail
  LOCAL_IPv4=`ip address show $ANT_MEDIA_IPV4_IFNAME | sed -En 's/.*inet (([0-9]*\.){3}[0-9]*).*/\1/p'`
  if [ $? != 0 ]; then
    exit 1
  fi
else
  LOCAL_IPv4=`ip address | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`
fi
HOST_NAME=`cat /proc/sys/kernel/hostname`
HOST_LINE="$LOCAL_IPv4 $HOST_NAME"

# Change /etc/hosts file
# In docker changing /etc/hosts produces device or resource busy error.
# Above commands takes care the changing host file

# temp hosts file
NEW_HOST_FILE=~/.hosts.new
# cp hosts file
cp /etc/hosts $NEW_HOST_FILE
# delete hostname line from the file
sed -i '/'$HOST_NAME'/d' $NEW_HOST_FILE
# add host line to the file
echo  "$HOST_LINE" | tee -a $NEW_HOST_FILE
# change the /etc/hosts file - (mv does not work)
cp -f $NEW_HOST_FILE /etc/hosts
# remove temp hosts file
rm $NEW_HOST_FILE
