# 使用kubectl kustomize更换image路径

首先确认kubectl版本在v1.14或以上。本文以替换nginx image路径为例来介绍。

## 步骤1.正常编写deployment.yaml文件
首先正常编写deployment.yaml文件。
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  selector:
    matchLabels:
      run: my-nginx
  replicas: 2
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
        ports:
        - containerPort: 80
```

## 步骤2.编写kustomization.yaml文件
在resources里指定要处理的yaml文件；对要替换的image，需要逐个编写，指定实际需要指向的路径。
```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- deployment.yaml
images:
- name: nginx
  newName: 048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn/dockerhub/nginx
  newTag: "1.17"
```

## 步骤3.查看image已更新(可选)
运行kubectl kustomize ./ 以确认image已更新，正常情况下，可看到**image**已替换为新的路径
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      run: my-nginx
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - image: 048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn/dockerhub/nginx:1.17
        name: my-nginx
        ports:
        - containerPort: 80
```

## 步骤4.实际部署
运行kubectl apply -k ./ 部署。

## 步骤5.验证
运行kubectl get pod查看pod运行情况。  
运行kubectl get pod my-nginx-xxxxxx-xxxx -o=jsonpath='{.spec.containers[0].image}'  
结果应该为048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn/dockerhub/nginx:1.17