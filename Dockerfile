# Stage 1: Packaging
FROM alpine:3.11 AS packager

# Copy and extract archive
WORKDIR /
RUN apk add --no-cache zip unzip
COPY ant-media-server-enterprise.zip .
RUN unzip ant-media-server-enterprise

WORKDIR /ant-media-server

# Discard default Apps
RUN cd webapps && rm -R LiveApp WebRTCAppEE

# Modify StreamApp.war
RUN unzip StreamApp-2.2.1.war -d /StreamApp && \
    rm StreamApp-2.2.1.war
WORKDIR /StreamApp
COPY StreamApp .
RUN zip -r /ant-media-server/StreamApp-2.2.1.war *

FROM debian:buster-slim AS mc
RUN apt-get update && apt-get install -y --no-install-recommends wget ca-certificates
RUN wget https://dl.min.io/client/mc/release/linux-amd64/mc && chmod +x mc

# Stage 2: The main part
FROM ubuntu:20.04
LABEL version "2.2.1-20201029_2042"
LABEL description "Ant Media Server Enterprise Edition, cluster mode"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openjdk-11-jdk unzip jsvc libapr1 libssl-dev libva-drm2 libva-x11-2 libvdpau-dev libcrystalhd-dev \
        openjfx libopenjfx-java libopenjfx-jni

# S3 push
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates ffmpeg jq curl
COPY --from=mc mc /usr/local/bin/mc
RUN mc config host rm s3

# Copy from previous stage and pre-setup permission
WORKDIR /usr/local/antmedia
RUN useradd -d /usr/local/antmedia/ -s /bin/false -r antmedia
COPY --from=packager --chown=antmedia:antmedia /ant-media-server .

# Overwrite the scripts, without touching the original archive
COPY override .

# Setup entrypoint, setting up cluster mode require `ifconfig` tool
RUN apt-get update && apt-get install -y iproute2
COPY docker-entrypoint.sh .
ENTRYPOINT ./docker-entrypoint.sh
