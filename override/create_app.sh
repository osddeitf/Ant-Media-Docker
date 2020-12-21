#!/bin/bash

usage() {
  echo "Usage:"
  echo "$0  {APPLICATION_NAME} [{INSTALL_DIRECTORY}]"
  echo "{APPLICATION_NAME} is the application name that you want to have. It's mandatory"
  echo "{INSTALL_DIRECTORY} is the install location of ant media server which is /usr/local/antmedia by default. It's optional"
  echo " "
  echo "Example: "
  echo "$0 live "
  echo " "
  echo "If you have any question, send e-mail to contact@antmedia.io"
}

if [[ -z "$1" ]]; then
    echo "Error: Missing parameter APPLICATON_NAME. Check instructions below"
    usage
    exit 1
fi

#set the app name
APP_NAME=$1
APP_NAME_LOWER=$(echo $APP_NAME | awk '{print tolower($0)}')

AMS_DIR=/usr/local/antmedia
APP_DIR=$AMS_DIR/webapps/$APP_NAME
RED5_PROPERTIES_FILE=$APP_DIR/WEB-INF/red5-web.properties
WEB_XML_FILE=$APP_DIR/WEB-INF/web.xml

mkdir $APP_DIR
unzip -q $AMS_DIR/StreamApp*.war -d $APP_DIR

sed -i 's^webapp.dbName=.*^webapp.dbName='$APP_NAME_LOWER'.db^' $RED5_PROPERTIES_FILE
sed -i 's^webapp.contextPath=.*^webapp.contextPath=/'$APP_NAME'^' $RED5_PROPERTIES_FILE
sed -i 's^db.app.name=.*^db.app.name='$APP_NAME'^' $RED5_PROPERTIES_FILE
sed -i 's^db.name=.*^db.name='$APP_NAME_LOWER'^' $RED5_PROPERTIES_FILE

sed -i 's^<display-name>StreamApp^<display-name>'$APP_NAME'^' $WEB_XML_FILE
sed -i 's^<param-value>/StreamApp^<param-value>/'$APP_NAME'^' $WEB_XML_FILE

chown -R antmedia:antmedia $APP_DIR
echo "Application $APP_NAME is created."
