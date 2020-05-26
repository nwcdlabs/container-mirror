#!/bin/bash
# set -x

ECR_REGION='cn-northwest-1'
ECR_DN="048912060910.dkr.ecr.${ECR_REGION}.amazonaws.com.cn"
IMAGES_BLACKLIST='blacklist-images.txt'
IMAGES_IGNORE_LIST='ignore-images.txt'

declare -A DOMAIN_MAP
DOMAIN_MAP["quayio"]="quay"
DOMAIN_MAP["quay.io"]="quay"
DOMAIN_MAP["gcr.io"]="gcr"
DOMAIN_MAP["asia.gcr.io"]="gcr"
DOMAIN_MAP["us.gcr.io"]="gcr"
DOMAIN_MAP["k8s.gcr.io"]="gcr/google_containers"
DOMAIN_MAP["602401143452.dkr.ecr.us-west-2.amazonaws.com"]="amazonecr"
DOMAIN_MAP["docker.io"]="dockerhub"

function replaceDomainName(){
  math_mirror=False
  URI="$1"
  for key in ${!DOMAIN_MAP[*]};do
    if [[ $URI == ${key}* ]]; then
	  math_mirror=True
	  URI=${URI/#${key}/${DOMAIN_MAP[$key]}}
	  break
    fi
  done
  if [[ $math_mirror == False ]] ; then
    URI="dockerhub/${URI}"
  fi
}

function createEcrRepo() {
  if inArray "$2" "$blacklist"
  then
    echo "repo: $2 on the blacklist"
  else
    if inArray "$1" "$allEcrRepos"
    then
      echo "repo: $1 already exists"
    else
      echo "creating repo: $1"
      aws --profile=ChinaECR --region ${ECR_REGION} ecr create-repository --repository-name "$1"    
      attachPolicy "$1"
    fi
  fi
}

function attachPolicy() {
  echo "attaching public-read policy on ECR repo: $1"
  aws --profile ChinaECR --region $ECR_REGION ecr set-repository-policy --policy-text file://policy.text --repository-name "$1"
}

function deleteEcrRepo() {
  if inArray "$1" "$allEcrRepos"
  then
    echo "deleting repo: $1"
    aws --profile=ChinaECR --region ${ECR_REGION} ecr delete-repository --repository-name "$1" --force
  fi
}

function isRemoteImageExists(){
  # is_remote_image_exists repositoryName:Tag Digests
  fullrepo=${1#*/}
  repoName=${fullrepo%%:*}
  tag=${fullrepo##*:}
  res=$(aws --profile ChinaECR --region $ECR_REGION ecr describe-images --repository-name "$repoName" --query "imageDetails[?(@.imageDigest=='$2')].contains(@.imageTags, '$tag') | [0]")

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
  aws --profile=ChinaECR ecr --region cn-northwest-1 get-login --no-include-email | sh
  #aws --profile=ChinaECR ecr --region cn-north-1 get-login --no-include-email | sh
  aws ecr get-login --region us-west-2 --registry-ids 602401143452 894847497797 --no-include-email | sh
}

function pullAndPush(){
  origimg="$1"
  echo "------origimg:${origimg}------"
  repo=`echo ${origimg}|cut -d: -f1`
  if inArray "${repo}" "$blacklist"
  then
    echo "repo: $repo on the blacklist"
  else
    if inArray "${origimg}" "$ignoreImages"
	then
      echo "ignore images:${origimg}"
    else
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
    fi
  fi
}

# list all existing repos
allEcrRepos=$(aws --profile=ChinaECR --region $ECR_REGION ecr describe-repositories --query 'repositories[*].repositoryName' --output text)
echo "allEcrRepos:$allEcrRepos"

blacklist=$(grep -v ^# $IMAGES_BLACKLIST | cut -d: -f1 | sort -u)
for blackrepo in ${blacklist[@]}
do
  replaceDomainName $blackrepo
  deleteEcrRepo $URI
done

ignoreImages=$(grep -v ^# $IMAGES_IGNORE_LIST | sort -u)


# ecr login for the once
loginEcr

