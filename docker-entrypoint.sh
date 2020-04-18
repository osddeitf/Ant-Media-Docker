#!/bin/bash

AMS_INSTALL_LOCATION=/usr/local/antmedia

# By link/stack - generated service name convention
MONGODB_ENV_NAME=${MONGODB_SERVICE_NAME}_SERVICE_HOST
MONGODB_ENV_NAME_ALT=${MONGODB_SERVICE_NAME}_LOADBALANCER_TCP_SERVICE_HOST

# Get 
if [ ${!MONGODB_ENV_NAME} ]; then
    MONGODB_SERVER=${!MONGODB_ENV_NAME}
elif [ ${!MONGODB_ENV_NAME_ALT} ]; then
    MONGODB_SERVER=${!MONGODB_ENV_NAME_ALT}
else
    echo "Could not find MongoDB service running in cluster" > /dev/stderr
    exit 1
fi

# Read secrets
SECRETS=/etc/ant-media
LICENSE=$(cat $SECRETS/license)
# MONGODB_SERVER=$MONGODB_SERVICE_NAME
MONGODB_USERNAME=$(cat $SECRETS/mongodb-username)
MONGODB_PASSWORD=$(cat $SECRETS/mongodb-password)

# Set-up license
sed -i 's/server\.licence_key=.*/server\.licence_key='$LICENSE'/' $AMS_INSTALL_LOCATION/conf/red5.properties

# Set-up cluster (if success, restart the daemon)
$AMS_INSTALL_LOCATION/change_server_mode.sh cluster $MONGODB_SERVER $MONGODB_USERNAME $MONGODB_PASSWORD

# Tweak: customize default settings base on environment variables
APP_DIRECTORIES=$(ls -d $AMS_INSTALL_LOCATION/webapps/*/ | sed 's/\/$//')

for APP_DIRECTORY in $APP_DIRECTORIES; do
    APP_PROPERTIES_FILE=$APP_DIRECTORY/WEB-INF/red5-web.properties
    echo -e "\n# Custom default settings" >> $APP_PROPERTIES_FILE
    echo "settings.listenerHookURL=$DEFAULT_LISTENER_HOOK_URL" >> $APP_PROPERTIES_FILE
done
