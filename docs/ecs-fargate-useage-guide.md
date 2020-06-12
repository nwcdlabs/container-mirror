# ECS and ECS Fargate usage guide

这里将展示如何利用本项目的 ECR 镜像地址部署 [ecsworkshop](https://ecsworkshop.com/introduction/) 演示用例, 这里以宁夏区 cn-northwest-1 ECS Fargate 为例

# 安装ecs-cli，jq

依照 [ecscli 安装指南](https://ecsworkshop.com/prerequisites/software/#install-software-1) 安装 ecscli

```bash
sudo curl -so /usr/local/bin/ecs-cli https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-linux-amd64-latest
sudo chmod +x /usr/local/bin/ecs-cli
sudo yum -y install jq gettext

# Setting environment variables required to communicate with AWS API's via the cli tools
export AWS_REGION=cn-northwest-1
aws configure set default.region ${AWS_REGION}
aws configure get default.region
```

# 部署示例应用
## 部署 ECS fargate 集群
```bash
cd ~/workspace/
git clone https://github.com/brentley/container-demo
aws cloudformation deploy --stack-name container-demo --template-file cluster-fargate-private-vpc.yml --capabilities CAPABILITY_IAM --region ${AWS_REGION}
aws cloudformation deploy --stack-name container-demo-alb --template-file script/alb-external.yml --region ${AWS_REGION}
```

## 部署前端服务 ecsdemo-frontend
1. git clone 前端服务
```bash
cd ~/workspace/
git clone https://github.com/brentley/ecsdemo-frontend
```
2. **修改镜像地址 ecsdemo-frontend/docker-compose.yml**
```yaml
version: '3'
services:
  ecsdemo-frontend:
    environment:
      - CRYSTAL_URL=http://ecsdemo-crystal.service:3000/crystal
      - NODEJS_URL=http://ecsdemo-nodejs.service:3000
    image: 048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn/dockerhub/brentley/ecsdemo-frontend
    ports:
      - "3000:3000"
    logging:
      driver: awslogs
      options:
        awslogs-group: ecsdemo-frontend
        awslogs-region: ${AWS_REGION}
        awslogs-stream-prefix: ecsdemo-frontend
```

3. 部署 ecsdemo-frontend 前端服务
```bash
# Deploy service and task
ecs-cli compose --region $AWS_REGION --project-name ecsdemo-frontend service up \
    --create-log-groups \
    --target-group-arn $target_group_arn \
    --private-dns-namespace service \
    --container-name ecsdemo-frontend \
    --container-port 3000 \
    --cluster-config container-demo \
    --vpc $vpc
INFO[0000] Using ECS task definition                     TaskDefinition="ecsdemo-frontend:3"
...
INFO[0045] ECS Service has reached a stable state        desiredCount=1 runningCount=1 serviceName=ecsdemo-frontend

# View running container
ecs-cli compose --project-name ecsdemo-frontend service ps \
    --cluster-config container-demo --region $AWS_REGION
Name                                                   State    Ports                       TaskDefinition      Health
7cb08af6-05cc-4c49-a5d2-0e5500301090/ecsdemo-frontend  RUNNING  10.0.102.93:3000->3000/tcp  ecsdemo-frontend:3  UNKNOWN

# View task image url
aws ecs describe-task-definition --task-definition ecsdemo-frontend:3 --query "taskDefinition.containerDefinitions[*].image" --region $AWS_REGION
[
    "048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn/dockerhub/brentley/ecsdemo-frontend"
]

# Check reachability
alb_url=$(aws cloudformation describe-stacks --stack-name container-demo-alb --query 'Stacks[0].Outputs[?OutputKey==`ExternalUrl`].OutputValue' --output text --region $AWS_REGION)
echo "Open $alb_url in your browser"

# Scale the tasks
ecs-cli compose --project-name ecsdemo-frontend service scale 3 \
    --cluster-config container-demo --region $AWS_REGION
INFO[0000] Updated ECS service successfully              desiredCount=3 force-deployment=false service=ecsdemo-frontend
...
INFO[0075] ECS Service has reached a stable state        desiredCount=3 runningCount=3 serviceName=ecsdemo-frontend

ecs-cli compose --project-name ecsdemo-frontend service ps \
    --cluster-config container-demo --region $AWS_REGION
Name                                                   State    Ports                        TaskDefinition      Health
1be97885-d9fa-41f2-9a2c-1f7b7e170aa7/ecsdemo-frontend  RUNNING  10.0.100.48:3000->3000/tcp   ecsdemo-frontend:3  UNKNOWN
25dfe72d-77e9-4971-8051-63b64913c7f6/ecsdemo-frontend  RUNNING  10.0.101.174:3000->3000/tcp  ecsdemo-frontend:3  UNKNOWN
7cb08af6-05cc-4c49-a5d2-0e5500301090/ecsdemo-frontend  RUNNING  10.0.102.93:3000->3000/tcp   ecsdemo-frontend:3  UNKNOWN
```

## 部署后端服务 ecsdemo-nodejs
```bash
git clone https://github.com/brentley/ecsdemo-nodejs
```
```yaml
version: '3'
services:
  ecsdemo-nodejs:
    image: 048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn/dockerhub/brentley/ecsdemo-nodejs
    ports:
      - "3000:3000"
    logging:
      driver: awslogs
      options: 
        awslogs-group: ecsdemo-nodejs
        awslogs-region: ${AWS_REGION}
        awslogs-stream-prefix: ecsdemo-nodejs
```

## 部署后端服务 ecsdemo-crystal
```
git clone https://github.com/brentley/ecsdemo-crystal
```

```yaml
version: '3'
services:
  ecsdemo-crystal:
    image: 048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn/dockerhub/brentley/ecsdemo-crystal
    ports:
      - "3000:3000"
    logging:
      driver: awslogs
      options: 
        awslogs-group: ecsdemo-crystal
        awslogs-region: ${AWS_REGION}
        awslogs-stream-prefix: ecsdemo-crystal
```

## 最终前端效果
```bash
alb_url=$(aws cloudformation describe-stacks --stack-name container-demo-alb --query 'Stacks[0].Outputs[?OutputKey==`ExternalUrl`].OutputValue' --output text --region $AWS_REGION)
echo "Open $alb_url in your browser"
```