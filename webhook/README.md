# 如何使用K8s mutating admission webhook自动更换K8s Pod的容器镜像

本项目基于[通过Amazon API Gateway实现k8s mutation admission webhook](https://github.com/aws-samples/amazon-api-gateway-mutating-webhook-for-k8)的原理，根据预先定义的映射规则自动修改k8s Pod内的镜像路径到对应的ECR镜像仓库。

## 如何部署使用
### 前提条件
- 如果您在使用Amazon EKS，可跳过检查步骤直接到部署环节。
- 如果您是自己搭建的k8s，请确保
    - 您的k8s集群版本为1.9或以上.
    - k8s的MutatingAdmissionWebhook admission controllers 功能已打开
    - admissionregistration.k8s.io/v1beta1 API 启用.


### 使用托管Amazon API Gateway
使用以下命令即可直接使用WebHook。
```bash
kubectl apply -f mutating-webhook.yaml
```
然后验证，即可像使用普通地址一样使用。
```bash
kubectl run --generator=run-pod/v1 test --image=k8s.gcr.io/coredns:1.3.1
kubectl get pod test -o=jsonpath='{.spec.containers[0].image}'
# 结果应显示为048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn/gcr/google_containers/coredns:1.3.1
# 清理
kubectl delete pod test
```

### 自己部署Amazon API Gateway
1. 部署新的webhook, 使用CloudFormation模板文件 api-gateway.yaml在AWS CloudFormation界面上部署，使用默认参数即可。
2. 创建 k8s MutatingWebhookConfiguration资源
    - 在第一步创建的CloudFormation stack完成后，在输出结果中找到 APIGateWayURL。
    - 修改 mutating-webhook.yaml，将 webhooks.clientConfig.url 的值替换为上面找到的APIGateWayURL值。
    - 创建 K8S resource:
        ```bash
        $ kubectl apply -f mutating-webhook.yaml
        ```

### 引用绝对地址，回源
  使用WebHook后，会把相关地址都转化为ECR仓库地址，但是ECR仓库没有同步所有的image。为了方便使用或回源，使用特殊标识(**direct.to/**)开始的image，会去掉该特殊标识。  
比如**direct.to/busybox:latest**返回**busybox:latest**，**direct.to/gcr.io/google_containers/pause-amd64:3.0**返回**gcr.io/google_containers/pause-amd64:3.0**。