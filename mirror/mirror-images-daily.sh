#!/bin/bash
source mirror-base.sh

IMAGES_DAILY_FILE_LIST='required-images-daily.txt'

images=$(grep -v ^# $IMAGES_DAILY_FILE_LIST)
for image in ${images[@]}
do
  repo=`echo ${image}|cut -d: -f1`
  echo "******begin pull ${repo} all tag******"
  if inArray "${repo}" "$blacklist"
  then
    echo "repo: $repo on the blacklist"
  else
    replaceDomainName $repo
    createEcrRepo $URI $repo
    allTags=`wget -q https://registry.hub.docker.com/v1/repositories/${repo}/tags -O -  | sed -e 's/[][]//g' -e 's/"//g' -e 's/ //g' | tr '}' '\n'  | awk -F: '{print $3}' | grep -v nanoserver | grep -v windowsservercore | grep -v alpha | grep -v beta`
    existTags=$(aws --profile ChinaECR --region $ECR_REGION ecr list-images --repository-name $URI |jq -r ".imageIds[]|.imageTag")
    existTags=$(echo $existTags | tr " " "\n" | sort)
    for tag in ${allTags}
    do
      if inArray "${tag}" "$existTags"
	  then
        echo "exist ${repo}:${tag}"
      else
        pullAndPush "${repo}:${tag}"
      fi
    done
  fi
done