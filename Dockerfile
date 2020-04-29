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

# Extract dashboard, discard default Apps
RUN cd webapps && \
    unzip root-1.9.1.war -d root && \
    rm LiveApp.war root-1.9.1.war WebRTCAppEE.war

# Without log folder with proper permission, server not working
RUN mkdir log
RUN touch log/ant-media-server.log

# Modify StreamApp.war
WORKDIR /StreamApp
COPY StreamApp .
RUN zip -ur /ant-media-server/StreamApp-1.9.1.war *

# Stage 2: The main part
FROM ubuntu:16.04
LABEL version "1.9.1-20200112_1830"
LABEL description "Ant Media Server Enterprise Edition, cluster mode"

# Copy from previous stage and pre-setup permission
RUN useradd -d /usr/local/antmedia/ -s /bin/false -r antmedia
COPY --from=packager --chown=antmedia:antmedia \
    /ant-media-server /usr/local/antmedia

# Run install scripts
WORKDIR /
COPY install.sh .
RUN ./install.sh

# Setup entrypoint, setting up cluster mode require `ifconfig` tool
WORKDIR /usr/local/antmedia
RUN apt-get update && apt-get install -y iproute2
COPY docker-entrypoint.sh .
ENTRYPOINT ./docker-entrypoint.sh && \
    # Update modified timestamp, force CoW (Copy-on-Write).
    :>> /usr/local/antmedia/log/ant-media-server.log && \
    # Watch for log
    tail -f /usr/local/antmedia/log/ant-media-server.log
