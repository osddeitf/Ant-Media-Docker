APP_NAME=$1
AMS_DIR=$2
APP_NAME_LOWER=$(echo $APP_NAME | awk '{print tolower($0)}') 
APP_DIR=$AMS_DIR/webapps/$APP_NAME
RED5_PROPERTIES_FILE=$APP_DIR/WEB-INF/red5-web.properties
WEB_XML_FILE=$APP_DIR/WEB-INF/web.xml

mkdir $APP_DIR 
unzip $AMS_DIR/StreamApp*.war -d $APP_DIR

OS_NAME=`uname`

if [[ "$OS_NAME" == 'Darwin' ]]; then
  SED_COMPATIBILITY='.bak'
fi
sed -i $SED_COMPATIBILITY 's^webapp.dbName=.*^webapp.dbName='$APP_NAME_LOWER'.db^' $RED5_PROPERTIES_FILE
sed -i $SED_COMPATIBILITY 's^webapp.contextPath=.*^webapp.contextPath=/'$APP_NAME'^' $RED5_PROPERTIES_FILE
sed -i $SED_COMPATIBILITY 's^db.app.name=.*^db.app.name='$APP_NAME'^' $RED5_PROPERTIES_FILE
sed -i $SED_COMPATIBILITY 's^db.name=.*^db.name='$APP_NAME_LOWER'^' $RED5_PROPERTIES_FILE

sed -i $SED_COMPATIBILITY 's^<display-name>StreamApp^<display-name>'$APP_NAME'^' $WEB_XML_FILE
sed -i $SED_COMPATIBILITY 's^<param-value>/StreamApp^<param-value>/'$APP_NAME'^' $WEB_XML_FILE
