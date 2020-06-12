# 如何使用Kubernetes mutating admission webhook自动更换Kubernetes Pod的容器镜像

本项目基于[通过 Amazon API Gateway 实现 Kubernetes mutation admission webhook](https://github.com/aws-samples/amazon-api-gateway-mutating-webhook-for-k8) 的原理，根据预先定义的映射规则自动修改 Kubernetes Pod 内的镜像路径到本项目对应的 ECR 镜像仓库。

## 如何部署使用 webhook
### 前提条件
- 如果您在使用Amazon EKS，可跳过检查步骤直接到部署环节。
- 如果您是自己搭建的Kubernetes，请确保
    - 您的Kubernetes集群版本为1.9或以上.
    - Kubernetes的MutatingAdmissionWebhook admission controllers 功能已打开
    - admissionregistration.k8s.io/v1beta1 API 启用.

### 部署 webhook
### 方法1：Kubernetes mutating admission webhook 直接使用本项目托管 Amazon API Gateway
1. 本项目已经部署了一个托管 Amazon API Gateway，使用以下命令即可直接部署 WebHook，并指向托管 Amazon API Gateway。
```bash
kubectl apply -f webhook/mutating-webhook.yaml
#kubectl apply -f https://raw.githubusercontent.com/nwcdlabs/container-mirror/master/webhook/mutating-webhook.yaml
```

2. 验证 pod 详细信息中的image 已经替换为本项目对应的 ECR 镜像仓库。
```bash
kubectl run --generator=run-pod/v1 test --image=k8s.gcr.io/coredns:1.3.1
kubectl get pod test -o=jsonpath='{.spec.containers[0].image}'
# 结果应显示为048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn/gcr/google_containers/coredns:1.3.1

# 清理
kubectl delete pod test
```

### 方法2：自己部署Amazon API Gateway
如果您期望部署自己的 Amazon API Gateway 用于 webhook, 按照下列步骤：
1. 使用CloudFormation模板文件 webhook/api-gateway.yaml 在 AWS CloudFormation Console 上部署 Amazon API Gateway 以及相关资源，CloudFormation Stack 使用默认参数即可。
2. 创建 Kubernetes Mutating Webhook Configuration资源
    - 在第一步创建的CloudFormation stack完成后，在输出结果中找到 APIGateWayURL。
    - 修改 webhook/mutating-webhook.yaml，将 webhooks.clientConfig.url 的值替换为上面找到的APIGateWayURL值。
    - 创建 Kubernetes resource:
        ```bash
        cd webhook/
        kubectl apply -f mutating-webhook.yaml
        ```

### 其他方法，例如 sam 部署方式
详情参考 [amazon-api-gateway-mutating-webhook-for-k8](https://github.com/aws-samples/amazon-api-gateway-mutating-webhook-for-k8)

## 使用 WebHook之后，期望部分 Image 依旧强制回源，引用绝对地址
  使用WebHook后，会把相关地址都转化为ECR仓库地址，如果期望部分 Image 依旧强制回源，或者由于 ECR 仓库没有同步所有的image，期望回源地址下载。可以在 image 路径使用特殊标识(**direct.to/**)。  
比如
```yaml
image: direct.to/busybox:latest
```
返回 busybox:latest

```yaml
image: direct.to/gcr.io/google_containers/pause-amd64:3.0
```
返回 gcr.io/google_containers/pause-amd64:3.0