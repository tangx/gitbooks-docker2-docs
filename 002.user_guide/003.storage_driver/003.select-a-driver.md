# 选择合适的 storage driver

Docker 支持多种不同的 storage driver, 使用 `pluggable architecture`。

+ `storage driver` 决定了如何 `保存` 和 `管理` `image` 和 `container`

选择合适的 `storage driver`，以下是几个比较重要的参考因素：

+ 如果系统内核支持多种 `storage driver`，在没有指定 `storage driver` 的情况下，系统会按照以下优先级选择：
  + `aufs`: 默认。 `最老` 的 `storage dirver` ，但是并不是所有系统都支持。
  + `btrfs`, `zfs`: 使用配置最少的 。这些都依赖于 `文件系统(backing system`) 正确配置
  + 否则，尝试在最常见的情况下使用具有最佳整体性能和稳定性的 `storage driver` 。
    + `overlay2` 最佳，其次是 `overlay`。这两者都不需要外配置。
    + `devicemapper` 再次，但要求 `direct-lvm` 的 **生产环境(production environments)**，因为 `loopback-lvm` 在无配置的情况下，性能很低
  + Docker [源码](https://github.com/moby/moby/blob/v17.03.1-ce/daemon/graphdriver/driver_linux.go#L54-L63)决定了 `storage driver` 的顺序。

+ `storage dirver` 可选列表依赖于 `docker 版本` 和 `系统版本`
  + `aufs` : Ubuntu and Debian
  + `btrfs`: SLES, 只支持 Docker EE
  + [Support storage drivers per Linux distribution](#supported-storage-drivers-per-linux-distribution)

+ 部分 `storage driver` 对 `文件系统` 有要求。
  + [Supported backing filesystems](https://docs.docker.com/engine/userguide/storagedriver/selectadriver/#supported-backing-filesystems)

+ 结合以上限制，根据业务工作量选择合适的 `storage driver`。
  + [other considerations](https://docs.docker.com/engine/userguide/storagedriver/selectadriver/#other-considerations)

## Supported storage drivers per Linux distribution

不推荐使用需要 `禁用(disable)` 安全策略的 `storage driver`

+ 在 `CentOS` 上使用 `overlay` or `overlay2` 需要禁用 `selinux`

### Docker EE and CS-Engine

看 [Product compatibility matrix](https://success.docker.com/Policies/Compatibility_Matrix)

### Docker CE

In general, the following configurations work on recent versions of the Linux distribution

| Linux distribution     | Recommended storage drivers     |
| :------------- | :------------- |
| Docker CE on Ubuntu      | `aufs`, `devicemapper`, `overlay2` (Ubuntu 14.04.4 or later, 16.04 or later), `overlay`, `zfs`, `vfs`       |
| Docker CE on Debian      | `aufs`, `devicemapper`, `overlay2` (Debian Stretch), `overlay`, `vfs`       |
| Docker CE on CentOS       | `devicemapper`, `vfs`       |
| Docker CE on Fedora      | `devicemapper`, `overlay2` (Fedora 26 or later, experimental), `overlay` (experimental), `vfs`       |


+ 犹豫的时候，最好选用支持 `overlay2` 的 linux 系统。
+ 使用 `Docker volume` 代替在 `writable layer` 上进行频繁的写入。
+ `vfs` 不要选。除非你清楚的知道自己在做什么 [its performance and storage characteristics and limitations.](https://docs.docker.com/engine/userguide/storagedriver/vfs-driver/)

> 注意：用常用的 `storage drive` 才能方便的排错。


### Docker for Mac and Docker for Windows

Docker for Mac and Docker for Windows are intended for development, rather than production. Modifying the storage driver on these platforms is not supported.

## Supported backing filesystems

对 Docker 而言， `backing filesystem` 就是 `/var/lib/docker/` 目录`所在`的**`文件系统格式`**。

一些 `storage dirver` 只能在特定的 `backing filesystem` 上工作

| **Storage Driver** | **Supported backing filesystems** |
| :--: | :--: |
| `overlay`, `overlay2` | `ext4`, `xfs` |
| `aufs` | `ext4`, `xfs` |
| `devicemapper` | `direct-lvm` |
| `btrfs` | `btrfs` |
| `zfs` | `zfs` |


## Other considerations

### 根据工作量选择

不同 `storage driver` 有不同的 `特性` 。

+ `aufs`, `overlay`, `overlay2` 更适合操作 `文件(file)` 而不是 `block` 。 使用 `内存` 更有效率，但大量写入操作会使 `container's writable layer` 快速增大。
+ `devicemapper`, `btrfs`, `zfs` 更适合 `block` 操作。比如用做 `docker volumes`
+ For `lots of small writes` or `containers with many layers` or `deep filesystems`, `overlay` 比 `overlay2` 更合适.
+ `btrfs` 和 `zfs` 对内存需求很高
+ `zfs` is a good choice for `high-density workloads` such as PaaS.


### Shared storage systems and the storage driver

If your enterprise uses `SAN`, `NAS`, `hardware RAID`, or other shared storage systems, they may provide `high availability`, `increased performance`, `thin provisioning`, `deduplication`, and `compression`. In many cases, Docker can `work on top of` these storage systems, but Docker does `not closely` integrate(整合,一体化) with them.

+ 每个 `docker storage driver` 都基于 `linux filesystem 或 volume manager`。 
+ 使用时，确保所选的 `dockter storage dirver` 在所在 `shared storage system` 上是最好的。

### Stability

出于稳定性考虑，一般而言 `aufs`, `overlay` 和 `devicemapper` 优先级最高。


### Experience and expertise

出于 `maintaining (维护)` 方便考虑。


### Test with your own workloads

测试工作量后在决定。


## Check and set your current storage driver

> 重要： 有些 `storage driver`， 例如 `devicemapper`, `btrfs`, `zfs` 需要对系统进行额外的配置。


使用 `docker info` 命令查看当前 `Storage driver` 信息

```bash 
docker info

Containers: 0
Images: 0
Storage Driver: overlay
 Backing Filesystem: extfs

...
<output truncated>
```

+ 在 Docker 启动命令中，使用 `--storage-driver` 标志可以设置 `storage driver`
+ (**推荐**) 配置 `daemon.json`
  + Linux: `/etc/docker/daemon.json`
  + Windows: `C:\programData\docker\config\daemon.json`

例如，指定 `devicemapper` driver。
```json
{
  "storage-driver": "devicemapper"
}
```

> 注意： 在 `ubuntu 16.04.3 x86_64 / docker-ce 17.06` 通过 `daemon.json` 配置 `registry-mirrors` 不成功。
>> 不知道 `storage driver` 是否可以通过 `daemon` 配置，未测试。


