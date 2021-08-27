#!/bin/bash
source mirror-base.sh

IMAGES_DAILY_FILE_LIST="required-images-daily.txt"
images=$(grep -v ^# $IMAGES_DAILY_FILE_LIST)
#images="golang"

count=0
for image in ${images[@]}
do
  count=$[$count + 1]
done
echo "count:${count}"
mytime=$(date "+%H")
split_index=$[$mytime / 3]
echo "split_index:${split_index}"
split_size=$[$[$count / 8] + 1]
echo "split_size:${split_size}"
begin=$[split_index * split_size]
end=$[$[split_index + 1] * split_size ]
echo "begin:${begin}"
echo "end:${end}"
current_index=0
for image in ${images[@]}
do
  if [ $current_index -lt $begin ]
  then
    current_index=$[$current_index + 1]
    continue
  fi
  
  if [ $current_index == $end ]
  then
    break
  fi
  
  current_index=$[$current_index + 1]
  
  repo=`echo ${image}|cut -d: -f1`
  echo "************begin pull ${repo} all tag************"
  date
  if inArray "${repo}" "$blacklist"
  then
    echo "repo: $repo on the blacklist"
  else
    replaceDomainName $repo
    createEcrRepo $URI $repo

    #把现有tag和digest放入到map
    declare -A ECR_MAP=()
    ecrTagsData=$(aws --profile ChinaECR --region $ECR_REGION ecr list-images --repository-name $URI)
    ecrTags=$(echo $ecrTagsData|jq ".imageIds[].imageTag" -r)
    ecrDigest=$(echo $ecrTagsData|jq ".imageIds[].imageDigest" -r)
    arrDigest=($ecrDigest)
    index=0
    for existTag in $ecrTags ;do
      ECR_MAP_Key=$existTag
      ECR_MAP_Value=${arrDigest[$index]}
      #echo "${ECR_MAP_Key}_${ECR_MAP_Value}"
      ECR_MAP[${ECR_MAP_Key}]=${ECR_MAP_Value}
      index=`expr $index + 1`
    done    
    
    if [[ ${repo} =~ / ]];then
        request_repo=$repo
    else
        request_repo="library/${repo}"
    fi
    url="https://hub.docker.com/v2/repositories/${request_repo}/tags"
    while true
    do
        echo "请求url:${url}"
        allTagsData=`wget -q $url -O -`
        allTags=$(echo $allTagsData | jq ".results[]" -c)
        #由于某些tag没有linux amd64版本，可能存在过滤后下标不对应问题，因此这里不能使用下标定位
        #schema1 manifest format的没有digest值
        for allTag in $allTags ;do
            tag=$(echo $allTag | jq -r ".name")
            if [[ ${tag} =~ beta || ${tag} =~ alpha || ${tag} =~ windowsservercore || ${tag} =~ nanoserver ]];then
                #echo "skip ${tag}==============="
                continue
            fi
            digest=$(echo $allTag | jq -r '.images[]|select(.architecture=="amd64")|select(.os=="linux")|.digest')
            #schema1 manifest format的没有digest值，如果ECR有值就不再处理
            if [[ "$digest" == "" && "${ECR_MAP[$tag]}" != "" ]] ; then
                #echo "skip ${tag}==============="
                continue
            elif [[ "$digest" != "" && "$digest" == "${ECR_MAP[$tag]}" ]] ; then
                #echo "skip ${tag}==============="
                continue
            elif [[ "$digest" != "" && "${ECR_MAP[$tag]}" != "" && "$digest" != "${ECR_MAP[$tag]}" ]] ; then
                #这种情况可能是tag内容变化
                #也有可能是有些tag的digest在docker hub和ECR上不一致
                #比如golang:1.10.6-alpine3.7
                #更新时间超过10天，且digest不一致的，不更新
                last_updated=$(echo $allTag | jq -r ".last_updated")
                last_date=$(date -d "$last_updated" +%s)
                current_date=$(date  +%s)
                interval=$(expr $current_date - $last_date)
                if [ ${interval} -gt 864000 ] ; then
                    #echo "skip ${tag}===============${last_updated}"
                    continue
                else
                    echo "${repo}:${tag}存在，需更新,last_updated:${last_updated},interval:${interval}"
                fi
            fi
            pullAndPush ${repo}:${tag}
        done
        url=$(echo $allTagsData | jq -r ".next")
        if [ "${url}" == "null" ]; then
            break
        fi
    done
  fi
done
date
