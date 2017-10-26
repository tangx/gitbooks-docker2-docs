# Start containers automatically

Docker 提供 [restart 策略](https://docs.docker.com/engine/reference/run/#restart-policies---restart) 控制容器在某些情境想是否自动重启。 重启策略保证了通过 `--link` 连接的容器以正确的顺序启动，而不在使用进程管理器控制启动流程。

重启策略与 `dockerd` 的 `--live-restore` 参数不一样。使用 `--live-restore` 允许你在 Docker升级期间保持容器运行，但 **网络** 和 **用户输入** 会被中断。


## Use a restart policy

在使用 `docker run` 命令启动容器时，使用 `--restart` 可以为容器指定重启策略。 `--restart` 的可选值包括以下

| **Flag**         | **描述**                                                |
|------------------|---------------------------------------------------------|
| `no`             | 不要自动重新启动容器。（默认）                             |
| `on-failure`     | 如果由于出现错误而重新启动容器，该错误显示为非零退出代码。   |
| `unless-stopped` | 重新启动容器，除非它被显示停止或Docker本身被停止或重新启动。 |
| `always`         | 如果停止，请务必重新启动容器。                             |

以 redis 容器为例， 除非明确停止或 docker 重启， 容器始终会重启。

```bash
$ docker run -dit --restart unless-stopped redis
```

### Restart policy details

使用重新启动策略时，请记住以下几点：

+ 重新启动策略仅在容器启动成功后生效。在这种情况下，启动成功意味着容器至少持续 10 秒钟，Docker 已经开始监视它。这样可以防止根本不启动的容器进入重启循环。
+ 如果您 **手动** 停止容器，则重新启动策略将被忽略，直到 Docker 守护程序重新启动或容器被手动重新启动。这是防止重新启动循环的另一个尝试。
+ 重新启动策略仅适用于容器。群组服务的重新启动策略配置不同。看 [flags related to service restart](https://docs.docker.com/engine/reference/commandline/service_create/)


## Use a process manager

如果重启策略满足要求，可以使用 **进程管理工具**，例如 `upstart`, `systemd` 或 `supervisor`。

进程管理工具运行在**容器**内，并检查容器内的进程是否启动，如果没有则启动它。这不是 Docker-aware 的，仅监控容器内的进程。
不推荐使用这种方式，因为这是基于系统平台的，不同 Linux 发行版之间。

> **警告**: 不要将 docker **重启策略** 与 **主机级别** 的进程管理工具混用，二者可能冲突。

如果要使用进程管理器，在启动容器或服务时，需要将其配置成为类似手动使用 `docker start` 或 `docker service` 启动容器或服务。o use a process manager, configure it to start your container or service using the same docker start or docker service command you would normally use to start the container manually. 