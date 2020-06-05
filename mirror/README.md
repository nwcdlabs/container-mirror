# 脚本说明
## mirror-base.sh
主要脚本，从Global同步到国内

## mirror-images.sh
需要同步的数据从required-images.txt获取，调用mirror-base.sh。

## mirror-images-daily.sh
需要配置trigger触发，从Global同步到国内，需要同步的数据从required-images-daily.txt获取。  

## ECRImageList.sh
获取国内ECR现有image清单，需要修改第3、4行为自己的ECR地址。

## ECR_Auth.sh
mirror-images.sh运行前，ECR授权