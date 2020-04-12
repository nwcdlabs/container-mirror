# 脚本说明

## mirror-images.sh
主要脚本，从Global同步到国内

## ECRImageList.sh
国内ECR现有image清单

## OfficialImageList.sh
获取[Docker Official Images](https://github.com/docker-library/official-images/tree/master/library)中的image，以便放到[required-images.txt](required-images.txt)。需要把https://github.com/docker-library/official-images/tree/master/library放到运行脚本的当前目录下。

## ECR2ECR.sh
从ECR到ECR复制

## ECR_Auth.sh
mirror-images.sh运行前，ECR授权