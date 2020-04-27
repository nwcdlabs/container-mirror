# Helm Chat usage guide

利用 Helm Charts 部署应用，并且chart template支持自定义Pod image，可以设置 chart 参数，指向本项目 ECR 中相应镜像的路径，

## Helm 部署 cluster-autoscaler 示例

通过 `--set image.repository` 和 `--set image.tag` 设置 chart 参数

```bash 
# 部署
helm search repo cluster-autoscaler

# Helm 3 example
helm install my-ca-helm stable/cluster-autoscaler --namespace kube-system \
--set autoDiscovery.clusterName=${CLUSTER_NAME} --set cloudProvider=aws --set awsRegion=${AWS_REGION} \
--set image.repository=048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn/gcr/google_containers/cluster-autoscaler --set image.tag=v1.14.7 
# Helm 2 --name my-ca-helm
helm install --name my-ca-helm stable/cluster-autoscaler --namespace kube-system \
--set autoDiscovery.clusterName=${CLUSTER_NAME} --set cloudProvider=aws --set awsRegion=${AWS_REGION} \
--set image.repository=048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn/gcr/google_containers/cluster-autoscaler --set image.tag=v1.14.7 

# 检查是否成功
kubectl get pod $(kubectl get pods -n kube-system | egrep -o "my-ca-helm[a-zA-Z0-9-]+") -n kube-system 

# 获取image地址
kubectl get pod $(kubectl get pods -n kube-system | egrep -o "my-ca-helm[a-zA-Z0-9-]+") -n kube-system -o=jsonpath='{.spec.containers[0].image}'
048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn/gcr/google_containers/cluster-autoscaler:v1.14.7

# 清理
helm delete my-ca-helm --namespace kube-system
```

## Helm 部署 wordpress 示例

```bash
# 部署
helm search repo wordpress

kubectl create namespace wordpress
helm install wordpress stable/wordpress --namespace wordpress \
--set image.repository=wordpress --set image.tag=5.4 \
--set mariadb.enabled=false --set externalDatabase.host=myexternalhost --set externalDatabase.user=myuser \
--set externalDatabase.password=mypassword --set externalDatabase.database=mydatabase --set externalDatabase.port=3306

# 检查是否成功和获取image地址
kubectl get pods -n wordpress
kubectl get pod $(kubectl get pods -n wordpress | egrep -o "wordpress[a-zA-Z0-9-]+" | head -1) -n wordpress -o=jsonpath='{.spec.containers[0].image}'

# 访问
export SERVICE_IP=$(kubectl get svc --namespace wordpress wordpress --template "{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}")
echo "WordPress URL: http://$SERVICE_IP/"
echo "WordPress Admin URL: http://$SERVICE_IP/admin"

echo Username: user
echo Password: $(kubectl get secret --namespace wordpress wordpress -o jsonpath="{.data.wordpress-password}" | base64 --decode)

# 清理
helm delete wordpress --namespace wordpress
```

