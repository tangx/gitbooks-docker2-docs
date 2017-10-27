# Docker 17.09 官方文档中文笔记

## 目录地址

[目录](/SUMMARY.md)

## 项目说明

为了更方便的阅读，本项目已经同步到 gitbooks 上了， 看这里 [Docker 17.09 官方文档中文笔记 https://docs-cn.docker.octowhale.com](https://docs-cn.docker.octowhale.com)

### 文档版本

基于当前官网文档最新版本。

### 些许建议

+ 建议有英语能力的人直接到 [docker 官网文档](https://docs.docker.com) 去看。

+ 我是二把刀水准，这个中文文档的目的，最初是给自己做笔记用的。
  + 不能保证以后会同步更新官网内容
  + 不能保证所有中文意思都表达清楚了，且贴合官网内容
  + 不能保证没有错误。

+ 如果你有心帮助后来人，发现文章里面有错误的地方，请通过 `gitbooks 下方的 disqus` 留言。或者到 [gitbooks-docker2-docs](hhttps://github.com/octowhale/gitbooks-docker2-docs/issues) 提 ISSUS。

+ 个人时间有限，大概也许也就会做这么多了，对于 Docker 入门的朋友应该已经够用了。

## 常见问题

+ 如果你对 docker 有一点了解，但还不是很清楚 docker 的概念，可以先去看看 [蜗牛大哥](https://blog.lab99.org) 的 [《docker 100 问》](https://blog.lab99.org/post/docker-2016-07-14-faq.html)

+ `Dockerfile` 注重**事了拂衣去 深藏功与名**。不要创建太多无用的层级，也不要在层级中留下没用的文件或缓存。在写之前，最好先看看 [dockerfile 最佳实践](./002.user_guide/002.work_with_images/001.dockerfile_best-practices.md)， 另外在 [Docker Hub](https://hub.docker.com) 多看看官方镜像的写法。
  + 看看 [dockerfiles 实战](998.dockerfiles/README.md) 前面的列出的事项。
  + 在容器中不用 `sudo`， 而是使用 `gosu` 代替

+ 系统环境不要用 `CentOS 6` 系列。 内核太老了， Docker官方已经不支持了。你可能遇到的报错，在网上也搜不到，问了别人也一头雾水。不要把有限的时间浪费在无限的 debug 中。

### 准备工作

+ 如果你还没有安装 docker， 可以选择直接到 [docker 官网](https://docs.docker.com/engine/installation/) 寻找操作系统发行版的安装方式。
  + 如果你想在 `ubuntu 16.04` 上安装，可以直接看 [在 ubuntu 16.04 上安装 docker-ce](000.get_docker/000.install-docker-ce.md)。

+ 在本地测试环境中，最好搭建一个『仓库代理服务器』。如果你用的是大水管，那当我没说。搭建 `代理服务器` 的时候，使用 `国内镜像源`，可以加速下载。
  + [启动『仓库代理服务器』](999.examples/002.registry_proxy/registry_proxy.md)

+ 国内镜像源。其实用诸如 aliyun、 daocloud 的源也没关系。这里提供两个不用注册即可使用的官方镜像源。配置方法参考 [启动『仓库代理服务器』](999.examples/002.registry_proxy/registry_proxy.md)
  + docker-cn 官方：`https://registry.docker-cn.com`
  + 中科大： `https://docker.mirrors.ustc.edu.cn`

## Lisences

本项目遵循 [`GNU GENERAL PUBLIC LICENSE Version 3`](./LICENSE)