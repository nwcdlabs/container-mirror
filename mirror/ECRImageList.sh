#!/bin/bash

ECR_REGION='cn-northwest-1'
ECR_DN="048912060910.dkr.ecr.${ECR_REGION_FROM}.amazonaws.com.cn"

# list all existing repos
allEcrRepos=$(aws --profile=China --region $ECR_REGION ecr describe-repositories --query 'repositories[*].repositoryName' --page-size 1000 --output text)
#allEcrRepos="dockerhub/redis dockerhub/kope/dns-controller"
#echo "allEcrRepos:$allEcrRepos"

function replaceDomainName(){
  URI="$1"
  URI=${URI/#quay/quay.io}
  URI=${URI/#gcr/gcr.io}
  URI=${URI/#dockerhub\//}
}

allEcrRepos=$(echo $allEcrRepos | tr " " "\n" | sort) 
for repo in $allEcrRepos
do
  tags=$(aws --profile China --region $ECR_REGION ecr describe-images --repository-name $repo |jq -r ".imageDetails[]|.imageTags[]")
  tags=$(echo $tags | tr " " "\n" | sort) 
  for tag in $tags
  do
    replaceDomainName "${repo}:${tag}"
	echo $URI
  done
done
