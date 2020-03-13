#!/bin/bash
# set -x

ECR_REGION='cn-northwest-1'
ECR_DN="048912060910.dkr.ecr.${ECR_REGION}.amazonaws.com.cn"
IMAGES_FILE_LIST='required-images.txt'

function trimDomainName(){
  URI="$1"
  URI=${URI/k8s.gcr.io\//}
  URI=${URI/gcr.io\//}
  URI=${URI/602401143452.dkr.ecr.us-west-2.amazonaws.com\//}
  URI=${URI/quay.io\//}
}

function trimDomainNameKops(){
  trimDomainName $1
  URI="${URI//\//-}"
}

function needKops(){
  if [[ $1 =~ \/ ]]
  then
    return 0
  else
    return 1
  fi
}

function createEcrRepo() {
  if inArray "$1" "$allEcrRepos"
  then
    echo "repo: $1 already exists"
  else
    echo "creating repo: $1"
    aws --profile=china --region ${ECR_REGION} ecr create-repository --repository-name "$1"    
    attachPolicy "$1"
  fi
}

function attachPolicy() {
  echo "attaching public-read policy on ECR repo: $1"
  aws --profile china --region $ECR_REGION ecr set-repository-policy --policy-text file://policy.text --repository-name "$1"
}

function isRemoteImageExists(){
  # is_remote_image_exists repositoryName:Tag Digests
  fullrepo=${1#*/}
  repoName=${fullrepo%%:*}
  tag=${fullrepo##*:}
  res=$(aws --profile china --region $ECR_REGION ecr describe-images --repository-name "$repoName" --query "imageDetails[?(@.imageDigest=='$2')].contains(@.imageTags, '$tag') | [0]")

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
  aws --profile=china ecr --region cn-northwest-1 get-login --no-include-email | sh
  #aws --profile=china ecr --region cn-north-1 get-login --no-include-email | sh
  aws ecr get-login --region us-west-2 --registry-ids 602401143452 894847497797 --no-include-email | sh
}

function pullAndPush(){
  origimg="$1"
  echo "origimg:${origimg}"
  docker pull $origimg
  
  trimDomainName $origimg
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

  #先简单处理，两次push，后续再修改
  if needKops ${URI};then
    trimDomainNameKops $origimg
    targetImgKops="$ECR_DN/${URI}"
    echo "tagging $origimg to $targetImgKops"
    docker tag $origimg $targetImgKops
		
    echo "getting the digests on $targetImgKops..."
    digestsKops=$(getLocalImageDigests $targetImgKops)
    echo "digestsKops:$digestsKops"
    echo "checking if remote image exists"

    if isRemoteImageExists $targetImgKops $digestsKops;then 
      echo "[SKIP] image already exists, skip"
    else
      echo "[PUSH] remote image not exists or digests not match, pushing $targetImgKops"
      docker push $targetImgKops
    fi
  fi
}

# list all existing repos
allEcrRepos=$(aws --profile=china --region $ECR_REGION ecr describe-repositories --query 'repositories[*].repositoryName' --output text)
echo "allEcrRepos:$allEcrRepos"
repos=$(grep -v ^# $IMAGES_FILE_LIST | cut -d: -f1 | sort -u)
for repo in ${repos[@]}
do
  # 为同步支持kops，/替换为-和不替换都存放一份
  trimDomainName $repo
  createEcrRepo $URI
  if needKops ${URI};then
    trimDomainNameKops $repo
    createEcrRepo $URI
  fi
done

# ecr login for the once
loginEcr
images=$(grep -v ^# $IMAGES_FILE_LIST)
# echo ${images//\//-}
for image in ${images[@]}
do
  pullAndPush $image
done
