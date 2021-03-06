#!/bin/bash

AMS_DIR=/usr/local/antmedia

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

# Set-up license
sed -i 's/server\.licence_key=.*/server\.licence_key='$LICENSE'/' $AMS_DIR/conf/red5.properties

# Create apps (from comma separated values)
IFS=',' read -ra INIT_WEBAPPS <<< $ANT_MEDIA_WEBAPPS
for APP in ${INIT_WEBAPPS[@]}; do
    if [ -e $AMS_DIR/webapps/$APP ]; then
        continue
    fi
    $AMS_DIR/create_app.sh $APP
done

# Set-up cluster (if success, restart the daemon)
$AMS_DIR/change_server_mode.sh cluster $MONGODB_SERVER $MONGODB_USERNAME $MONGODB_PASSWORD

# Tweak: customize default settings base on environment variables
APP_DIRECTORIES=$(cd $AMS_DIR/webapps/ && ls -d */ | sed 's/\/$//')
GLOBAL_APP_CONFIGURATION=/etc/ant-media/app-settings/global.properties

for APP_NAME in $APP_DIRECTORIES; do
    APP_PROPERTIES_FILE=$AMS_DIR/webapps/$APP_NAME/WEB-INF/red5-web.properties

    if [ $APP_NAME != root ]; then    
        if [ -r $GLOBAL_APP_CONFIGURATION ]; then
            echo "Restoring settings from $GLOBAL_APP_CONFIGURATION to $APP_PROPERTIES_FILE"
            echo -e "\n# Global setting" >> $APP_PROPERTIES_FILE
            cat $GLOBAL_APP_CONFIGURATION >> $APP_PROPERTIES_FILE
        fi
    fi

    APP_CONFIGURATION=/etc/ant-media/app-settings/$APP_NAME.properties
    if [ -r $APP_CONFIGURATION ]; then
        echo "Restoring settings from $APP_CONFIGURATION to $APP_PROPERTIES_FILE"
        echo -e "\n# Override settings" >> $APP_PROPERTIES_FILE
        cat $APP_CONFIGURATION >> $APP_PROPERTIES_FILE
    fi
done
