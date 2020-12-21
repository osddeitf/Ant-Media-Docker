#!/bin/bash

# @author: osddeitf
# @version: 2.2.1-20201029_2042
# Custom, simplified install script for optimize Dockerfile output image size
# Original version: https://github.com/ant-media/Scripts/blob/2690dd89517fda3eadbd9ddf2e5ea66e2950bb09/install_ant-media-server.sh

AMS_BASE=/usr/local/antmedia

check() {
  OUT=$?
  if [ $OUT -ne 0 ]; then
    echo "There is a problem in installing the ant media server. Please send the log of this console to contact@antmedia.io"
    exit $OUT
  fi
}

SUDO="sudo"
if ! [ -x "$(command -v sudo)" ]; then
  SUDO=""
fi

# use ln because of the jcvr bug: https://stackoverflow.com/questions/25868313/jscv-cannot-locate-jvm-library-file 
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/
$SUDO mkdir -p $JAVA_HOME/lib/amd64
$SUDO ln -sfn $JAVA_HOME/lib/server $JAVA_HOME/lib/amd64/

# Install service
$SUDO cp $AMS_BASE/antmedia.service /lib/systemd/system/
$SUDO chmod 644 /lib/systemd/system/antmedia.service

$SUDO cp $AMS_BASE/antmedia /etc/init.d/
check

$SUDO update-rc.d antmedia defaults
check

$SUDO update-rc.d antmedia enable
check

# The following commands are handled in advance (for less layers), see `Dockerfile`
# $SUDO mkdir $AMS_BASE/log
# check
#
# $SUDO useradd -d $AMS_BASE/ -s /bin/false -r antmedia
# check
#
# $SUDO chown -R antmedia:antmedia $AMS_BASE/
# check

$SUDO service antmedia stop &
wait $!
$SUDO service antmedia start
check

echo "Ant Media Server is started"
