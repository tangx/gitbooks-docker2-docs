# Embedded DNS server in user-defined networks

DNS lookup for containers connected to user-defined networks works `differently` compared to the containers connected to `default bridge` network.

> 注意： 为了向后兼容， `default bridge` 网络的 DNS 配置没有改变。
>> 看这里 [DNS in default bridge network](https://docs.docker.com/engine/userguide/networking/default_network/configure-dns/) 了解 `default bridge network` 的 DNS 配置

+ 从 1.10 开始， Docker 提供了一个 `内置的 DNS 服务器`， 因此可以为容器设置一个有效的 `name`, `network-alias` 或通过 `link` 指定别名。
+ 在 `container` 内， Docker 如何管理 DNS 配置的具体细节可以从一个 Docker 版本更改为下一个。
+ 因此，不要修改容器内的 `/etc/hosts`, `/etc/resolv.conf`。 同时，使用以下命令进行管理：

|  options | note     |
| :------------- | :------------- |
| `--name=<container_name>`       | 通过 `--name` 指定容器名，可以在 `user-defined` 网络中使用。 `内置 DNS 服务器`维护 `container` 所连接的网络中， `container_name` 与 `container_ip` 之间的映射关系        |
| `--network-alias=<alias_name>`       | 除了 `--name` 中描述的之外，`container` 在连接到 `user-defined network` 时，还可以指定在该网络中使用的 `一个或多个` `别名 alias_name`。 `内置 DNS 服务器`维护网络中的 `alias_name` 与 `container_ip` 的映射关系。可以使用 `docker network connect --alias alias_name1 --alias alias_name2 network_name container_name ` 将运行中的容器加入网络时配置多个别名       |
| `--link=<container_name>:<alias_name>`       | 在使用 `docker run` 时，为 `container_name` 在 `内置 DNS 中` 指定一个额外的 `alias_name` 映射到 `container_ip` 上。 只是当前使用 `--link` 的 container 才能通过 `alias_name` 对目标容器进行访问。 这实现了 `容器1` 中的进程可以在不知道 `容器2` 的名称或IP的情况下连接到 `容器2`。         |
| `--dns=[IP_ADDRESS...]`       | `--dns` 指定了当 `内置 DNS 服务器` 无法解析主机名时，所转发 DNS 请求的 `目标服务器 ip 地址`。 `--dns` IP 地址由 `内置 DNS 服务器` 维护，但是不会更新容器内的 `/etc/resolv.conf` 文件     |
| `--dns-search=DOMAIN...`       | 设置在容器内使用 `裸的不合格的主机名(bare unqualified hostname)` 时搜索的的域名。`--dns-search` 选项由 `内置 DNS 服务器` 维护，但是不会更新容器内的 `/etc/resolv.conf` 文件。 当一个进程尝试访问 `host` 且设置了域名 `example.com` ， DNS 会搜索 `host` 和 `host.example.com` 。     |
| `--dns-opt=OPTION...`       | Sets the options used by DNS resolvers. These options are managed by the embedded DNS server and will not be updated in the container's `/etc/resolv.conf` file. See documentation for `resolv.conf` for a list of valid options.      |

+ 当没有指定 `--dns=<ipaddr>`, `--dns-search=<domain.com>`, `--dns-opt=OPTION...` 时， Docker 使用所在 `宿主机` 的 `/etc/resolv.conf`。
  + 这种情况下， docker daemon 会过滤掉 `宿主机上的 resolv.conf 文件` 中所有的 `localhost ip address` `nameserver` 入口(entry)

+ 过滤是非常有必要的，因为主机的 localhost address 如法从容器中访问。
+ 过滤只是，如果容器中的 `/etc/resolv.conf` 没有其他的 `nameserver` 入口存在，那么daemon会添加 `google dns nameserver`  `(8.8.8.8 and 8.8.4.4)`， 如果启用了 ipv6 ，会添加 `(2001:4860:4860::8888 and 2001:4860:4860::8844)`。

 > 注意： 如果需要访问本机的 `DNS 服务器`，必须将 DNS 进程服务监听在 `non-localhost` ip 上，这样容器才能访问


> 住址：容器中的 `/etc/resolv.conf` 中的 DNS 服务器永远是 `127.0.0.11`。
