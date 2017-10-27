# Use bind mounts

+ `bind mounts` 在 docker 早期版本就已经在使用了。
+ `bind mounts` 较 `volumes` 而言，会有一些功能限制。
+ 当使用 `bind mounts` 时， *宿主机*中的 `已存在的文件或目录` 被挂载到容器中。
+ 在挂载时，使用 `绝对路径` 或 `相对路径` 指定所挂载的文件或目录。

```bash
$ docker run --rm -v python3:/root/python3/ --name nginx_test -d  nginx 
bfd85451aa6e96e304341c8c80ac16af64482d793a2b00e866f0bae06ec2e83f
```

+ 与 `bind mounts` 不同，当创建一个 `volume` 时，会在宿主机的 `Docker’s storage directory` 创建一个新文件夹，并有 docker 管理其内容。


+ 容器中的挂载点在不需要预先存在。
  + 如果挂载点不存在，则会自动创建。
  + 如果挂载点存在且不会空，那么挂载点中的内容将被隐藏。（参考 linux mount）
+ `bind mount` 在研发阶段非常有效，但它们依赖于具有特定目录结构的主机的文件系统。
+ 如果要发布一个 docker 应用，应该使用 `命名卷`.
+ docker CLI 命令不能直接作用于 `bind mounts`。

![003.types-of-mounts-bind.png](003.types-of-mounts-bind.png)


## 用 `-v` 还是 `--mount`

+ 最开始， `-v` 或 `--volume` 用于 `standalone` 容器， 而 `--mount` 用于 `swarm services`；但从 `17.06` 开始 `--mount` 也可以用于 `standalone` 容器了。
+ `--mount` 可读性更高，意义更明确。
  + `-v` 将所有参数组合成一个；而 `--mount` 将他们分开

> 建议： 新人用 `--mount`；老鸟可能更熟悉 `-v / --volume` ，但建议使用 `--mount`


+ `-v / --volume`: 有三个部分组成，以 冒号 `:` 分隔。 `-v local_path:mount_point:flag`
  + local_path ：宿主机文件或目录的 `绝对路径或相对路径`。
  + mount_point : 容器中的挂载点。
  + flag: 可选部分。如果有个多，使用 **逗号** `,` 分隔。例如 `ro`, `consistent`, `delegated`, `cached`, `z`, `Z`。 

+ `--mount`: 以多个 `<key>=<value>` 对组成，使用 **逗号** `,` 分隔。虽然 `--mount` 比 `-v` 更冗长，但是每个字段意义更明确，而且字段之间没有顺序限制。
  + `type` : 挂载类型 `bind`, `volume`, `tmpfs`， 此处为 `bind`。
  + `source / src` : 宿主机文件或目录的 `绝对路径`。
  + `destination / dst/ target`: 容器中的挂载点
  + `readonly`: 只读挂载
  + `bind-propagation`: 如果存在，则修改 bind 的传播方式。可选值为 `rprivate`, `private`, `rshared`, `shared`, `rslave`, `slave`。
  + `consistency`: 如果存在，可选值为 `consistent`, `delegated`, `cached`。该选项仅对 `Docker for Mac` 有效，其他平台将会被忽略。
  + `--mount` 不支持 `z` 或 `Z` 修改 selinux 标签。


**`--mount` 的 `src` 不支持相对路径**: 
```bash
$ docker run -d --rm --name nginx_test --mount type=bind,src=python3,dst=/root/python3 nginx
docker: Error response from daemon: invalid mount config for type "bind": invalid mount path: 'python3' mount path must be absolute.
See 'docker run --help'.

$ docker run -d --rm --name nginx_test --mount type=bind,src=/home/python3,dst=/root/python3 nginx
880c35d9d2cfb01db921030451ff2a4f0b6da7baf2b1f5b8ce3fe4da2985ed8e
```

### Differences between -v and --mount behavior

Because the `-v` and `--volume` flags have been a part of Docker for a long time, their behavior cannot be changed. This means that there is one behavior that is different between `-v` and `--mount`.

+ 使用 `-v / --volume` 挂载时，如果 `source` 不存在，docker 会在指定路径创建一个 `目录` 作为 `source`。
+ 使用 `--mount` 挂载是，如果 `source` 不存在，docker 不会创建任何东西，并报错。


## Start a container with a bind mount

**`--mount`**:

```bash
$ docker run -d \
  -it \
  --name devtest \
  --mount type=bind,source="$(pwd)"/target,target=/app \
  nginx:latest
```

**`-v`**:

```bash
$ docker run -d \
  -it \
  --name devtest \
  -v "$(pwd)"/target:/app \
  nginx:latest
```

使用命令 `docker container inspect devtest` 验证挂载是否正确，并查看 `Mounts` 部分：

```json
"Mounts": [
    {
        "Type": "bind",
        "Source": "/tmp/source/target",
        "Destination": "/app",
        "Mode": "",
        "RW": true,
        "Propagation": "rprivate"
    }
],
```

结果显示， 挂载方式为 `bind`, `source` 和 `Destination` 位置正确，挂载方式为 `read-write`, 传播方式为 `rprivate`。

关闭容器：

```bash
$ docker container stop devtest

$ docker container rm devtest

```

### Mounting into a non-empty directory on the container

使用 `bind mounts` 挂载本地目录到容器中的一个非空目录时， 容器中的目录内容将会被隐藏。

这个非常适合用于研发阶段，经常变动。


下例非常极端，把宿主机的中的 `/tmp` 目录挂载到了容器中的 `/usr` 目录。


**`--mount`**:

```bash
$ docker run -d \
  -it \
  --name broken-container \
  --mount type=bind,source=/tmp,target=/usr \
  nginx:latest

docker: Error response from daemon: oci runtime error: container_linux.go:262:
starting container process caused "exec: \"nginx\": executable file not found in $PATH".


```

**`-v`**:

```bash
$ docker run -d \
  -it \
  --name broken-container \
  -v /tmp:/usr \
  nginx:latest

docker: Error response from daemon: oci runtime error: container_linux.go:262:
starting container process caused "exec: \"nginx\": executable file not found in $PATH".
```

上例中，容器创建了，但是没有被启动。使用命令删除

```bash
$ docker container rm broken-container
```

## Use a read-only bind mount

当需要被挂在的目录为 `只读` 时：
+ `-v`: `ro`
+ `--mount`: `readonly`

**`--mount`**:

```bash
$ docker run -d \
  -it \
  --name devtest \
  --mount type=bind,source="$(pwd)"/target,target=/app,readonly \
  nginx:latest
```

**`-v`**:

```bash
$ docker run -d \
  -it \
  --name devtest \
  -v "$(pwd)"/target:/app:ro \
  nginx:latest
```

使用命令 `docker container inspect devtest` 查看容器信息，并查看 `Mounts` 部分

```json
"Mounts": [
    {
        "Type": "bind",
        "Source": "/tmp/source/target",
        "Destination": "/app",
        "Mode": "ro",
        "RW": false,
        "Propagation": "rprivate"
    }
],

```

关闭容器

```bash
$ docker container stop devtest

$ docker container rm devtest
```

## Configure bind propagation

+ 在 `bind mount` 和 `volumes` 中，`Bind propagation` 默认为 `rprivate`。
+ 只有 `linux` 上能为 `bind mounts` 配置 `bind-propagation` 的值。
+ `bind propagation` 是一个高阶功能，大部分人不会配置到这部分。


> 更多信息，直接看官方文档 https://docs.docker.com/engine/admin/volumes/bind-mounts/#configure-bind-propagation


## Configure the selinux label

如果使用 `selinux`， 你可以使用 `z` 或 `Z` 来修改 mount 到容器中的主机文件或目录的 selinux 标签。并且可能会在 Docker 的范围之外产生后果。
  + `z`：`bind mount` 的内容可以在多个容器之间共享
  + `Z`: `bind mount` 的内容是 `私有的` ，不能被共享。  

在 **极端情况下**，如果挂载宿主机的 `/home` 或 `/usr/` 到容器中，并使用了 `Z`， 那么会导致宿主机无法操作，且你需要手动 `relabel` 这些宿主机文件。

> `z` 或 `Z` 不能搭配 `--mount` 使用

This example sets the `z` option to specify that multiple containers can share the bind mount’s contents:

```bash
$ docker run -d \
  -it \
  --name devtest \
  -v "$(pwd)"/target:/app:z \
  nginx:latest
```

## Configure mount consistency for macOS


> 只作用于 MacOS ，自己看官网 https://docs.docker.com/engine/admin/volumes/bind-mounts/#configure-mount-consistency-for-macos

