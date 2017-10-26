# Install Docker Compose

安装很简单，到 docker-compose 的 [github release](https://github.com/docker/compose/releases) 页面下载后，将 `二进制` 文件放入 `/usr/local/bin/` 目录下即可


## 安装

```bash

curl -L https://github.com/docker/compose/releases/download/1.16.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

```

## 升级

下载最新版本覆盖原来的即可

## 卸载

删除二进制文件即可
