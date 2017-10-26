# 创建基础镜像

+ 大多数时候，只需要使用 `FROM` 抓取官方镜像进行修改
+ 在某些时候，可能需要自己创建镜像

## 使用 tar 创建完整镜像

打包压缩当前系统，创建完整初始镜像。

以 `ubuntu` 为例

```bash
$ sudo debootstrap xenial xenial > /dev/null
$ sudo tar -C xenial -c . | docker import - xenial

a29c15f1bf7a

$ docker run xenial cat /etc/lsb-release

DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=16.04
DISTRIB_CODENAME=xenial
DISTRIB_DESCRIPTION="Ubuntu 16.04 LTS"
```

There are more example scripts for creating parent images in the Docker GitHub Repo:

+ [BusyBox](https://github.com/moby/moby/blob/master/contrib/mkimage/busybox-static)
+ CentOS / Scientific Linux CERN (SLC) [on Debian/Ubuntu](https://github.com/moby/moby/blob/master/contrib/mkimage/rinse) or [on CentOS/RHEL/SLC/etc](https://github.com/moby/moby/blob/master/contrib/mkimage-yum.sh).
+ [Debian / Ubuntu](https://github.com/moby/moby/blob/master/contrib/mkimage/debootstrap)


## 使用 scratch 创建一个简单父镜像

`scratch` 是 docker 维护的一个小型镜像。

没多大意义


## 其他

更多创建 `基本镜像` 或者 `黑箱镜像` 可以参考
+ [使用 `import` 创建镜像](https://docker.octowhale.com/chapter02/03-build-your-own-image-with-import.html)
+ [使用 `commit` 创建镜像](https://docker.octowhale.com/chapter02/03-build-your-own-image-with-commit.html)
