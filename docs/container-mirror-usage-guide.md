# 容器镜像库使用指南

本文档用于分场景指导AWS用户如何使用[container-mirror](https://github.com/nwcdlabs/container-mirror)方便快捷的部署常见的容器镜像。

场景分类：
1. Docker 和 docker-compose, 直接修改文件中的 image 指向本项目 ECR 中相应镜像的路径。[点击查看示例](docker-docker-compose-usage-guide.md)

2. ECS/Fargate
    修改 ECS/Fargate 的 task defition yaml 文件 或者 docker-compose.yml 中 image 参数，指向 ECR 中相应 image 的路径 [点击查看如何使用在 ECS/Fargate 使用本项目的 ECR 镜像地址](ecs-fargate-useage-guide.md)。

3. Kubernetes on EC2 / EKS
    1. 使用 Mutating webhook 自动替换所有 Kubernetes Pod 中 image 路径

        如果您使用了自动部署工具且不方便修改 image 路径，或者想自动替换所有 Kubernetes Pod 中 image 到相应 ECR 路径，可以使用 Kubernetes 的[Mutating admission webhook](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#mutatingadmissionwebhook)，[点击查看如何使用 Mutating webhook](webhook/README.md)。

    2. 使用Helm Charts
        
        利用 Helm Charts 部署应用，并且chart template支持自定义Pod image，可以设置 chart 参数，指向本项目 ECR 中相应镜像的路径，[点击查看如何使用示例](helm-chart-useage-guide.md)。

    3. 直接修改 kubernetes deployment yaml 文件
    
        如果您的项目可以直接修改引用到原始容器镜像的地方，如修改 kubernetes deployment yaml 文件中的 image 指向本项目 ECR 中相应镜像的路径
        ```yaml
        apiVersion: v1
        kind: Pod
        metadata:
          name: bosybox-ecr-demo
        spec:
          containers:
            - name: bosybox
              image: 048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn/dockerhub/busybox:1.31.1
              command: ["/bin/sh"]
              args:
                [
                  '-c',
                  'i=0; while true; do echo "$i: $(date -u)"; i=$((i+1)); sleep 1; done'
                ]
        ```
        ```bash
        kubectl apply -f busybox-demo.yaml
        kubectl get pod bosybox-ecr-demo -o=jsonpath='{.spec.containers[0].image}'
        kubectl logs --tail=30 bosybox-ecr-demo
        ```
    
    4. [使用kustomize](../kustomize/README.md)
    
        如果您的 kubernetes 集群直接使用 kubectl 部署，且 kubectl 版本在v1.14或以上，可以使用 [kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/) 将原始 image 路径指向 本项目 ECR 响应镜像的路径，[点击查看使用kustomize示例](../kustomize/README.md)。

4. [如何增加新的容器镜像](how-to-request-new-container-image.md)


