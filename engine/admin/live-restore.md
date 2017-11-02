# Docker daemon 宕机期间保持容器存活

默认情况下，当 Docker daemon 退出的时候， 会关闭正在运行的容器。从 `1.12` 开始，可以配置 daemon 参数，使容器在 daemon 进程不可用的时候已经保持运行。改参数降低了在 daemon 崩溃、计划性维护以及升级时容器的停止时间。

> 注意： `live restore` 不支持 windows 容器。但是支持在 Docker for Windows 上跑的 Linux 容器。


## 启用 live restore 选项

有两种方法配置： 

1. 配置 `/etc/docker/daemon.json`，推荐这种方式，但要注意 `json` 格式

```json
{
    "live-restore": true
}
```

发送命令，热加载新配置的参数

```bash
$ kill -SIGHUP $(pidof dockerd)
```

2. 或者给 `dockerd` 传参。

```bash
$ sudo dockerd --live-restore
```

## 升级时的 live restore

`live restore` 支持在 `minor` 版本之间升级时恢复容器与 daemon 之间的连接关系。例如 Docker Engine `1.12.1` 到 `1.12.2`。

如果版本跨越较大的升级， daemon 可能不能恢复与容器之间的连接。如果出现这种情况， daemon 会忽略正在运行的容器，而你必须手动进行管理。

## 重启时的 live restore

只有在 daemon 配置不变的的情况下重启 daemon `live restore` 才会生效。例如， `live restore` 在 daemon 更换了 `bridge ip` 和 `graphdriver` 时不会生效。

> 并不是所有的参数发生变化了 `live restore` 都不会生效。应该处于比较底层的一些参数发生变化了，才不会生效。例如，增加或修改 `registry-mirrors` 就有效。

## live restore 对运行中的容器的影响

docker daemon 进程长时间不活动会对容器产生不良影响。 容器进程会日志写入到一个 FIFO 日志文件中，以供 daemon 恢复之后处理。如果 daemon 长时间不处理这些日志文件， buffer 缓冲去会填满并停止写入新的日志。一个被写满了的日志在有更多空间钱，会阻扰进程。 buffer 默认大小是 `64K`。

刷新 buffer 必须要重启 Docker 。

改变 buffer 大小需要修改 `/proc/sys/fs/pipe-max-size` 的值

## live restore 与 swarm mode

`live store` 与 Docker swarm mode 不兼容。When the Docker Engine runs in swarm mode, the orchestration feature manages tasks and keeps containers running according to a service specification.

## 排错

简单记录一下。

1. 在配置 ` "live-restore" : true ` 之后重启 Docker
1. 不知道在什么时候做测试的时候，开启了 swarm mode，及 `docker swarm init`
1. 由于 `live-restore` 与 swarm mode 冲突，因此重启 Docker 的时候出现以下报错：

```log
Nov 01 10:33:59 instance-4 dockerd[30728]: time="2017-11-01T10:33:59.310839742Z" level=info msg="There are old running containers, the network config will not take affect"
Nov 01 10:33:59 instance-4 dockerd[30728]: time="2017-11-01T10:33:59.322647040Z" level=info msg="Loading containers: done."
Nov 01 10:33:59 instance-4 dockerd[30728]: time="2017-11-01T10:33:59.344132196Z" level=info msg="Docker daemon" commit=afdb6d4 graphdriver(s)=overlay2 version=17.09.0-ce
Nov 01 10:33:59 instance-4 dockerd[30728]: time="2017-11-01T10:33:59.344906513Z" level=fatal msg="Error starting cluster component: --live-restore daemon configuration is incompatible with swarm mode"
```

> 注意： 在使用 `journalctl -xe` 命令查看系统日志时，可能会出现日志过长，一个屏幕不能完全显示的情况。但不会自动换行，这个时候可以使用键盘 `左右` 键调整日志位置。