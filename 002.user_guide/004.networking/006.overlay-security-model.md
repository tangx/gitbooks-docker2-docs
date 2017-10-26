# swarm mode overlay network security model

+ Overlay networking for Docker Engine `swarm mode` `comes secure out of the box`.
+ swarm nodes 交换 `overlay` 网络信息使用 `八卦协议(gossip protcol)` 。
+ 在 `GCM` 模式下，节点使用 AES 算法对所交换的信息进行 `加密` 和 `解密` 。
+ `Manager Node` 每 `12小时` 更换一次 `gossip` 的加密密钥。

+ 在 `overlay` 网络中，你可以在不同 `node` 的容器上加密数据。
  + 创建网络时，使用 `--opt encrypted` 标识启用加密。

```bash
$ docker network create --opt encrypted --driver overlay my-multi-host-network

dt0zvqn0saezzinc8a5g4worx
```

+ 启用 `overlay` 网络加密之后， docker 在根据任务调度，会在执行 service 任务的 `node` 上与 `overlay` 网络之间创建一个 `IPSEC` 通道。参考 (IPVS 的 TUN 模式)
  + 在 `GCM` 模式下，这些 `tunnel` 同样适用 `AES` 算法加密
  + `manager node` 每 `12小时` 更换一次 `key`


> 警告：**不要将 windows 节点加入到 `加密`后的 overlay 网络中** 。
>> `overlay 网络加密` 不支持 windows。 如果尝试将 windows 节点加入加密后的 overlay 网络时， `不会被检测到` 但 `节点不能通信`

## Swarm mode overlay networks and unmanaged containers

+ 由于 `swarm mode` 的 `overlay` 网络中， `manager nodes` 使用 `加密密钥` 对 `gossip communication` 进行了加密，只有 swarm 中执行任务的的容器才拥有该 `密钥` 。
  + 因此，在 swarm mode 外启动的容器(非托管容器) 不能加入到该 `overlay` 网络中。

举个例子:

```bash
$ docker run --network my-multi-host-network nginx

docker: Error response from daemon: swarm-scoped network
(my-multi-host-network) is not compatible with `docker create` or `docker
run`. This network can only be used by a docker service.
```

**为了解决这个问题，可以将非托管容器迁移到托管服务中**

举个例子：使用镜像 `my-image` 创建一个服务

```bash
$ docker service create --network my-multi-host-network my-image

# 查看当前服务
$ docker service ls

```

+ 因为 `swarm mode` 是一个可选功能， Docker Engine 向后兼容。你可以继续使用第三方 `key-value store` 创建 `overlay` 网络。但强烈建议使用 `swarm mode`。
+ 除了本文中描述的安全性好处之外，`swarm mode` 还可以利用新的服务API提供的更大的可扩展性。
