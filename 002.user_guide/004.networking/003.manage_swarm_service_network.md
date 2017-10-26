# Manage swarm service networks

## 数据流量分类

Docker swarm 数据流量分为两个层面：
+ `控制管理流量`(**control and management plane traffic**): 包括 swarm 管理消息，例如加入/退出 swarm 的请求。这些流量总是被加密的。

+ `应用数据流量`(**Application data plane traffic**): 包括容器之间的数据交换，以及容器与外部网络的数据交换。

[更多关于 swarm 网络的信息](https://success.docker.com/Architecture/Docker_Reference_Architecture%3A_Designing_Scalable%2C_Portable_Docker_Container_Networks)


## swarm 的三个重要网络概念

swarm service 三个重要的网络概念:

+ `Overlay network`: 管理参数到 swarm 中的 Docker Daemon 之间的通信。
  + 可以添加 service 到 `一个或多个` `overlay` 网络中, 从而实现 `service to service` 的通信交互。
  + 使用 `overlay network driver` 创建的网络就是 `overlay` 网络

+ `Ingress network`: 是一个特殊的 `overlay` 网络，用于协调 service 节点之间的 `load balancing`
  + 当 `swarm node` 收到一个请求包时，会调用 `IPVS` 模块，经过 `ingress` 网络，将请求包路由到 `service node`
  + `ingress` 网络在 `init` 或 `join` swarm 的时候自动创建。`17.05` 及之后的版本允许用户自定义参数，但一般用不到。

+ `docker_gwbridge`: 是一个 `bridge`网络，用于连接 `overlay` 网络(包括 `ingress` 网络) 到 `docker daemon` 的物理网络。
  + 默认情况下，每个跑服务的容器都是连接到本地 docker dameon 主机的 `docker_gwbridge` 网络上。
  + `docker_gwbridge` 网络在 `init` 或 `join` swarm 的时候自动创建。一般不用去管，但用户可以自定义参数。


## Firewall considerations

swarm 中的 docker daemon 相互通信需通过以下端口：

+ `7946` `TCP/UDP`: 用于容器网络发现
+ `4789` `UDP`: 用于容器 overlay 网络


## 创建 overlay 网络

使用命令 `docker network create -d overlay` 创建

```bash
docker network create -d overlay my-network

```

使用命令 `docker network inspect` 查看网络信息

```bash
$ docker network inspect my-network
[
    {
        "Name": "my-network",
        "Id": "fsf1dmx3i9q75an49z36jycxd",
        "Created": "0001-01-01T00:00:00Z",
        "Scope": "swarm",
        "Driver": "overlay",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": []
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "Containers": null,
        "Options": {
            "com.docker.network.driver.overlay.vxlanid_list": "4097"
        },
        "Labels": null
    }
]
```

+ `driver` 是 `overlay`
+ `scope` 是 `swarm`
  + 在 docker 的其他网络中，还可能是 `local`, `host`, `global`
  + `scope` 表示，只有在相同 `swarm` 中的主机才能访问该网络。

+ 当 service `第一次` 加入到该网络中时，网络的子网和网关会自动被配置。



### Customize an overlay network

使用命令 `docker network create --help` 查看更多配置参数。


### 配置子网和网关

You can configure these when creating a network using the `--subnet` and `--gateway` flags.

```bash
$ docker network create \
  --driver overlay \
  --subnet 10.0.9.0/24 \
  --gateway 10.0.9.99 \
  my-network
```

### CONFIGURE ENCRYPTION OF APPLICATION DATA

Management and control plane data related to a swarm is always encrypted. [Docker swarm mode overlay network security model.](https://docs.docker.com/engine/userguide/networking/overlay-security-model/)


Application data among swarm nodes is not encrypted by default. 在 `docker network create` 的时候使用 `--opt encrypted` 标识可以为 `overlay` 网络加密

+ 在 `vxlan` 层允许 `IPSEC` 加密方式。这种加密对性能造成不可忽视的影响，因此您应该在生产过程中使用该选项之前测试此选项。


## Attach a service to an overlay network

将 `service` 加入 `overlay` 网络中
+ `docker service create --network <network_name>`
+ `docker service update --network-add <network_name>`

```bash
$ docker service create \
  --replicas 3 \
  --name my-web \
  --network my-network \
  nginx
```

`service` 下的容器可以通过 `overlay` 网络中的容器进行通信。

**查看 service 所加入的网络**
+ 使用命令 `docker service ls` 查看有哪些 `service`
+ 使用命令 `docker service ps <service_name>` 查看 `service` 加入了哪些网络。

**查看 network 有哪些 service**
+ `docker network inspect <network_name>` 可以看到当前网络下处于 `running` 的容器。


## Configure service discovery

**Service discovery** is the mechanism Docker uses to `route` a request `from` your service’s external clients `to` an individual swarm node。笼统的说就是包转发：

+ `IPVS` 模式 / `Virtual IP (VIP)`
+ `DNS` 轮询模式 / `DNS Round Robin (DNSRR)`


## Customize the ingress network

Most users `never need` to configure the `ingress` network, but Docker 17.05 and higher allow you to do so.
+ 解决子网冲突
+ 修改 `MTU` 大小

自定义 `ingress` 参数意味着 `删除(removing)` 和 `重建(recreating)`。
+ 如果 `ingress` 关联了 `对外的 service (service which publish ports)`，那首先要将 `对外服务` 全部删除，才能删除 `ingress`。
+ 在删除 `ingress` 之后，重建之前，`不对外的 service (services which do not publish ports)` 依旧正常运行，但无法进行负载均衡。

1. 使用命令 `docker network inspect ingress` 查看 `ingress` 的信息，删除所有连接到 `ingress` 的 `service`。否则之后操作会报错。

2. 使用命令 `docker network rm ingress` 删除 `ingress` 网络。

```bash
$ docker network rm ingress

WARNING! Before removing the routing-mesh network, make sure all the nodes in your swarm run the same docker engine version. Otherwise, removal may not be effective and functionality of newly create ingress networks will be impaired.
Are you sure you want to continue? [y/N]
```

3. 使用 `--ingress` 标识重建一个 `overlay` 网络，并指定需要使用的参数和值。例如设置
+ `MUT` : 1200，
+ 子网: `10.11.0.0/16`，
+ 网关: `10.11.0.2`

```bash
$ docker network create \
  -d overlay \
  --ingress \
  --subnet=10.11.0.0/16 \
  --gateway=10.11.0.2 \
  --opt com.docker.network.mtu=1200 \
  my-ingress
```

> 注意： `ingress` 网络只能有一个，但是网络名可以设置为任何值。

4. 重启第一步停掉的服务。


## Customize the docker_gwbridge

The `docker_gwbridge` is a` virtual bridge` that connects the `overlay networks` (**including the ingress network**) to an `individual` Docker daemon’s `physical` network.

+ `docker_gwbridge` 不是 `docker device`
+ `docker_gwbridge` 存在于 `docker 主机` 的 `内核` 中

如果想要自定义 `docker_gwbridge` 的参数，`docker host 不能处于 swarm 中`
+ 必须在 docker 主机加入 swarm 之前
+ 或暂时将主机从 swarm 中删除

You need to have the `brctl` application installed on your operating system in order to delete an existing bridge. The package name is `bridge-utils`.

0. install `brctl`

```bash
# 如果不存在 brctl ，ubuntu 16.04 使用命令安装
sudo apt-get install bridge-utils
```

1. stop docker

```bash
$ sudo systemctl stop docker
Warning: Stopping docker.service, but it can still be activated by:
  docker.socket
```

2. 使用 `brctl show <network_device_name>` 查看名为 `docker_gwbridge` 的 `桥接设备(bridge device)` 是否存在。如存在，则使用 `brctl delbr <network_device_name>` 删除

```bash
$ sudo brctl show docker_gwbridge
bridge name	bridge id		STP enabled	interfaces
docker_gwbridge		8000.0242b9cc96b2	no		

# 网卡删除失败
$ sudo brctl delbr docker_gwbridge
bridge docker_gwbridge is still up; can not delete it

# 关闭网卡
$ sudo ifconfig docker_gwbridge down

# 重新删除
$ sudo brctl delbr docker_gwbridge

```

> 注意：删除 `docker_gwbridge` 网卡之前，需要先使用命令 `sudo ifocnfig docker_gwbridge down` 关闭它，否则会报错
>> https://unix.stackexchange.com/questions/62751/cannot-delete-bridge-bridge-br0-is-still-up-cant-delete-it

3. 启动 docker 但是不要 `join` 或 `init` swarm

```bash
$ sudo systemctl start docker
```

4. 使用自定义参数重新创建 `docker_gwbridge`
+ 更多自定义参数 [bridge driver options](https://docs.docker.com/engine/reference/commandline/network_create/#bridge-driver-options)

```bash
$ docker network create \
--subnet 10.11.0.0/16 \
--opt com.docker.network.bridge.name=docker_gwbridge \
--opt com.docker.network.bridge.enable_icc=false \
docker_gwbridge
```

> 注意：ubuntu 16.04 /docker 17.06 中，如果 `docker network ls` 中如果存在 `docker_gwbridge`，不使用 `docker network rm docker_gwbridge` 删除网络。即使按照之前的步骤，使用 `sudo btctl delbr <network_device_name>` 删除网卡设备，之后启动 docker 时已经会自动重建 `docker_gwbridge`。 前后过程可以通过 `ip a|grep docker_gwbridge` 查看


> 注意：
>> 在 ubuntu16.04 / docker 17.06 中，实际操作应该如下

0. 不用安装 `bridge-utils` 也不同停止 `docker daemon`

1. 使用命令 `docker network rm docker_gwbridge` 删除网络，与此同时，系统对应的 `docker_gwbridge` 设备也会被删除。

2. 使用 `docker network create ...` 命令创建自定义网卡即可。


## Use a separate interface for control and data traffic

By `default`, all swarm traffic is sent over the `same interface`, including `control and management` traffic for maintaining the swarm itself and `data traffic` to and from the service containers.

In Docker `17.06 and higher`, it is possible to `separate` this traffic by passing the `--datapath-addr` flag when `initializing` or `joining` the swarm.

**多网卡时**

+ `--advertise-addr`: 必须被指定
  + Traffic about `joining`, `leaving`, and `managing` the swarm will be sent over the `--advertise-addr interface`
+ `--datapath-addr`: 如果不指定，则与 `--advertise-addr` 同
  + traffic `among a service’s containers` will be sent over the `--datapath-addr interface`
+ `--advertise-addr` 和 `--datapath-addr` 的值，可以是
  + `ip 地址`: `192.168.1.1`, `--advertise-addr 192.168.1.1`
  + `接口名称`: `enp0s3`, `--datapath-addr enp0s3`

举个例子：

**初始化 swarm**

+ `eth0` 做管理， `eth1` 做数据交换
+ `eth0`: `10.0.0.1`
+ `enp0s8`: `192.168.0.1`

```bash
$ docker swarm init --advertise-addr 10.0.2.15 --data-path-addr enp0s8

Swarm initialized: current node (tejhf9eji9eaw3m268rjx94cw) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-token-string 10.0.2.15:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.

```

**加入 swarm**

+ swarm manager: `192.168.99.100:2377`
+ `eth0` 做管理，`eth1` 做数据交换

```bash
$ docker swarm join \
  --token SWMTKN-1-token-string \
  --advertise-addr eth0 \
  --datapath-addr eth1 \
  192.168.99.100:2377
```

## swarm join-token 与 join

### join-token

可以通过命令 `docker swarm join-token` 查询 swarm-token

```bash
$ docker swarm join-token --help

Usage:	docker swarm join-token [OPTIONS] (worker|manager)

Manage join tokens

Options:
      --help     Print usage
  -q, --quiet    Only display token
      --rotate   更新token(Rotate join token)

# 查询 token
$ docker swarm join-token worker
$ docker swarm join-token manager
# 更新 token
$ docker swarm join-token --rotate worker
$ docker swarm join-token --rotate worker
```

### join

使用 `docker swarm join --token <token_string> <manager ip:port>` 命令可以加入 swarm。
+ 根据 `<token_string>` 的值不同，加入后的角色(`worker`/`manager`) 也不同。
+ `<token_string>` 由 `docker swarm join-token <worker|manager>` 命令生成

```bash

$ docker swarm join --help

Usage:	docker swarm join [OPTIONS] HOST:PORT

Join a swarm as a node and/or manager

Options:
      --advertise-addr string   Advertised address (format: <ip|interface>[:port])
      --availability string     Availability of the node ("active"|"pause"|"drain") (default "active")
      --data-path-addr string   Address or interface to use for data path traffic (format: <ip|interface>)
      --help                    Print usage
      --listen-addr node-addr   Listen address (format: <ip|interface>[:port]) (default 0.0.0.0:2377)
      --token string            Token for entry into the swarm

```
