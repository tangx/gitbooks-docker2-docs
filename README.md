# Docker 17.09 官方文档中文笔记

基于官网文档 17.09 

> 建议有英语能力的人直接到 [docker 官网文档](https://docs.docker.com) 去看。

[目录](/SUMMARY.md)

## 项目地址

+ **GitHub 项目地址**: https://github.com/octowhale/gitbooks-docker2-docs/
+ **GitBooks 在线阅读**: https://www.gitbook.com/read/book/octowhale/docker-doc-cn

## 常见问题

+ 学会如何聪明的提问 [《提问的智慧》](https://github.com/ryanhanwu/How-To-Ask-Questions-The-Smart-Way/blob/master/README-zh_CN.md)
+ 对 Docker 不是很了解，还有很多问题，可以先去看看 **蜗牛大哥** 的 [《常见 docker 100 问》](https://blog.lab99.org/post/docker-2016-07-14-faq.html)。在这里几乎能找到你入门的所有答案。

### 勘误

如果你有心帮助后来人，发现文章里面有错误的地方，
+ **GitBooks**: 请通过 `gitbooks 下方的 disqus` 留言。
+ **GitHub Issus**: https://github.com/octowhale/gitbooks-docker2-docs/issues

## 准备工作

如果你还没有安装 docker， 可以选择直接到 [docker 官网](https://docs.docker.com/engine/installation/) 寻找操作系统发行版的安装方式。
+ 为了保证 Docker 最新功能，尽量选择 `ubuntu 16.04` 上安装，可以直接看 [在 ubuntu 16.04 上安装 docker-ce](000.get_docker/000.install-docker-ce.md)。
+ 不要 **CentOS 6** 安装 Docker，不要安装 **CentOS 7** 自带源中的 Docker

#### 代理服务器

在本地测试环境中，最好搭建一个『仓库代理服务器』。如果你用的是大水管，那当我没说。搭建 `代理服务器` 的时候，使用 `国内镜像源`，可以加速下载。
+ [启动『仓库代理服务器』](/999.examples/002.registry_proxy/registry_proxy.md)

#### 镜像服务器

国内镜像源。其实用诸如 aliyun、 daocloud 的源也没关系。这里提供两个不用注册即可使用的官方镜像源。配置方法参考 [启动『仓库代理服务器』](/999.examples/002.registry_proxy/registry_proxy.md)
+ docker-cn 官方：`https://registry.docker-cn.com`
+ 中科大： `https://docker.mirrors.ustc.edu.cn`

## Lisences

本项目遵循 [`GNU GENERAL PUBLIC LICENSE Version 3`](./LICENSE)


## 捐助

如果你觉得该文档对你有所帮助

可以通过 `微信` 请我喝杯咖啡。

![wechat pay](/donate/wechat_pay.png)