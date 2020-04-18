FROM ubuntu:16.04
LABEL version "1.9.1-20200112_1830"
LABEL description "Ant Media Server Enterprise Edition, cluster mode"

# Install
WORKDIR /
COPY install.sh .
COPY ant-media-server-enterprise.zip .
RUN ./install.sh ant-media-server-enterprise.zip && \
    rm install.sh ant-media-server-enterprise.zip

WORKDIR /usr/local/antmedia
COPY override/* ./

# Prepopulate webapps resource from archive.
RUN cd webapps && \
    unzip root-1.9.1.war -d root && \
    rm LiveApp.war root-1.9.1.war WebRTCAppEE.war

RUN ./create_app.sh staging $(pwd) && \
    ./create_app.sh production $(pwd)

RUN chown -R antmedia:antmedia .

# `ifconfig` is needed by `docker-entrypoint.sh` -> `change_server_mode.sh`
RUN apt-get update && apt-get install -y net-tools

# Setup entrypoint
COPY docker-entrypoint.sh .
ENTRYPOINT ./docker-entrypoint.sh && /bin/bash
