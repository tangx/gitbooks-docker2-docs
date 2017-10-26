# Use volumes

`Volumes` 在 docker 中更推荐使用。虽然 `bind mount` 也可以用，但是 `bind mount` 更依赖于宿主机的目录结构。此外 `volumes` 完全通过 docker 管理。

`volumes` 比 `bind mount` 有以下几个优势：

+ `volumes` 更容易备份和迁移。
+ `volumes` 可以通过 `docker CLI` 和 `API` 进行管理。
+ `volumes` 可以在用于 `linux` 和 `windows` 下的容器。
+ `volumes` 在多个容器间共享更安全。
+ `volumes drivers` 允许你将 `volumes` 放在 `远程主机` 或 `云服务` 上，因此实现 `volumes` 内容加密或实现 `额外功能`。
+ 新 `volumes` 的内容可以由容器 `预先填充(pre-populated)`。
  + 即，当 `volumes` 为空，而挂载目录不为空的时候，目录中的内容会被自动复制到 `volumes` 中。

此外，将容器持久化数据放入 `volumes` 中比放入 `writable layer` 中更好，这样不会增加容器占用磁盘空间大小。当容器删除后， `volumes` 依然存在。

![002.types-of-mounts-volume.png](002.types-of-mounts-volume.png)

如果容器会产生的数据不需要被持久化，建议使用 `tmpfs mount` 

+ 以避免这些数据在某些地方被保存
+ 替代使用容器的 `writable layer` 从而提高效率。

Volumes use `rprivate` bind propagation, and bind propagation is not configurable for volumes.

## 使用 `-v` 还是 `--mount` 

+ 最开始， `-v` 或 `--volume` 用于 `standalone` 容器， 而 `--mount` 用于 `swarm services`；但从 `17.06` 开始 `--mount` 也可以用于 `standalone` 容器了。
+ `--mount` 可读性更高，意义更明确。
  + `-v` 将所有参数组合成一个；而 `--mount` 将他们分开
+ 如果主要指定 `volume driver`，必须使用 `--mount`

> 建议： 新人用 `--mount`；老鸟可能更熟悉 `-v / --volume` ，但建议使用 `--mount`


+ `-v / --volume`: 由 `3` 部分组成，用 `冒号 : ` 分隔。每部分的排序必须正确。`volume_name:mount_point:flag`
  + `volume_name`: 第一部分，指定被挂载的卷名。如果是 `命名卷` 这部分就是 `卷名称`, 如果是 `匿名卷` 这部分省略。
  + `mount_point`: 第二部分，指定 `volume` 在容器中的挂载路径。
  + `flag`: 第三部分，可选。如果有多个字段，以 `逗号 , ` 分隔。 字段将在下面进行讨论。

+ `--mount`: 由多个 `key-value` 对组成；以 `逗号 , ` 分隔；每个字段格式为 `<key>=<value>`。虽然 `--mount` 比 `-v` 更冗长，但是每个字段意义更明确，而且字段之间没有顺序限制。
  + `type`: 指定挂载类型，值为 `bind`, `volume`, `tmpfs`。此处为 `volume`。
  + `source / src`: 被挂载的卷名。如果为 `命名卷` 则为卷名。如果省略，则为 `匿名卷`。
  + `destination / dst / target `: 指定 `volume` 在容器中的挂载路径。
  + `readonly`: 如果存在，则所挂载的 `volume` 为只读。
  + `volume-opt`: 可以出现多次，使用 `key-value` 对指定 `option name` 和 `option value`。

## `-v` 与 `--mount` 的行为的异同

+ 与 `bind mount` 不同， `volume` 的所有参数都可以同时用于 `--mount` 和 `-v`。
+ 当 `volumes` 用于 `services` 时，只能使用 `--mount`。

## 创建与管理 volumes

与 `bind mount` 不同，可以在容器之外 `创建` 和 `管理` volume。

### 创建 volume

```bash
$ docker volume create my-vol
```

### 查看存在 volume

```bash
$ docker volume ls

local               my-vol
```

### 查看 volume 详细信息

```bash
$ docker volume inspect my-vol
[
    {
        "Driver": "local",
        "Labels": {},
        "Mountpoint": "/var/lib/docker/volumes/my-vol/_data",
        "Name": "my-vol",
        "Options": {},
        "Scope": "local"
    }
]
```

### 删除 volume

```bash
$ docker volume rm my-vol
```

## Start a container with a volume

在 `run` 一个容器时，如果 `volume` 不存在，则会自动被创建。下例中 `myvol2` 被挂载到容器中的 `/app/` 目录下。

下面两种写法是等价的
**`--mount`**

```bash
$ docker run -d \
  -it  \
  --name devtest  \
  --mount source=myvol2,target=/app  \
  nginx:latest

```

**`--volume`**

```bash
$ docker run -d \
  -it \
  --name devtest
  -v myvol2:/app  \
  nginx:latest
```

使用命令 `docker container inspect devtest` 验证 volume 已经被创建并且正确挂载。查看 `Mounts` 部分：

```json
"Mounts": [
    {
        "Type": "volume",
        "Name": "myvol2",
        "Source": "/var/lib/docker/volumes/myvol2/_data",
        "Destination": "/app",
        "Driver": "local",
        "Mode": "",
        "RW": true,
        "Propagation": ""
    }
],
```

结果表明了，挂载类型为 `volume` ， 卷和挂载点都正确，且挂载权限为 `read-write`。

停止容器并删除卷

```bash
$ docker container stop devtest

$ docker container rm devtest

$ docker volume rm myvol2
```


### start a service with volumes

当启动一个 `serice` 并定一个 `volume` 时， 每个容器会使用各自的 `local volume`。 当使用 `local` `volume driver` 时，所有容器都不能共享数据；但其他 `volume driver` 可以支持共享存储。 Docker for AWS 和 Docker for Azure 都支持使用 `Cloudstor plugin` 保存数据。

下例中， 创建了一个 4 个 nginx 容器实例的 `service`, 每个容器都使用各自的 `local volume`，名称都为 `myvol2`

```bash

$ docker swarm init

$ docker service create -d  \
  --name devtest-service  \
  --mount source=myvol2,target=app  \
  --replicas 4  \
  nginx:latest

```

使用命令 `docker service ps devtest-service` 验证 `service` 正常启动

```bash
$ docker service ps devtest-service 
ID                  NAME                IMAGE               NODE                DESIRED STATE       CURRENT STATE           ERROR               PORTS
11ckavzyee76        devtest-service.1   nginx:latest        instance-4          Running             Running 2 minutes ago                       
o7fmb0363h75        devtest-service.2   nginx:latest        instance-4          Running             Running 2 minutes ago                       
ftiz0l91v9wb        devtest-service.3   nginx:latest        instance-4          Running             Running 2 minutes ago                       
cbnd9h2hczqv        devtest-service.4   nginx:latest        instance-4          Running             Running 2 minutes ago 
```

删除 service 

```bash
$ docker service rm devtest-service
```

#### syntax differences for service

命令 `docker service create` 不支持使用 `-v` 或 `--volume`。当要挂载 `volume` 时，必须使用 `--mount`。


### Populate a volume using a container 

+ 当挂载一个 `空 volume` 到容器，且容器中挂载点中 `有` 文件时
  + Docker 会将 挂载点 中的文件复制到 `volume` 中
  + 容器挂载该 `volume`
  + 容器使用 `volume` 中的文件
  + 其他容器有权访问 `volume` 中的文件。


为了说明这个现象，下例中启动了一个 `nginx` 容器，并将 `空 volume` `nginx-vol` 挂载到容器中的 `/usr/share/nginx/html` 目录上，且该目录中那个有默认的 HTML 文件。

**`--mount`**

```bash
$ docker run -d  \
  -it  \
  --name=nginxtest  \
  --mount source=nginx-vol,dst=/usr/share/nginx/html  \
  nginx:latest

```

**`--volume`**

```bash
$ docker run -d  \
  -it  \
  --name=nginxtest
  -v nginx-vol:/usr/share/nginx/html  \
  nginx:latest
```

当通过上面的命令创建容器之后，下面的几条命令可以删除容器与卷：

```bash

$ docker container stop nginxtest

$ docker container stop nginxtest

$ docker volume rm nginx-vol

```

## 使用只读卷

某些情况下，你可能希望挂载的卷为 `只读` 状态，这个时候，
+ `-v / --volume` :  `ro`, 以 `冒号 : ` 分割
+ `--mount` : `readonly`， 以 `逗号 , ` 分割

例如

**`--mount`**

```bash
$ docker run -d  \
  -it  \
  --name=nginxtest  \
  --mount src=nginx-vol,dst=/usr/share/nginx/html,readonly  \
  nginx:latest
```

**`-v / --volume`**

```bash
$ docker run -d  \
  -it  \
  --name=nginxtest  \
  -v nginx-vol:/usr/share/nginx/html:ro  \
  nginx:latest

```

使用命令 `docker container inspect nginxtest` 可以看到 volume 已经正常被挂载。查看 `Mounts` 部分：

```json
"Mounts": [
    {
        "Type": "volume",
        "Name": "nginx-vol",
        "Source": "/var/lib/docker/volumes/nginx-vol/_data",
        "Destination": "/usr/share/nginx/html",
        "Driver": "local",
        "Mode": "",
        "RW": false,
        "Propagation": ""
    }
],

```

停止并移除容器，删除卷命令

```bash

$ docker container stop nginxtest

$ docker container rm nginxtest

$ docker volume rm nginx-vol
```

## Usa a volume driver

当使用命令 `docker volume create` 创建卷 或当启动容器时使用一个 `没有被创建的卷` 时，可以为新创建的卷指定 `volume driver`。

下例中使用 `vieux/sshfs` volume driver 。

### Inital set-up

假设有两个节点，第一个节点为 Docker 宿主机，并可以通过 `ssh` 连接到第二个节点。

在 Docker 宿主机上，安装 `vieux/sshfs` 插件：

```bash
$ docker plugin install --grant-all-permissions vieux/sshfs
```

### Create a volume using a volume driver

下例中使用了 SSH 密码进行授权，如果两个节点之间使用 `密钥` 进行授权的话，密码部分可以省略。

不同的 `volume dirver` 可能有 `0 个或多个` 配置选项，每个选项配置时使用 `-o` 指定。

```bash
$ docker volume create --driver vieux/sshfs  \
  -o sshcmd=test@node2:/home/test  \
  -o password=testpassword  \
  sshvolume

```

### start a container which creates a volume using a volume driver

下例中使用了 SSH 密码进行授权，如果两个节点之间使用 `密钥` 进行授权的话，密码部分可以省略。

不同的 `volume dirver` 可能有 `0 个或多个` 配置选项，每个选项配置时使用 `-o` 指定。

> 如果所使用的 `volume driver` 需要配置选项，那么创建时必须使用 `--mount` ，而不是 `-v / --volume`。

```bash
$ docker run -d  \
  -it  \
  --name sshfs-container  \
  --volume-driver vieux/sshfs  \
  --mount src=sshvolume,dst=/app,volume-opt=sshcmd=test@node2:/home/test,volume-opt=password=testpassword  \
  nginx:latest
```

