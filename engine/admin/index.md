# Docker daemon 的配置和排错

本文教你如何定制 `dockerd` 的参数。

## Start the daemon using operating system utilities

+ [安装 docker](https://docs.docker.com/engine/installation/)
+ [配置开机启动](https://docs.docker.com/engine/installation/linux/linux-postinstall/#configure-docker-to-start-on-boot)


## Start the daemon manually

出于 DEBUG 的目的，可以使用 `dockerd` 手工启动 Docker服务。如果非管理员，需要使用 `sudo` 命令。当通过这种方式启动 Docker 后， Docker 运行在前台，并直接在控制端上打印日志。

```bash
$ dockerd

INFO[0000] +job init_networkdriver()
INFO[0000] +job serveapi(unix:///var/run/docker.sock)
INFO[0000] Listening for HTTP on unix (/var/run/docker.sock)
...
...

```

按 `Ctrl+C` 停止 Docker


## Configure the Docker daemon

Docker daemon 包含了很多参数，
+ 手工启动的时候，你可以通过给 `dockerd` 传参
+ 还可以在 `daemon.json` 中配置

当然，更推荐使用 `daemon.json` 这种方式。

查看 [dockerd](https://docs.docker.com/engine/reference/commandline/dockerd/) 获得更多配置选项。

手动传参启动方式：

```bash
$ dockerd -D --tls=true --tlscert=/var/docker/server.pem --tlskey=/var/docker/serverkey.pem -H tcp://192.168.59.3:2376
```

+ `-D` : debugging
+ `-tls`: 启用 TLS 证书
  + `--tlscert`, `--tlskey` 指定证书
+ `-H`: 指定 daemon 监听的 `网络接口`

更好的方式是所有参数放入 `daemon.json` 中，并重启 Docker daemon。这种方式适用于各种 Docker平台。 例如将上面的参数放 `daemon.json` 中：

```json
{
  "debug": true,
  "tls": true,
  "tlscert": "/var/docker/server.pem",
  "tlskey": "/var/docker/serverkey.pem",
  "hosts": ["tcp://192.168.59.3:2376"]
}
```

Docker 文档中有许多具体的配置选项。例如：

+ [Automatic start contaienr](https://docs.docker.com/engine/admin/host_integration/)
+ [Limit a container’s resources](https://docs.docker.com/engine/admin/resource_constraints/)
+ [Configure storage drivers](https://docs.docker.com/engine/userguide/storagedriver/)
+ [Container security](https://docs.docker.com/engine/security/)


## Troubleshoot the daemon

开启 debugging 模式可以帮助排错。如果 docker daemon 完全不响应，您还 可以通过个 docker daemon 发送信号 `SIGUSR` ， [强制将所有线程的堆栈信息](#force-a-full-stack-trace-to-be-logged) 添加到守护程序日志中。

### Out Of Memory Exceptions (OOME)

如果你的容器尝试使用的内存超过了系统上限，可能会触发 `Out Of Memory Exception (OOME)`， 并且**某个容器**或**Docker daemon**可能会被 `kernel OOM killer` 关闭。为了防止这种情况的发生，确保容器主机有足够的内存，另外，查阅 [Understand the risks of running out of memory.](https://docs.docker.com/engine/admin/resource_constraints/#understand-the-risks-of-running-out-of-memory)

### Read the logs

**排错，要善于看日志**， 不同的系统，日志存储的位置不一样。

| **Operating system**  | **Location**                                                                           |
|-----------------------|----------------------------------------------------------------------------------------|
| RHEL, Oracle Linux    | `/var/log/messages`                                                                      |
| Debian                | `/var/log/daemon.log`                                                                    |
| Ubuntu 16.04+, CentOS | Use the command `journalctl -u docker.service`                                           |
| Ubuntu 14.10-         | `/var/log/upstart/docker.log`                                                            |
| macOS                 | `~/Library/Containers/com.docker.docker/Data/com.docker.driver.amd64-linux/console-ring` |
| Windows               | `AppData\Local`                                                                          |

### Enable debugging

有两种方式可以开启 debugging 模式。

其一，为 `dockerd` 传参 `-D`。

其二，为 `daemon.json` 增加 `"debug": true` 字段。这种方式适用于 Docker 各个平台。

1. 编辑 `/etc/docker/daemon.json`。 如果是 **Windows** 或 **MacOS**，不能直接编辑，需要在 **Preferences / Daemon / Advanced** 中处理。

2. 如果文件为空， `daemon.json` 如下：

```json
{
  "debug": true
}
```
如果文件存在，则直接添加 `"debug": true` 字段，注意换行出的 `逗号`。另外，同时可以指定 `log-level` 等级； 默认为 `info`；有效值为 `debug`, `info`, `warm`, `error`, `fatal`。

3. 如果是 Linux 主机， `dockerd` 发送 `HUP` 信号， reload 配置。如果是 Windows 主机，重启 docker。

```bash
$ sudo kill -SIGHUP $(pidof dockerd)
```

### Force a stack trace to be logged

如果 daemon 无响应，你可以向 daemon 发送 `SIGUSR1` 信号强制将所有堆栈信息保存下来。

+ **Linux**:
```bash
$ sudo kill -SIGUSR1 $(pidof dockerd)
```

+ **Windows Server**:
下载 [docker-signal]https://github.com/jhowardmsft/docker-signal)，使用参数 `--pid=<PID of daemon` 执行命令。

这样便会强制保存堆栈信息，但不会停止 daemon。 Daemon 的日志中会保存上述堆栈信息，或记录保存上述堆栈信息文件的路径。

The daemon will continue operating after handling the `SIGUSR1` signal and dumping the stack traces to the log. The stack traces can be used to determine the state of all goroutines and threads within the daemon.

### View stack traces

Docker daemon 日志可以通过以下方式查看：

+ Linux 系统使用 `systemctl` : `journalctl -u docker.service`
+ 早期的 Linux系统 : `/var/log/message`, `/var/log/daemon.log`, `/var/log/docker.log`
+ Windows Server 的 DockerEE : `Get-EventLog -LogName Application -Source Docker -After (Get-Date).AddMinutes(-5) | Sort-Object Time`

> **注意**: 在 windows 或 MacOS 上不能手动生成堆栈信息。但是，可以通过 Docker 任务栏中 **Diagnose and feddback** 向 Docker 团队反馈你的问题。

Docker 日志如下：

```
...goroutine stacks written to /var/run/docker/goroutine-stacks-2017-06-02T193336z.log
...daemon datastructure dump written to /var/run/docker/daemon-data-2017-06-02T193336z.log
```

上述信息展示了 Docker 将堆栈信息保存的路径。


## Check whether Docker is running

+ 使用命令 `docker info` 来检查 Docker 是否正在运行。

+ 你还可以使用操作系统指令来检查，例如 `sudo systemctl is-active docker` 或 `sudo status docker` 或 `sudo service docker status` 或使用 Windows 工具

+ 当然，你还可以使用 `ps` 或 `top` 查看 `dockerd` 进程是否存在。
