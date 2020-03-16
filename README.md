![](https://codebuild.ap-northeast-1.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoiU0k4WjlocEs4SXRqWmoxQTd4MzJIUUE1Nk1KU01UODBFTWRjdkRWclB4VDdoTWdjb0M0R2czaVoxWkRRQ041bkFlNlRoR1ArdVV3MHF0eGdyN3lPc3ZzPSIsIml2UGFyYW1ldGVyU3BlYyI6IkdZcnFHOFk5aE9UUmZydkciLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=master)

## 免责说明
建议测试过程中使用此方案，生产环境使用请自行考虑评估。  
当您对方案需要进一步的沟通和反馈后，可以联系 nwcd_labs@nwcdcloud.cn 获得更进一步的支持。  
欢迎联系参与方案共建和提交方案需求, 也欢迎在 github 项目issue中留言反馈bugs。    


# 项目介绍
由于防火墙或安全限制，海外gcr.io, quay.io的镜像可能无法下载，本项目将K8S集群搭建过程中需要拉取的镜像拉回国内，优化使用体验。
为了不手动修改原始yaml文件的镜像路径，采用下面webhook的方式，自动修改国内配置的镜像路径。

# 特性
- [x] 集群创建过程中所需的docker镜像已存放在 **宁夏** 区域的`Amazon ECR`中。
- [x] 无需任何VPN代理或翻墙设置
- [x] 如有新的Docker镜像拉取需求，您可以创建Github push or pull request,您的request会触发**CodeBuild**([buildspec.yml](./buildspec.yml))  去拉取镜像并存放到AWS `cn-northwest-1` 的ECR中。查看： [镜像列表](./mirror/required-images.txt).

# 使用方法
## 直接使用镜像
EKS用户可直接使用，镜像域名为048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn。  
k8s.gcr.io/coredns:1.3.1对应地址为048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn/coredns:1.3.1。  
gcr.io/google_containers/kube-apiserver:v1.12.8对应地址为048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn/google_containers/kube-apiserver:v1.12.8
## 使用WebHook引用镜像
使用WebHook后，拉取k8s.gcr.io、gcr.io、quay.io镜像时，会自动替换为国内的ECR URI。详细介绍参见 https://github.com/aws-samples/amazon-api-gateway-mutating-webhook-for-k8。  
EKS用户使用以下命令即可直接使用WebHook。
```bash
kubectl apply -f https://raw.githubusercontent.com/nowfox/container-mirror/master/webhook/mutating-webhook.yaml
```
然后验证，即可像使用普通地址一样使用。
```bash
kubectl run test --image=k8s.gcr.io/coredns:1.3.1
kubectl get pods
kubectl get pod test-xxxx -o=jsonpath='{.spec.containers[0].image}'
# 结果应显示为048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn/coredns:1.3.1
# 清理
kubectl delete deployment test
```

# 自建WebHook API Gateway
由于安全或访问限制等原因，需要自己部署WebHook API Gateway的，按以下步骤进行操作。
1. 修改 [webhook/api-gateway.yaml](./webhook/api-gateway.yaml) 中 image_mirrors 下面的镜像地址您偏好的国内镜像地址，如果使用NWCD labs镜像地址，则不用修改。
```bash
git clone https://github.com/nowfox/container-mirror.git
cd webhook
vi api-gateway.yaml
# 
image_mirrors = {
            'k8s.gcr.io/': '<镜像地址>/',
            'gcr.io/': '<镜像地址>/',
            'quay.io/': '<镜像地址>/'
}
```

2. 在AWS console 部署 CloudFormation template api-gateway.yaml
3. 修改 [webhook/mutating-webhook.yaml](./webhook/mutating-webhook.yaml) 中 webhooks.clientConfig.url 为CloudFormation的输出值。
4. 创建Kubernetes资源
```bash
kubectl apply -f mutating-webhook.yaml
```
5. 验证
然后验证，即可像使用普通地址一样使用。
```bash
kubectl run test --image=k8s.gcr.io/coredns:1.3.1
kubectl get pods
kubectl get pod test-xxxx -o=jsonpath='{.spec.containers[0].image}'
# 结果应显示为 您偏好的国内镜像地址/coredns:1.3.1
# 清理
kubectl delete deployment test
```

# FAQ
## 我需要的docker镜像在ECR中不存在
已有镜像见[required-images-mirrored.txt](./mirror/required-images-mirrored.txt)。  
如您在集群创建过程中需要其他镜像, 请您编辑 [required-images.txt](./mirror/required-images.txt) ，这将会在您的GitHub账户中 fork 一个新的分支，之后您可以提交PR（pull request）。 Merge您的PR会触发`CodeBuild` 去拉取 `required-images.txt` 中定义的镜像回ECR库。 数分钟后，您可以看到图标从`in progress`变为`passing`

当前状态：![](https://codebuild.ap-northeast-1.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoiU0k4WjlocEs4SXRqWmoxQTd4MzJIUUE1Nk1KU01UODBFTWRjdkRWclB4VDdoTWdjb0M0R2czaVoxWkRRQ041bkFlNlRoR1ArdVV3MHF0eGdyN3lPc3ZzPSIsIml2UGFyYW1ldGVyU3BlYyI6IkdZcnFHOFk5aE9UUmZydkciLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=master)