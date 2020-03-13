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
- [x] 使用webhook后，拉取k8s.gcr.io、gcr.io、quay.io镜像时，会自动替换为国内的ECR URI。详细介绍参见 https://github.com/aws-samples/amazon-api-gateway-mutating-webhook-for-k8