#!/bin/bash
# set -x

ECR_REGION='cn-northwest-1'
ECR_DN="048912060910.dkr.ecr.${ECR_REGION}.amazonaws.com.cn"
IMAGES_FILE_LIST='required-images.txt'
IMAGES_DAILY_FILE_LIST='required-images-daily.txt'

function replaceDomainName(){
  URI="$1"
  if [[ $URI == quay.io* ]]
  then
    URI=${URI/#quay.io/quay}
  elif [[ $URI == gcr.io* ]]
  then
    URI=${URI/#gcr.io/gcr}
  elif [[ $URI == k8s.gcr.io* ]]
  then
    URI=${URI/#k8s.gcr.io/gcr\/google_containers}
  else
    URI="dockerhub/${URI}"
  fi
}

function createEcrRepo() {
  if inArray "$1" "$allEcrRepos"
  then
    echo "repo: $1 already exists"
  else
    echo "creating repo: $1"
    aws --profile=China --region ${ECR_REGION} ecr create-repository --repository-name "$1"    
    attachPolicy "$1"
  fi
}

function attachPolicy() {
  echo "attaching public-read policy on ECR repo: $1"
  aws --profile China --region $ECR_REGION ecr set-repository-policy --policy-text file://policy.text --repository-name "$1"
}

function isRemoteImageExists(){
  # is_remote_image_exists repositoryName:Tag Digests
  fullrepo=${1#*/}
  repoName=${fullrepo%%:*}
  tag=${fullrepo##*:}
  res=$(aws --profile China --region $ECR_REGION ecr describe-images --repository-name "$repoName" --query "imageDetails[?(@.imageDigest=='$2')].contains(@.imageTags, '$tag') | [0]")

  if [ "$res" == "true" ]; then 
    return 0 
  else
    return 1
  fi
}

function getLocalImageDigests(){
  x=$(docker image inspect --format='{{index .RepoDigests 0}}' "$1")
  echo ${x##*@}
  # docker images --digests --no-trunc -q "$1"
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
  aws --profile=China ecr --region cn-northwest-1 get-login --no-include-email | sh
  #aws --profile=China ecr --region cn-north-1 get-login --no-include-email | sh
  aws ecr get-login --region us-west-2 --registry-ids 602401143452 894847497797 --no-include-email | sh
}

function pullAndPush(){
  origimg="$1"
  echo "origimg:${origimg}"
  docker pull $origimg
  
  replaceDomainName $origimg
  targetImg="$ECR_DN/${URI}"
  
  echo "tagging $origimg to $targetImg"
  docker tag $origimg $targetImg
  
  echo "getting the digests on $targetImg..."
  digests=$(getLocalImageDigests $targetImg)
  echo "digests:$digests"
  echo "checking if remote image exists"

  if isRemoteImageExists $targetImg $digests;then 
    echo "[SKIP] image already exists, skip"
  else
    echo "[PUSH] remote image not exists or digests not match, pushing $targetImg"
    docker push $targetImg
  fi
}

# list all existing repos
allEcrRepos=$(aws --profile=China --region $ECR_REGION ecr describe-repositories --query 'repositories[*].repositoryName' --output text)
echo "allEcrRepos:$allEcrRepos"
repos=$(grep -v ^# $IMAGES_FILE_LIST | cut -d: -f1 | sort -u)
for repo in ${repos[@]}
do
  replaceDomainName $repo
  createEcrRepo $URI
done

# ecr login for the once
loginEcr

images=$(grep -v ^# $IMAGES_FILE_LIST)
for image in ${images[@]}
do
  pullAndPush $image
done

# daily
function version_ge() {
  test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1";
}

images=$(grep -v ^# $IMAGES_DAILY_FILE_LIST)
for image in ${images[@]}
do
  repo=`echo ${image}|cut -d: -f1`
  baseTag=`echo ${image}|cut -d: -f2`
  replaceDomainName $repo
  createEcrRepo $URI
  tags=`wget -q https://registry.hub.docker.com/v1/repositories/${repo}/tags -O -  | sed -e 's/[][]//g' -e 's/"//g' -e 's/ //g' | tr '}' '\n'  | awk -F: '{print $3}' | grep -v latest | grep -v alpha | grep -v beta`
  for tag in ${tags}
  do
    if version_ge ${tag} $baseTag
    then
      pullAndPush "${repo}:${tag}"
    fi
  done
done