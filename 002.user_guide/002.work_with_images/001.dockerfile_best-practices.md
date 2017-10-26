# Best practices for writing Dockerfiles

dockerfile 是一个包含特殊命令格式的文件，描述了如何 `build` 一个镜像。

This document covers the best practices and methods recommended by Docker, Inc. and the Docker community for creating `easy-to-use`, `effective` Dockerfiles. We `strongly suggest` you `follow` these recommendations (**in fact, if you’re creating an Official Image, you must adhere to these practices**).

> Note: for more detailed explanations of any of the Dockerfile commands mentioned here, visit the [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/) page.

## General guidelines and recommendations

### Containers should be ephemeral( 无状态容器 )

`dockerfile` 创建的容器应该是 `无状态` 的，容器可以被关闭销毁，并且可以被新建的容器替代。参考 [Processes](https://12factor.net/processes)

### 使用 .dockerignore

为了提高性能，可以使用 `.dockerignore` 忽略编译时不必要的文件。用法与 `.gitignore` 相似。 参考[.dockerignore](https://docs.docker.com/engine/reference/builder/#dockerignore-file)

### 避免安装不必要的包

降低复杂性、依赖以、包大小以及 `build` 时间。

### Each container should have only one concern (容器功能单一性)

将多个应用放入多个容器中，可以更好的横向扩展和服用容器。

`one process per container` 是个不错的宗旨，但并不是一个 `快捷的方法`。 应该让容器尽可能的保持 `clean` 与 `模块化(modular)`

You may have heard that there should be “`one process per container`”. While this mantra has good intentions, it is `not necessarily true` that there should be only one operating system process per container. In addition to the fact that containers can now be s[pawned with an init process](https://docs.docker.com/engine/reference/run/#/specifying-an-init-process), some programs might spawn additional processes of their own accord.

### 减少容器层数

保持 `dockerfile` 的可读性与 `容器层数` 之间的平衡。

### 参数排序换行

使用 `\` 换行后，可以方便的修改、去重、增加可读性。

```
RUN apt-get update && apt-get install -y \
  bzr \
  cvs \
  git \
  mercurial \
  subversion
```

### 善用 build 缓存

docker build 的时候按照 `dockerfile` 中指令顺序执行。每个指令`执行之前`，docker 检查该指令是否存在缓存镜像，以及是否可以`复用`，而不是重新创建一个重复镜像。If you do not want to use the cache at all you can use the `--no-cache=true` option on the docker build command.

复用镜像缓存的基本原则：
+ `Starting with a parent image that is already in the cache`, the next instruction is compared against `all child images` derived(自..衍生) from that base image to see if one of them was built using the exact same instruction. If not, the cache is invalidated

+ In most cases simply comparing the instruction in the `Dockerfile` with one of the child images is sufficient. However, certain instructions require a little more examination and explanation.

+ For the `ADD` and `COPY` instructions, `the contents of the file(s) in the image` are examined and a `checksum` is calculated `for each file`. The `last-modified and last-accessed` times of the file(s) are `not` considered in these checksums. During the cache lookup, the checksum is compared against the checksum in the existing images. If anything has changed in the file(s), such as the contents and metadata, then the cache is invalidated.

+ Aside from the `ADD` and `COPY` commands, cache checking `will not` look at the files in the container to `determine a cache match`. 缓存一致性检查不会涉及容器中的缓存文件。


## 容器指令

### FROM

[Dockerfile reference for the FROM instruction](https://docs.docker.com/engine/reference/builder/#from)

指定父镜像。任何时候，都尽量选择官方镜像。推荐使用 `Debian images`

### LABEL

[Understanding object labels](https://docs.docker.com/engine/userguide/labels-custom-metadata/)

在项目中，使用 `LABEL` 标记 `镜像` 标签是一个个 `键值对`

> **Note**: 如果值有空格，使用 `双引号 (")` 括起开。尽量避免 `值` 里面本身就包含双引号，

三种有效格式

```
# Set one or more individual labels
LABEL com.example.version="0.0.1-beta"
LABEL vendor="ACME Incorporated"
LABEL com.example.release-date="2015-02-12"
LABEL com.example.version.is-production=""

# Set multiple labels on one line
LABEL com.example.version="0.0.1-beta" com.example.release-date="2015-02-12"

# Set multiple labels at once, using line-continuation characters to break long lines
LABEL vendor=ACME\ Incorporated \
      com.example.is-beta= \
      com.example.is-production="" \
      com.example.version="0.0.1-beta" \
      com.example.release-date="2015-02-12"
```

### RUN

[Dockerfile reference for the RUN instruction](https://docs.docker.com/engine/reference/builder/#run)

As always, to make your `Dockerfile` more `readable`, `understandable`, and `maintainable`, split `long or complex` `RUN` statements on `multiple lines` separated with `backslashes`.

#### APT-GET

避免使用 `UN apt-get upgrade` or `dist-upgrade` 。 而应该指定特定的包，例如 `apt-get install -y foo`。

Always `combine(联合)` `RUN apt-get update` with `apt-get install` in the same RUN statement, for example:
```
RUN apt-get update && apt-get install -y \
    package-bar \
    package-baz \
    package-foo
```
Using `apt-get update alone` in a `RUN` statement causes `caching issues` and subsequent `apt-get install` instructions `fail`. (由 build cache 引起的)。
Using `RUN apt-get update && apt-get install -y` ensures your Dockerfile installs the `latest package versions` with no further coding or manual intervention.

Below is a `well-formed` `RUN` instruction that demonstrates all the `apt-get` `recommendations`.

```
RUN apt-get update && apt-get install -y \
    aufs-tools \
    automake \
    build-essential \
    curl \
    dpkg-sig \
    libcap-dev \
    libsqlite3-dev \
    mercurial \
    reprepro \
    ruby1.9.1 \
    ruby1.9.1-dev \
    s3cmd=1.1.* \
 && rm -rf /var/lib/apt/lists/*
```

#### USING PIPES

部分 `RUN` 命令支持 `管道 (|)`。

例如：

```dockerfile
RUN wget -O - https://some.site | wc -l > /number
```

上诉命令使用 `/bin/sh -c` 解释器， `最后一个`(这里为 `wc -l` ) `退出值` 是否成功决定了此次 `RUN` 命令是否成功。此案例中，即使 `wget` 失败了，`RUN` 也是成功的。

使用 `set -o pipefail &&` 可以保证管道失败的时候， `RUN` 也失败。

```dockerfile
RUN set -o pipefail && wget -O - https://some.site | wc -l > /number
```

> 注意： `不是所有` shell 都支持 `-o pipefail` 。
>> `dash shell` 就不支持支持。因此可以考虑 `exec` 格式的 `RUN`。

```dockerfile
RUN ["/bin/bash", "-c", "set -o pipefail && wget -O - https://some.site | wc -l > /number"]
```

### CMD

[Dockerfile reference for the CMD instruction](https://docs.docker.com/engine/reference/builder/#cmd)

+ `CMD` 命令只应该出现在 `dockerfile` 中一次。
  + 如果重复出现，只有最后一个会生效
+ `CMD` 三格式：
  + `exec` form : `CMD ["executable","param1","param2"]` , 推荐使用
    + 传递 `json` 数组。必须使用 `双引号`
  + 作为 `ENTRYPOINT` 默认参数 : `CMD ["param1","param2"]`
    + 参考 [《docker 99 问》 CMD 和 ENTRYPOINT 到底有什么不同](https://blog.lab99.org/post/docker-2016-07-14-faq.html#entrypoint-he-cmd-dao-di-you-shi-me-bu-tong)
  + `shell` form : `CMD command param1 param2`
    + 默认使用 `/bin/sh -c` 解释器
+ `CMD` 命令会在容器内部执行。
+ `CMD` 命令应该始终使用如下格式
  + `CMD ["executable", "param1", "param2"…]`
  + ex: `CMD ["apache2","-DFOREGROUND"]`
+ `CMD`命令大多数情况下应该指定一个 `可交互` 的 `shell` , 例如 `bash`, `python` 等
  + ex: `CMD ["perl", "-de0"]` , `CMD ["python"]`
  + 这样，创建容器时可以使用 `docker run -it python`
+ 尽量不要使用 `CMD ["param1","param2"]` 与 `ENTRYPOINT` 组合格式，除非你清楚的知道你在做什么。


### EXPOSE

[Dockerfile reference for the EXPOSE instruction](https://docs.docker.com/engine/reference/builder/#expose)

指定容器提供服务的端口

```dockerfile
EXPOSE <port> [<port>...]
```

+ 使用 : `docker run -p out_port:inter_port` 实现映射
+ For container linking, Docker provides environment variables for the path from the recipient container back to the source (ie, `MYSQL_PORT_3306_TCP`).

延展阅读 [EXPOSE 与 PUBLISH 的区别](https://blog.lab99.org/post/docker-2016-07-14-faq.html#zen-me-ying-she-su-zhu-duan-kou-dockerfile-zhong-de-expose-he-docker-run-p-you-sha-qu-bie)

### ENV

[Dockerfile reference for the ENV instruction](https://docs.docker.com/engine/reference/builder/#env)

+ 设置容器的 `环境变量`
  + For example, `ENV PATH /usr/local/nginx/bin:$PATH` will ensure that CMD ["nginx"] just works.

+ 定义 `dockerfile` 变量
```
ENV PG_MAJOR 9.3
ENV PG_VERSION 9.3.4
RUN curl -SL http://example.com/postgres-$PG_VERSION.tar.xz | tar -xJC /usr/src/postgress && …
ENV PATH /usr/local/postgres-$PG_MAJOR/bin:$PATH
```


### AND or COPY

[Dockerfile reference for the ADD instruction](https://docs.docker.com/engine/reference/builder/#add)

[Dockerfile reference for the COPY instruction](https://docs.docker.com/engine/reference/builder/#copy)

+ `ADD` 和 `COPY` 功能相似，但推荐使用 `COPY`
+ `COPY` 只支持将文件从 `本地` 复制到 `镜像`
+ `ADD` 支持：
  + URL 支持 : `ADD http://example.com/big.tar.xz /usr/src/things/`
  + 解压支持 : `ADD rootfs.tar.xz /`
+ 使用多个 `COPY` 命令将文件分别复制到 `镜像` 中能更好的使用 `build cache` 机制
+ 在文件不需要被解压时，使用 `COPY` 而不是 `ADD`
+ 出于 `镜像容量` 考虑，应该使用 `curl / wget` 代替 `ADD` 的 `URL` 支持
  + 删除多余的文件
  + 减少镜像层数

```dockerfile
# ADD 命令
ADD http://example.com/big.tar.xz /usr/src/things/
RUN tar -xJf /usr/src/things/big.tar.xz -C /usr/src/things
RUN make -C /usr/src/things all

# 使用 curl / wget 代替
RUN mkdir -p /usr/src/things \
    && curl -SL http://example.com/big.tar.xz | tar -xJC /usr/src/things \
    && make -C /usr/src/things all
```

### ENTRYPOINT

[Dockerfile reference for the ENTRYPOINT instruction](https://docs.docker.com/engine/reference/builder/#entrypoint)

指定容器 `默认入口`

+ `ENTRYPOINT` 与 `CMD` : `ENTRYPOINT CMD`

```
ENTRYPOINT ["s3cmd"]
CMD ["--help"]

# 执行效果相当于 s3cmd --help
```

+ 优化 `ENTRYPOINT` 入口

For example, the [Postgres Official Image](https://hub.docker.com/_/postgres/) uses the following script as its `ENTRYPOINT`:
```bash
#!/bin/bash
set -e

if [ "$1" = 'postgres' ]; then
    chown -R postgres "$PGDATA"

    if [ -z "$(ls -A "$PGDATA")" ]; then
        gosu postgres initdb
    fi

    exec gosu postgres "$@"
fi

exec "$@"
```

> 注意： Note: This script uses the `exec` Bash command so that the final running application becomes the `container’s PID 1`. This `allows` the application to `receive` `any Unix signals` sent to the container. See the `ENTRYPOINT` help for more details.

> 注意2： `gosu` 用于替代 `sudo` 切换用户权限。更多信息参考 `USER` 命令
新入口

```dockerfile
COPY ./docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
```

### VOLUME

[Dockerfile reference for the VOLUME instruction](https://docs.docker.com/engine/reference/builder/#volume)

+ The `VOLUME` instruction creates `a mount point` with the specified name and marks it as `holding externally mounted` volumes from native host or other containers.
+ `VOLUEME` 指令创建了一个 `挂载点`，该挂载点可以挂在来自于 `本地目录` 或 `其他容器` 的卷。
  + 就像 `EXPOSE` 指令暴露了一个可以被映射的端口一样。

+ 需要将容器可变数据放入到挂载目录中
  + 数据盘
  + 日志盘
  + ...

### USER

[Dockerfile reference for the USER instruction](https://docs.docker.com/engine/reference/builder/#user)


+ 如果容器服务可以运行与非特权用户，可以使用 `USER` 切换用户

```dockerfile
USER <user>[:<group>] or
USER <UID>[:<GID>]
```

创建用户

```dockerfile
RUN groupadd -r postgres && useradd --no-log-init -r -g postgres postgres
```

> 注意： 上述命令在添加用户时将的到一个 `非固定` 的 `UID/GID`。 如果有需要，可以使用命令指定 `UID/GID`.

> 注意2： Due to an [unresolved bug](https://github.com/golang/go/issues/13548) in the Go archive/tar package’s handling of sparse files, attempting to create a user with a sufficiently `large UID` inside a Docker container can lead to disk exhaustion as `/var/log/faillog` in the container layer is `filled with NUL (\0)` characters. Passing the `--no-log-init flag` to useradd works around this issue. The `Debian/Ubuntu` `adduser` wrapper `does not` support the `--no-log-init` flag and should be avoided.

+ 在容器中，使用 `gosu` 代替 `sudo`
+ 不要 `频繁` 的在 `dockerfile` 中切换用户

### WORKDIR
[Dockerfile reference for the WORKDIR instruction](https://docs.docker.com/engine/reference/builder/#workdir)

```dockerfile
WORKDIR /path/to/workdir
```

+ `WORKDIR` 的参数应该使用 `绝对路径`
+ 使用 `WORKDIR` 而不是 `RUN cd /some/path && do something`


### ONBUILD

[Dockerfile reference for the ONBUILD instruction](https://docs.docker.com/engine/reference/builder/#onbuild)

在 `镜像上` 操作。

不是很懂。


## Examples for Official Repositories

These Official Repositories have exemplary Dockerfiles:

+ [Go](https://hub.docker.com/_/golang/)
+ [Perl](https://hub.docker.com/_/perl/)
+ [Hy](https://hub.docker.com/_/hylang/)
+ [Ruby](https://hub.docker.com/_/ruby/)
