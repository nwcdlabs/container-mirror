#!/bin/bash

ECR_REGION_FROM='cn-northwest-1'
ECR_DN_FROM="048912060910.dkr.ecr.${ECR_REGION_FROM}.amazonaws.com.cn"

ECR_REGION_TO='cn-north-1'
ECR_DN_TO="048912060910.dkr.ecr.${ECR_REGION_TO}.amazonaws.com.cn"


function createEcrRepo() {
  if inArray "$1" "$allEcrReposTo"
  then
    echo "repo: $1 already exists"
  else
    echo "creating repo: $1"
    aws --profile=ecrTo --region ${ECR_REGION_TO} ecr create-repository --repository-name "$1"    
    attachPolicy "$1"
  fi
}

function attachPolicy() {
  echo "attaching public-read policy on ECR repo: $1"
  aws --profile ecrTo --region $ECR_REGION_TO ecr set-repository-policy --policy-text file://policy.text --repository-name "$1"
}

function inArray() {
    local list=$2
    local elem=$1  
    for i in ${list[@]}
    do
        if [ "$i" == "${elem}" ] ; then
            return 0
        fi
    done
    return 1    
}

function loginEcr() {
  aws --profile=ecrFrom ecr --region ${ECR_REGION_FROM} get-login --no-include-email | sh
  aws --profile=ecrTo ecr --region ${ECR_REGION_TO} get-login --no-include-email | sh
}

function pullAndPush(){
  imgOriginal="$1"
  
  imgFrom="$ECR_DN_FROM/$imgOriginal"
  docker pull $imgFrom
  
  imgTo="$ECR_DN_TO/$imgOriginal"
  
  echo "tagging $imgFrom to $imgTo"
  docker tag $imgFrom $imgTo
  
  docker push $imgTo
}

# list all existing repos
allEcrReposFrom=$(aws --profile=ecrFrom --region $ECR_REGION_FROM ecr describe-repositories --query 'repositories[*].repositoryName' --no-paginate --output text)
allEcrReposTo=$(aws --profile=ecrTo --region $ECR_REGION_TO ecr describe-repositories --query 'repositories[*].repositoryName' --no-paginate --output text)
#allEcrReposFrom="dockerhub/redis"
#allEcrReposTo="dockerhub/redis"
echo "allEcrReposFrom:$allEcrReposFrom"
echo "allEcrReposTo:$allEcrReposTo"

loginEcr

for repo in $allEcrReposFrom
do
  createEcrRepo $repo
  # base on hash
  imageDetailsFrom=$(aws --profile ecrFrom --region $ECR_REGION_FROM ecr describe-images --repository-name $repo |jq -r ".imageDetails")
  imageDetailsTo=$(aws --profile ecrTo --region $ECR_REGION_TO ecr describe-images --repository-name $repo |jq -r ".imageDetails")
  hashesFrom=$(echo $imageDetailsFrom | jq .[].imageDigest -r)
  for curr_hash in $hashesFrom
  do
    tagsFrom=$(echo $imageDetailsFrom | jq -r ".[]| select(.imageDigest==\"${curr_hash}\")|.imageTags|.[]")
	tagsTo=$(echo $imageDetailsTo | jq -r ".[]| select(.imageDigest==\"${curr_hash}\")|.imageTags|.[]")
	for tag in $tagsFrom
	do
	  echo "Start sync ${repo}:${tag}"
	  if inArray "$tag" "$tagsTo";then
	    echo "[SKIP] ${repo}:${tag} already exists"
	  else
	    pullAndPush "${repo}:${tag}"
	  fi
	done
  done
done
