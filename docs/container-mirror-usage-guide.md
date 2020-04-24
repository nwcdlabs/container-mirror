# 容器镜像库使用指南

本文档用于分场景指导AWS用户如何使用[container-mirror](https://github.com/nwcdlabs/container-mirror)方便快捷的部署常见的容器镜像。

场景分类：
1. ECS/Fargate
2. K8S on EC2 / EKS
    1. K8S on EC2 处理 ECR login
    2. 使用Mutating admission webhook，
    3. 使用Helm Charts
    4. 直接使用k8s deployment yaml文件
    5. [使用kustomize](../kustomize/README.md)
3. [如何增加新的容器镜像](how-to-request-new-container-image.md)

