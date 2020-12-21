# Stage 1: Packaging
FROM alpine:3.11 AS packager

# Copy and extract archive
WORKDIR /
RUN apk add --no-cache zip unzip
COPY ant-media-server-enterprise.zip .
RUN unzip ant-media-server-enterprise

# Overwrite the scripts, without touching the original archive
WORKDIR /ant-media-server
COPY override ./

# Discard default Apps
RUN cd webapps && rm -R LiveApp WebRTCAppEE

# Modify StreamApp.war
RUN unzip StreamApp-2.2.1.war -d /StreamApp && \
    rm StreamApp-2.2.1.war
WORKDIR /StreamApp
COPY StreamApp .
RUN zip -r /ant-media-server/StreamApp-2.2.1.war *

# Stage 2: The main part
FROM ubuntu:20.04
LABEL version "2.2.1-20201029_2042"
LABEL description "Ant Media Server Enterprise Edition, cluster mode"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openjdk-11-jdk unzip jsvc libapr1 libssl-dev libva-drm2 libva-x11-2 libvdpau-dev libcrystalhd-dev \
        openjfx libopenjfx-java libopenjfx-jni

# Copy from previous stage and pre-setup permission
RUN useradd -d /usr/local/antmedia/ -s /bin/false -r antmedia
COPY --from=packager --chown=antmedia:antmedia \
    /ant-media-server /usr/local/antmedia

# Setup entrypoint, setting up cluster mode require `ifconfig` tool
WORKDIR /usr/local/antmedia
RUN apt-get update && apt-get install -y iproute2
COPY docker-entrypoint.sh .
ENTRYPOINT ./docker-entrypoint.sh
