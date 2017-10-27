# Use tmpfs mounts

`volume` 和 `bind mounts` 都是挂载到容器的文件系统中，且内容保存在宿主机上。

在某些情况下，你可能不希望将容器数据放在宿主机上，也不想放在容器的 `writable layer` 中，或者处于性能或安全考虑，或者数据涉及非持久性应用程序状态。

使用 `tmpfs` 挂载，将数据写入 `内存` 中（内存小时，写入 `swap` 中）。
  + 当容器停止后， `tmpfs` mount 被删除。
  + 当容器被 commit 是， `tmpfs` mount 不会被保存。

![004.types-of-mounts-tmpfs.png](004.types-of-mounts-tmpfs.png)


## 选 `--tmpfs` 还是 `--mount`

+ 最开始， `--tmpfs` 只用于 standalone 容器， 而 `--mount` 用于 `swarm services`。 然而从 `17.06` 开始， `--mount` 也可以用于 standalone 容器了。

+ `--mount` 可读性更高，意义更明确。
  + `-v` 将所有参数组合成一个；而 `--mount` 将他们分开

> 建议： 新人用 `--mount`；老鸟可能更熟悉 `-v / --volume` ，但建议使用 `--mount`


+ `--tmpfs`: 挂载 `tmpfs mount`，但不能指定任何配置，只能用于 standalone 容器。
+ `--mount`: 由多个 `<key>=<value>` 组成。
  + `type`: 指定类型；可选值为 `bind`, `volume`, `tmpfs`。此处为 `tmpfs`。
  + `destination / dst / target`: 指定挂载点。
  + `tmpfs-type` 和 `tmpfs-mode`: 看下面的介绍

### Differences between `--tmpfs` and `--mount` behavior

+ `--tmpfs` 不允许指定任何配置。
+ `--tmpfs` 不能用于 `swarm services`。必须使用 `--mount`。

## Limitations of tmpfs containers

+ `tmpfs` mounts 不能再容器间共享。
+ `tmpfs` mounts 只能作用于 linux 容器，不支持 windows 容器。

## Use a tmpfs mount in a container

容器中使用 `tmpfs` mounts 时，可以使用 `--tmpfs` 或 `--mount type=tmpfs`。 `tmpfs` 没有 `source` 选项。

下例中为 nginx 容器创建了一个 `tmpfs` mount 并挂载到了 `/app` 目录。

**`--mount`**:

```bash
$ docker run -d  \
  -it  \
  --name tmptest  \
  --mount type=tmpfs,dst=/app  \
  nginx:latest
```

**`--tmpfs`**:

```bash
$ docker run -d  \
  -it  \
  --tmpfs /app  \
  nginx:latest

```

使用命令 `docker container inspect tmptest` 查看容器信息，并查看 `Mounts` 部分。

```json
"Tmpfs": {
    "/app": ""
},

```

删除容器

```bash
$ docker container stop tmptest

$ docker container rm tmptest
```

## Specify tmpfs options

`tmpfs` mounts 有两个配置选项；两个选项都不是必须的。如果要使用这两个选项，必须使用 `--mount` 而不是 `--tmpfs`。

| **Option** | **Description** |
| :---- | :---- |
| `tmpfs-size` | 设置 `tmpfs mounts` 的大小，单位 `bytes`。默认 `无限制` |
| `tmpfs-mode` | 设置 tmpfs 的 `8 进制 rwx` 权限。 例如 `700` 或 `0770`。 默认为 `1777` 或 `world-writable`。|

下例中设置 `tmpfs-mode` 为 `1770`。 因此在容器中，非 `world-readable`。

```bash
$ docker run -d  \
  -it  \
  --name tmptest  \
  --mount type=tmpfs,dst=/app,tmpfs-mode=1770  \
  nginx:latest
```