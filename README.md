![](https://codebuild.ap-northeast-1.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoicjlSNndlSGg4ZkJPQXF0Z1hIQnJIaFZES2VvN2tmUllKTjNEemJGeDVKZU5UUUt5eWdWT0Jrd0NZc2xweHROZFV1dEdXNmJLOVZmUGF1Tnl3ZmRSd1ZBPSIsIml2UGFyYW1ldGVyU3BlYyI6Ik5rNkxrdTZnR21GLzl4YzkiLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=master)


## 项目介绍
本项目用于将[Docker Hub](https://hub.docker.com/)，[Google Container Registry](https://console.cloud.google.com/gcr/images/google-containers/GLOBAL?pli=1)和[Quay](https://quay.io/search)中常用的公共container image自动同步至AWS中国区的ECR内，使AWS用户能更方便快捷的获取这些常见的容器镜像。

## Amazon ECR镜像路径
所有同步至ECR的镜像都放在048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn这一container registry内，ECR镜像路径规则如下
* **Docker Hub** (*目前只支持[docker official images](https://github.com/docker-library/official-images)*)
    * 原始镜像路径: [library/]repo:tag
    * ECR镜像路径: 048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn/dockerhub/[library/]repo:tag
* **GCR**
    * 原始镜像路径: gcr.io/namespace/repo:tag
    * ECR镜像路径: 048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn/gcr/namespace/repo:tag
    * 原始镜像路径: k8s.gcr.io/repo:tag
    * ECR镜像路径: 048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn/gcr/google_containers/repo:tag
* **Quay**
    * 原始镜像路径: quay.io/namespace/repo:tag
    * ECR镜像路径: 048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn/quay/namespace/repo:tag 

海外镜像复制到ECR后的路径转换示例如下：

| 海外镜像         | ECR镜像  |
|------------    |---------|
| ubuntu:1.17.9  | 048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn/dockerhub/ubuntu:1.17.9 |
| gcr.io/heptio-images/velero:v1.1.0 | 048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn/gcr/heptio-images/velero:v1.1.0 |
| k8s.gcr.io/cluster-autoscaler:v1.2.2 | 048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn/gcr/google_containers/cluster-autoscaler:v1.2.2 |
| quay.io/calico/node:v3.7.4 | 048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn/quay/calico/node:v3.7.4 |

## 使用方法
1. 如果您是开发测试或新建项目，可以直接修改引用到原始容器镜像的地方，如修改k8s deployment yaml文件中的image指向ECR中相应image的路径。
2. 如果您使用了自动部署工具且不方便修改image路径，或者想自动替换所有Pod中image到相应ECR路径，可以使用Kubernetes的[Mutating admission webhook](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#mutatingadmissionwebhook)，本项目中提供了该webhook的参考实现，[点击查看](webhook/README.md)。
3. 如果项目中用到了Helm Charts，并且chart template支持自定义Pod image，可以设置chart参数指向ECR中相应image的路径。
4. 如果您的项目直接使用kubectl部署，且kubectl版本在v1.14或以上，可以使用[kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)将原始image路径指向ECR中相应image的路径。

## 增加新的容器镜像
已有镜像列表放在[required-images-mirrored.txt](./mirror/required-images-mirrored.txt)。 
如果您在集群创建过程中需要其他镜像, 请您编辑 [required-images.txt](./mirror/required-images.txt) ，这将会在您的GitHub账户中 fork 一个新的分支，之后您可以提交PR（pull request）。 Merge您的PR会触发`CodeBuild` 去拉取 `required-images.txt` 中定义的镜像回ECR库。 几分钟后，您可以看到图标从`in progress`变为`passing`
![](https://codebuild.ap-northeast-1.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoicjlSNndlSGg4ZkJPQXF0Z1hIQnJIaFZES2VvN2tmUllKTjNEemJGeDVKZU5UUUt5eWdWT0Jrd0NZc2xweHROZFV1dEdXNmJLOVZmUGF1Tnl3ZmRSd1ZBPSIsIml2UGFyYW1ldGVyU3BlYyI6Ik5rNkxrdTZnR21GLzl4YzkiLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=master)

## 自动同步新镜像
在[required-images-daily.txt](./mirror/required-images-daily.txt)中的镜像，会自动同步高于指定tag的新镜像，tag中包含latest、alpha、beta的不同步。目前仅支持Docker Hub。  
比如指定kopeio/etcd-manager:3.0.20190930，会自动同步  
kopeio/etcd-manager:3.0.20200116  
kopeio/etcd-manager:3.0.20200307  