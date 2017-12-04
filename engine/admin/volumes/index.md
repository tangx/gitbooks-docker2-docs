# Manage data in Docker

将数据放在容器的 `writable layer` 中有以下缺点：
+ 数据无法 `持久化`。当然一个容器关闭后，另一个容器不能再使用这些数据。
+ `writable layer` 与宿主机 `紧耦合`。不能方便的迁移到其他地方。
+ 在 `writable layer` 中写数据需要 `storage driver` 管理文件系统。 `storage driver` 使用 `Linux kernel` 提供了一个 `union filesystem`。 与使用 *`data volumes`* 直接写入主机文件系统相比，这种方式会额外降低性能。

`Docker` 提供了 `3` 中不同的方式挂载挂载数据到容器中：
+ `volumes`
+ `bind mounts`
+ `tmpfs`

当不能明确选择使用哪种方式的时候，就是用 `volumes`。


## Choose the right type of mount

无论选择哪种挂载方式，数据在容器中看起来都一样；要么是个文件夹，要么是一个独立的文件。

下图很好的说明了， `volumes`, `bind mounts` 和 `tmpfs` 三种方式在宿主机上存放数据的位置。

![types-of-mounts.png](types-of-mounts.png)

+ **`volumes`**: 将数据存放在由 `docker 管理` 的 `文件系统` 的一部分中 (linux 下为 `/var/lib/docker/volumes/`)。 `Non-Docker` 进程无法修改改文件系统。 **`volumes` 是最佳的 `持久化` 数据的方案。**
+ **`bind mounts`**: 数据存在于 `宿主机` 的 `任何地方`。这些数据对于宿主机也可能是很重要的文件或目录。 `Non-docker` 进程在任何时间都可以修改这些文件。
+ **`tmpfs`**: 将数据存放在 `宿主机` 的 `内存` 中。并且 `永远` 不会落盘写入文件系统。

### More details about mount types

### Volumes

+ 由 `Docker` 创建并管理。
  + 使用 `docker volume create <volume_name>` 创建
  + 或在创建 `容器` 或 `服务` 时附带创建。

```bash
$ docker volume create -d local test-vol
test-vol

$ ll /var/lib/docker/volumes/
drwxr-xr-x  3 root root  4096 Oct  3 14:44 test-vol/

$ docker volume create
8d360a1944d08e1ddb3e96981642504ca33b4d4d9c630733fd7c5c6eef7b3503
$ docker volume create
f2cf1aabeadc2568a2ca186722840b249bf89db2aac78c0812c2baf31d985a78
```

+ 当创建创建一个 `volume` 的时候， Docker 在宿主机上相应位置创建一个 `目录`。
  + 当 `mount` volume 到容器中时，实际就是 `mount` 该目录到容器中。
  + 与 `bind mounts` 类似，但 `volume` 有 `Docker` 管理，并与宿主机的核心功能 `隔离`。

+ 一个 `volume` 可以同时 `mount` 到多个容器。
  + 当没有容器挂载， `volume` 依旧可以通过 `Docker` 管理，并不会自动删除。
  + 可以使用 `docker volume prune` 命令删除没用的 `volume`。

```bash
$ docker volume prune
WARNING! This will remove all volumes not used by at least one container.
Are you sure you want to continue? [y/N] y
Deleted Volumes:
8d360a1944d08e1ddb3e96981642504ca33b4d4d9c630733fd7c5c6eef7b3503
f2cf1aabeadc2568a2ca186722840b249bf89db2aac78c0812c2baf31d985a78
test-vol
```

+ 当挂载 `volume` 时，`volume` 可以被 `命名` 或 `匿名`。
  + `匿名卷 (anonymous volumes)` 是指那些第一次挂载时，没有为其指定名称的卷，因此 Docker 为这些卷分配了一个随机名称，以此保证卷名的唯一性。
  + `命名卷 (name volumes)` 和 `匿名卷` 除了名称上的差别，实际行为都一样。

+ `Volumes` 同样支持 `volumes drivers`，因此允许将数据放在远程主机或云服务器上。


### Bind mounts

+ 与 `volumes` 相比， `bind mounts` 有一些功能限制。
+ 挂载的时候，需要指定 `宿主机` 上的 `源路径` 必须是 `绝对路径`。
+ 挂载之前，`容器` 中的 `目标路径` 可以不存在。如不存在，挂载时会自动创建。
+ `bind mounts` 效率可以很高，但是依赖宿主机具有特殊结构的文件系统。
+ 发布 Docker 应用时，优先考虑 `volumes`。
+ `bind mounts` 不能通过 `Docker CLI` 直接进行管理。

> **警告**: 使用 `bind mounts` 挂载的目录或文件可以在宿主机上直接进行修改，删除等操作。


### tmpfs mounts

通过 `tmpfs` 挂载的数据，无论是在宿主机或者容器中都不会被持久化。可以用在容器的生命周期内，保存一些非持久状态或敏感信息。For instance, internally, swarm services use tmpfs mounts to mount secrets into a service’s containers.

### difference between three mount type

+ `bind mount` 和 `volume mount` 都是使用 `-v / --volume` 进行挂载， 但参数有点不同。
+ `tmpfs` 使用 `--tmpfs`。
+ 在 `docker 17.06` 之后， 建议以上三种类型都是用使用 `--mount` 进行挂载。

## Good use cases for volumes

建议使用 `volume` 的场景包括：

+ 当需要多个不同容器之间共享数据。
  + 如果不特别指定，容器启动时会自动创建一个 `volume`
  + 该容器删除后， `volume` 依旧存在。
  + 一个或多个其他容器可以挂载这个 `volume`, `rw/ro` 权限。
  + `volume` 在明确指出删除的情况下，才会被删除。
+ 当宿主机不能提供 `bind mount` 挂载的 `目录或文件结构` 时。
  + `volume` 可帮助您将Docker主机的配置与容器运行时分离。
+ 当需要在 `远程主机` 或 `云存储服务` 上保存数据时。
+ 当需要将数据在宿主机之间 `备份` 、 `恢复` 和 `迁移` 时。
  + 首先，停止容器
  + 再次，备份 `volume` 目录（ex: `/var/lib/docker/volumes/<volume_name>` ）

## Good use case for bind mounts

建议使用 `bind mount` 的场景包括：

+ 在宿主机和容器之间共享 `配置文件` 。
  + 例如， Docker 本身的 DNS 解析。 `/etc/resolv.conf` 在宿主机和所有容器之间共享
+ 在开发环境下宿主机的和容器之间共享 `代码` 和 `编译组件` 。
  + 使用 `bind mount` 快速挂载，而不是将代码 `COPY` build 到镜像中。
+ 当宿主机的文件或目录结构保证与容器 `bind mount` 一致时。

## Good use cases for tmpfs mount

建议使用 `tmpfs mount` 的场景包括：

+ 处于安全或性能考虑，不想数据被保存在宿主机硬盘或容器中。

## Tips for using bind mounts or volumes

如果同时使用 `bind mount` 和 `volumes` ，需要注意一下几点：

+ 在使用 `volume` 时，如果镜像中的挂载点目录原本就有文件，那么这些文件会复制到 `volume` 中。
  + This is a good way to pre-populate data that the Docker host needs (in the case of bind mounts) or that another container needs (in the case of volumes).
  + `bind mount` 不会， `docker-ce 17.09` 中测试

```bash
# 创建新 volume
$ docker volume create testvol
testvol

# 查看 volume 中的内容
$ tree /var/lib/docker/volumes/testvol/
/var/lib/docker/volumes/testvol/
└── _data

1 directory, 0 files

# 将 volume 挂载到 container 中， 挂载点中原来就有内容
$ docker run --rm -v testvol:/etc/nginx/ nginx ls /etc/nginx
conf.d
fastcgi_params
koi-utf
koi-win
mime.types
modules
nginx.conf
scgi_params
uwsgi_params
win-utf

# 再次查看挂载点，容器中的内容被复制到了 volume 中
$ tree /var/lib/docker/volumes/testvol/
/var/lib/docker/volumes/testvol/
└── _data
    ├── conf.d
    │   └── default.conf
    ├── fastcgi_params
    ├── koi-utf
    ├── koi-win
    ├── mime.types
    ├── modules -> /usr/lib/nginx/modules
    ├── nginx.conf
    ├── scgi_params
    ├── uwsgi_params
    └── win-utf

2 directories, 10 files
```

```bash
# 创建一个 bind mount 挂载源目录
$ mkdir -p testdir
$ ls testdir/

# 查看镜像中挂载点内容
$ docker run --rm nginx ls /etc/nginx
conf.d
fastcgi_params
koi-utf
koi-win
mime.types
modules
nginx.conf
scgi_params
uwsgi_params
win-utf

# 挂载时，查看挂载点无内容
$ docker run --rm -v /root/testdir/:/etc/nginx/ nginx ls /etc/nginx

# 挂载后，查看宿主机挂载路径无内容
$ ls testdir/
```

+ 在使用 `bind mount` 或 `volume` 挂载时，如果 `源目录` 或 `volume` 中有数据，那么，容器中挂载点原本的数据将会被隐藏，类似 linux 下的 `mount`。
