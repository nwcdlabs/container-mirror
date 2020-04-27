# docker 和 docker-compose

直接修改文件中的 image 指向本项目 ECR 中相应镜像的路径，这里以 Docker 部署 xwiki 为例

## ECR登录/docker login
EKS、Kops on EC2用户可直接使用，无需 ECR登录/docker login。

确定你执行命令的IAM user / IAM role拥有下面权限：
```json
[
    "ecr:GetDownloadUrlForLayer",
    "ecr:BatchGetImage",
    "ecr:GetAuthorizationToken",
    "ecr:BatchCheckLayerAvailability"
]
```

对于docker用户，需要 ECR 登录/docker login 后才能使用：
```bash
pip install awscli --upgrade --user
aws ecr get-login-password --region cn-northwest-1 | docker login --username AWS --password-stdin 048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn
```

如果AWS CLI版本低于v1.17.10，需运行以下脚本：
```bash
aws ecr get-login --region cn-northwest-1 --registry-ids 048912060910 --no-include-email | sh
```

您也可以使用[ecr-credential-helper](https://github.com/awslabs/amazon-ecr-credential-helper) 完成登录。

## 使用 docker-compose 部署 xwiki
- 下载配置
```bash
mkdir -p ~/workspace/docker-xwiki && cd ~/workspace/docker-xwiki
wget https://raw.githubusercontent.com/xwiki-contrib/docker-xwiki/master/11/mysql-tomcat/mysql/xwiki.cnf

wget https://raw.githubusercontent.com/xwiki-contrib/docker-xwiki/master/11/mysql-tomcat/mysql/init.sql

wget -O docker-compose.yml https://raw.githubusercontent.com/xwiki-contrib/docker-xwiki/master/docker-compose-mysql.yml
```

- 修改 image 路径
```yaml
version: '2'
networks:
  bridge:
    driver: bridge
services:
  web:
    image: 048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn/dockerhub/xwiki:lts-mysql-tomcat
    container_name: xwiki-mysql-tomcat-web
    depends_on:
      - db
    ports:
      - "8080:8080"
    environment:
      - DB_USER=xwiki
      - DB_PASSWORD=xwiki
      - DB_HOST=xwiki-mysql-db
    volumes:
      - xwiki-data:/usr/local/xwiki
    networks:
      - bridge
  db:
    image: 048912060910.dkr.ecr.cn-northwest-1.amazonaws.com.cn/dockerhub/mysql:5.7
    container_name: xwiki-mysql-db
    volumes:
      - ./xwiki.cnf:/etc/mysql/conf.d/xwiki.cnf
      - mysql-data:/var/lib/mysql
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    environment:
      - MYSQL_ROOT_PASSWORD=xwiki
      - MYSQL_USER=xwiki
      - MYSQL_PASSWORD=xwiki
      - MYSQL_DATABASE=xwiki
    networks:
      - bridge
volumes:
  mysql-data: {}
  xwiki-data: {}
```

- 部署
```
docker-compose up
docker logs --follow <container-id>
http://{instance-ip}:8080/bin/view/Main/
```

## 附录：如何安装 docker-compose
```bash
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
docker-compose --version
```
