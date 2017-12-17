#!/bin/bash

if [ "$#" -ne 2 ]; then
  echo Wrong parameter count
  echo Usage:
  echo ./delete-s3.sh \"s3://mys3bucket/apps/my-app/master\" \"7 days\"
  exit
fi

PLATFORM=$(uname)
COMMAND='date'

if [ "$PLATFORM" == "Darwin" ]; then
  if ! hash gdate 2>/dev/null; then
    echo gdate is not installed
    exit
  fi
  COMMAND='gdate'
fi

aws s3 ls "${1}/" | while read -r line; do
  # Get file modified date
  MODIFIED_DATE=$(echo $line | awk {'print $1" "$2'})

  # Get seconds from file modified date
  MODIFIED_SEC=$(${COMMAND} -d"${MODIFIED_DATE}" +%s)

  # Get seconds from "older than" date
  OLDER_THAN_SEC=$(${COMMAND} -d"-$2" +%s)

  # Compare
  if [ "$MODIFIED_SEC" -lt "$OLDER_THAN_SEC" ]; then
    FILE_NAME=$(echo $line | awk {'print $4'})
    if [ "$FILE_NAME" != "" ]; then
      aws s3 rm "${1}/${FILE_NAME}"
    fi
  fi
done
