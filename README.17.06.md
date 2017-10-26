# Docker 17.06 官方文档中文笔记

docker 官网文档阅读笔记及实验。

基于官方文档 `Docker v17.06`

| 系统     | docker 版本     |
| :------------- | :------------- |
| `Ubuntu 16.04.3` | `docker-ce 17.06-1` / `docker-ce 17.06-2` |



## 写在前面

1. 如果你有一点 Docker 知识或者知识比较凌乱，建议你先看一下 [Docker 99问](https://blog.lab99.org/post/docker-2016-07-14-faq.html).
2. 系统环境不要用 CentOS6 系列。 内核太老了， Docker官方已经支持了。你的报错，问了别人也一头雾水。 安装 Docker 尽量使用包管理安装，方便升级卸载。[安装方式](https://docs.docker.com/engine/installation/)
3. 在 `ubuntu 16.04` 下使用 `apt-get` 安装正式包， [在 ubuntu 16.04 上装 docker](000.get_docker/000.install-docker-ce.md)

4. 在测试环境中，最好搭建一个仓库代理服务器。不是『仓库加速源』，是『 [仓库代理服务器](999.examples/002.registry_proxy/registry_proxy.md) 』，再代理服务器配置国内加速源。尤其是本地网络下载限速的时候，你会发现，在多台机器上下载一个包是多么的畅快。

## Docker Engine user guide

> Estimated reading time: 1 minute
This guide helps users learn how to use Docker Engine.

## Learn by example

+ [Network containers](001.get_started/002.learn_by_example/001.network_container.md)
+ Manage data in containers
+ Samples
+ [Get started](001.get_started)

## Work with images

+ [Best practices for writing Dockerfiles](002.user_guide/002.work_with_images/001.dockerfile-最佳实践.md)
+ [Create a base image](002.user_guide/002.work_with_images/002.创建基础镜像.md)
+ Image management

## Manage storage drivers

+ [Understand images, containers, and storage drivers](002.user_guide/003.storage_driver/002.镜像与容器.md)
+ [Select a storage driver](002.user_guide/003.storage_driver/003.选择storage.driver.md)
+ AUFS storage in practice
+ Btrfs storage in practice
+ Device Mapper storage in practice
+ OverlayFS storage in practice
+ ZFS storage in practice

## Configure networks

+ [Understand Docker container networks](002.user_guide/004.networking/001.容器网络.md)
+ Embedded DNS server in user-defined networks
+ Get started with multi-host networking
+ [Work with network commands](002.user_guide/004.networking/002.work_with_network_command.md)

### Work with the default network

+ Understand container communication
+ Legacy container links
+ Binding container ports to the host
+ Build your own bridge
+ Configure container DNS
+ Customize the docker0 bridge
+ IPv6 with Docker

## Misc

+ Apply custom metadata
