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

# Create apps (separated by semicolon ;)
IFS=',' read -ra INIT_WEBAPPS <<< $ANT_MEDIA_WEBAPPS
for APP in ${INIT_WEBAPPS[@]}; do
    if [ -e $AMS_INSTALL_LOCATION/webapps/$APP ]; then
        continue
    fi
    echo "Creating app with name $APP..."
    $AMS_INSTALL_LOCATION/create_app.sh $APP $AMS_INSTALL_LOCATION
    chown -R antmedia:antmedia $AMS_INSTALL_LOCATION/webapps/$APP
done

# Set-up cluster (if success, restart the daemon)
$AMS_INSTALL_LOCATION/change_server_mode.sh cluster $MONGODB_SERVER $MONGODB_USERNAME $MONGODB_PASSWORD

# Tweak: customize default settings base on environment variables
APP_DIRECTORIES=$(cd $AMS_INSTALL_LOCATION/webapps/ && ls -d */ | sed 's/\/$//')
GLOBAL_APP_CONFIGURATION=/etc/ant-media/app-settings/global.properties

for APP_NAME in $APP_DIRECTORIES; do
    APP_PROPERTIES_FILE=$AMS_INSTALL_LOCATION/webapps/$APP_NAME/WEB-INF/red5-web.properties

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
