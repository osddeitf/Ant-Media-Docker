#!/bin/bash

# Config s3 host if not done yet.
mc config host list s3 > /dev/null 2>&1
status=$?
if [ $status != 0 ]; then
  # Try again upto 3 times, waiting 5s each
  for i in $(seq 1 3); do
    echo "Trying connect to s3..."
    mc config host add s3 $S3_ENDPOINT $S3_ACCESS_KEY $S3_SECRET_KEY && break
    s=$?

    if [ $i = 3 ]; then
      echo "Error connecting to s3." >&2
      exit $s
    else
      sleep 5
    fi
  done;
fi

function evoke() {
  set -ve
  "$@"
  set +ve
}

VIDEO=$1
PREVIEW=$(echo $1 | sed -E "s/.mp4$/.png/")

# Generate preview
seek=$(ffmpeg -i $VIDEO 2>&1 | grep -E '^\s+Duration' | sed -E 's/^\s+Duration:\s*([0-9:]+).*/\1/')
if [[ $seek > $PREVIEW_TIME ]]; then
  seek=$PREVIEW_TIME
fi
evoke ffmpeg -i $VIDEO -ss $seek -vframes 1 -vcodec png $PREVIEW

# Push to s3
evoke mc cp $PREVIEW s3/$S3_PREVIEW_BUCKET/$(basename $PREVIEW)
evoke mc cp $VIDEO s3/$S3_VIDEO_BUCKET/$(basename $VIDEO)

# Get preview size. TODO: should get video size as well?
size=$(ffprobe -v error -show_entries stream=width,height -i $PREVIEW -of json | jq .streams[])

# Webhook notification
evoke curl -f \
  -X POST \
  -H 'Content-Type: application/json' \
  -d "{\
    \"video\":\"$(basename $VIDEO)\",\
    \"preview\":\"$(basename $PREVIEW)\",\
    \"video_bucket\":\"$S3_VIDEO_BUCKET\",\
    \"preview_bucket\":\"$S3_PREVIEW_BUCKET\",\
    \"resolution\":$size\
  }" \
  $WEBHOOK_ENDPOINT

# Clean-up
rm -f $VIDEO $PREVIEW
