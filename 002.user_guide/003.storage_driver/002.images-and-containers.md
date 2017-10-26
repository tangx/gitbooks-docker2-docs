# 镜像、容器与存储

> https://docs.docker.com/engine/userguide/storagedriver/imagesandcontainers



# 镜像与层

+ 一个镜像包含多个 `层 (layer)` 堆叠 `(stack)` 而成
+ 每一层代表一个 `dockerfile` 指令
+ 除了最后一层，其他都为 `只读 (read-only)`
+ 每个 `layer` 都与之前的不一样
+ 当创建 `container` 时， 会在顶端新建一个 `可写层(writable layer)`，被称为 `容器层 (container layer)`
+ 所有文件 `更改` 都发生在 `容器层`


下图展示了 `ubuntu 15.04` 镜像的层级关系

![container-layers.jpg](container-layers.jpg)

+ `存储驱动 (storage driver)` 管理这些层之间的关系。
+ 不同的 **存储驱动** 有各自不同的特性。


## 容器与层

+ 多个 `container` 可以共享一个 `image`
+ 每个 `container` 在 `image` 的基础上创建一个属于各自的 `writable layer`
+ 所有文件变动都 `只会` 发生在 `writable layer` 上
+ 任何文件变动都 `不会` 影响到 `image`
+ `container` 在被删除的时候，相应的 `writable layer` 也被删除

下图展示了 `ubuntu 15.04` 镜像创建多个 `容器` 之间的关系

![sharing-layers.jpg](sharing-layers.jpg)

> 注意： 如果你有`多个`镜像需要 `共享访问` `相同的数据` ，那么需要将这些数据放在 `docker volume` 中，并 `mount` 到你的容器中。


## 容器在磁盘上的大小

+ 使用命令 `docker container ps -s` 查看运行中容器的大小
+ `SIZE`: 当前容器的 `writable layer` 大小
+ `virtual size`: 容器使用的 `read-only` 镜像大小
  + 还可以通过 `docker image ls` 查看
  + 不同的容器可能使用相同的镜像，因此统计 `virtual size` 是不能简单的相加

  ```bash
  $ docker container ps -s

  CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES                    SIZE
  714135f3cac4        registry:2          "/entrypoint.sh /e..."   28 hours ago        Up 28 hours         0.0.0.0:5000->5000/tcp   registryproxy_mirror_1   0B (virtual 33.2MB)
  ```

+ 容器使用的总容量为：所有容器的 `size` 与一个 `virtual size` 的和。
  + 这种说法并不包含以下几点：
  + 使用 `json-file` logging drive 的日志文件大小。
  + 容器使用的 `volume`
  + 容器的配置，通常很小
  + Memory written to disk (if swapping is enabled)
  + checkpoint, if you're useing the experimental checkpoint/restore feature.

## copy-on-write(CoW) 策略

+ `CoW` 策略是一种高效的 `sharing and copying` 策略。
+ 尽可能的降低了 `I/O` 消耗
+ 当一个文件在低层 `layer` 中存在时，可以直接访问并读取。
+ 当一个文件 `第一次` 被修改时，先复制到当前 `writable layer`，然后在修改

### sharing promotes smaller images

使用命令 `docker pull <image>` 的时候

+ `image` 的每一次独立下载
+ `Linux` 系统存放在 `/var/lib/docker/` 目录下
  + `/var/lib/docker/<storage-driver>/layers/`
+ 使用 `docker history <image>` 查看镜像的 `build` 过程
  + 输出中含有 `<missing>` 的 `layer` 表示： 这些 `layer` 在其他系统上 `build` 并且在本地不可用。可以被忽略

### Copying makes containers efficient

当发生 `copy-on-write` 操作时，具体步骤和具体的 `storage driver` 有关。

默认的 `aufs` driver 以及 `overlay`, `overlay2` drivers 的 `CoW` 步骤如下：

+ 首先，搜索 `image layer` 中是否包含此文件。 从 `最上层` 开始，到 `最下层` 为止。当找到后，添加到 `cache` 中等待下一步操作。
+ 随后，`copy_up` 操作将找到的文件复制到容器的 `writable layer`。
+ 最后，针对此文件的所有操作，容器都不会再次进行搜索底层 `layer` 了。

`Btrfs`, `ZFS` 和其他 storage dirver 的 `CoW` 实现方式不同。

+ 有 `write` 操作的容器会消耗更多的资源，因为 `write` 操作的结果会保存在 `writable layer` 中。

> 注意： 对于 `write-heavy` 应用，不应该将 `data` 保存在容器中。 而应该使用 ·`Docker volume`。

A `copy_up` operation can incur a `noticeable` performance `overhead`. This `overhead` is `different depending on` which `storage driver` is in use. `Large files`, `lots of layers`, and `deep directory trees` can make the impact more `noticeable`. This is mitigated by the fact that each `copy_up` operation only occurs the `first time` a given file is modified.

+ 容器在启动时就就会创建 `writable layer`，而不仅是在有 `CoW` 操作时。


## Data volumes and the storage driver

+ 当容器被删除时，没有保存在 `data volume` 中的数据也将被删除。
+ `data volume` 是直接被挂载到容器中的 `directory` 或 `file`
+ `data volume` 不受 `storage driver` 控制
  + `Reads` and `writes` to `data volumes` `bypass` the storage driver and operate at native host
+ 一个容器可以挂载多个 `data volume`
+ 一个 `data volume` 可以被多个容器挂载

下图展示了：

+ 一个主机启动了两个容器
+ 每个容器在 `/var/lib/docker` 下有自己的磁盘空间
+ 每个容器还分别挂载了一个 `data volume` 到容器的 `/data`

![shared-volume.jpg](shared-volume.jpg)

+ Data volumes reside outside of the local storage area on the Docker host, further reinforcing their independence from the storage driver’s control.
+ When a container is deleted, any data stored in data volumes persists on the Docker host.
