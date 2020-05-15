#!/bin/bash

# @author: osddeitf
# Custom, simplified install script for optimize Dockerfile output image size
# Original version: https://github.com/ant-media/Scripts/blob/dc9c8076909574e53eaf61268b7f69f78dca3a87/install_ant-media-server.sh

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

# Install dependencies
$SUDO apt-get update -y
check

$SUDO apt-get install openjdk-8-jdk openjfx jsvc unzip -y
check


$SUDO sed -i '/JAVA_HOME="\/usr\/lib\/jvm\/java-8-oracle"/c\JAVA_HOME="\/usr\/lib\/jvm\/java-8-openjdk-amd64"'  $AMS_BASE/antmedia
check

# Install service
$SUDO cp $AMS_BASE/antmedia /etc/init.d/
check

$SUDO update-rc.d antmedia defaults
check

$SUDO update-rc.d antmedia enable
check

# The following commands are handled in advance, see `Dockerfile`
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
