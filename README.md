# Docker image for Ant Media Server
This repository is `Dockerfile` for building customized Ant Media Server Enterprise edition.

- This repo will not included installation `.zip` archive, for privacy reason.
- Community edition should work, too, but lacks of most feature, though tweaking the `Dockerfile` might necessary.
- Feel free to fork and edit this file to match your use case and expectation.

## Features
- Automatic setup cluster, currently works well on Kubernetes..
- Support S3-compatible video push via `settings.muxerFinishScript`.
- Application creation on start-up via `ANT_MEDIA_WEBAPPS`, rather than default `WebRTCAppEE` or `LiveApp`.
- Application configuration overwrite using mount points, no need to manually edit inside container.

## Requirements
- Ant Media `.zip` archive, either is Community or Enterprise edition, which suit your need.

## Environment variables
- `MONGODB_HOST`: mongodb ip / hostname.
- `MONGODB_USERNAME`(optional): for cluster mode, may needed in conjunction with `MONGODB_PASSWORD` for mongodb connection.
- `MONGODB_PASSWORD`(optional): for cluster mode.
- `ANT_MEDIA_LICENSE`: license for enterprise edition
- `ANT_MEDIA_WEBAPPS`: initialize webapps when container start, separated by `,` likes `staging,production`.
- `ANT_MEDIA_IPV4_IFNAME`: each node in cluster will be assigned a IPv4 based on a specific interface name.

Currently, Ant Media's `change_server_mode.sh` pick a random IPv4 from pool of network interfaces. This may leads to occasion when the same IPv4 is used amongst nodes. Use `ANT_MEDIA_IPV4_IFNAME` in combined with some overlay network like `flannel` to mitigate the risks.

## Mount points
- Folder `/etc/ant-media/app-settings`: Ant Media webapps settings overrides, e.g. content of file `[app_name].properties` will be appended to `webapps/[app_name]/WEB-INF/red5-web.properties`.
- The special overrides file `/etc/ant-media/app-settings/global.properties` is used for all apps.
- When you want to update application settings, after update the mounted files, restart the container (pod).
