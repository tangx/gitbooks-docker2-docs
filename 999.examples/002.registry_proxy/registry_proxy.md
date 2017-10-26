# Docker 仓库代理服务器

## 镜像源与配置

由于国情原因，在国内从过来 `pull` 镜像是非常痛苦的。

好在国内的前辈提供了一些国内镜像源，可以很好的加速。
两个公开镜像源，不需要注册用户
+ docker-cn 官方：`https://registry.docker-cn.com`
+ 中科大： `https://docker.mirrors.ustc.edu.cn`

### 增加镜像源

`ubuntu 16.04` / `docker 17.06 `

```bash
# 1. 修改 daemon 配置
$ sudo vi  /etc/systemd/system/multi-user.target.wants/docker.service
ExecStart=/usr/bin/dockerd -H fd:// --registry-mirror=https://docker.mirrors.ustc.edu.cn/

# 2. 重启
$ sudo systemctl daemon-reload
$ sudo systemctl restart docker
```

## 镜像仓库代理

即使配置了国内源，但反复下载大镜像或者有个小水管也是很恼火的事情。

一般这种情况下有三种考虑：
+ 自建镜像仓库， `registry`
+ 自建镜像仓库代理， `registry:2`
+ 二合一。 官方 `registry` 镜像无法实现，可以通过 `nexus` 镜像实现。


### 启动仓库

1. 下载代理配置好的镜像仓库代理包 [registry_proxy.tar.gz](registry_proxy.tar.gz)
2. 解压并运行包中的 `bash start.sh`

> 注意: 需要依赖 [docker-compose](https://github.com/docker/compose/releases) 组件

3. 将前面介绍的 `docker daemon` 配置的镜像，替换成你当前的镜像仓库代理路径即可。

以下是具体配置

### 镜像仓库代理服务器配置

```yaml
# config.yml

version: 0.1
log:
  fields:
    service: registry
storage:
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
proxy:
  remoteurl: https://registry.docker-cn.com
```

### docker-compose 发布文件

```yaml
# docker-compose.yml

version: '2'
services:
  mirror:
    # restart: always 永远保持运行
    restart: always
    image: registry:2
    ports:
      - "5000:5000"
    volumes:
      - ./config.yml:/etc/docker/registry/config.yml
```

### 启动

```bash
#!/bin/bash

source ~/.bashrc

which docker-compose || {

    echo "sudo curl -L https://github.com/docker/compose/releases/download/1.16.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose"
    echo "sudo chmod +x /usr/local/bin/docker-compose"

}

cd $(dirname $0)

docker-compose -f docker-compose-registry-proxy.yml  up -d
```
