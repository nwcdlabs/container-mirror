#!/bin/bash
source mirror-base.sh

IMAGES_FILE_LIST='required-images.txt'

repos=$(grep -v ^# $IMAGES_FILE_LIST | cut -d: -f1 | sort -u)
for repo in ${repos[@]}
do
  replaceDomainName $repo
  createEcrRepo $URI $repo
done

images=$(grep -v ^# $IMAGES_FILE_LIST)
for image in ${images[@]}
do
  pullAndPush $image
done
