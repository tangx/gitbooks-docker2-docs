# Dockerfile practice

1. 尽量不是使用 `ADD`, 使用 `COPY` 代替
  + 其实尽量使用 `RUN wget http://path/file.tar.gz ; do something ; rm -f file.tar.gz`

2. 删除没用的临时文件
  + **`ubuntu` 缓存**: 
    + `apt-get install -y --no-install-recommends $packages `
    + `apt-get purge -y --auto-remove $packages `
    + `rm -rf /var/lib/apt/lists/* `
  + **删除临时文件规则**
    + 类似于 `wget` 这样的辅助命令，或者包管理器的缓存
      + 在 `每一步` `RUN` 命令之前安装
      + 在 `每一步` `RUN` 命令之后删除
      + 否则，就会保留在该 `layer` 中

3. 将不变的内容放在前面
  + 前面的镜像内容变了，后面就要重新构建，而不能使用 `cache` 了。

4. `COPY`: 将文件放入镜像的时候会保留当前的文件权限。
  + 因此，类似于 `entrypoint.sh` 这类执行文件，需要在 `build` 之间就赋予 `chmod +x` 的权限


## docker-entrypoint.sh

这是 `redis` 官方的 `entrypoint.sh`。

dockerfile 中， 
+ 结尾的时候将 `ENTRYPOINT` 和 `CMD` 分开了。并且，在 `entrypoint.sh` 结尾使用 `exec $@` 命令。
  + 这样， 用户在不添加任何参数的时候，可以默认执行 `redis-server`
  + 如果使用自定义个 `docker run --rm -it redis sh` 就可以进入命令行界面进行交互

```dockerfile
ENTRYPOINT ["entrypoint.sh"]
CMD ["redis-server"]
```

```bash
#!/bin/sh
set -e

# first arg is `-f` or `--some-option`
# or first arg is `something.conf`
if [ "${1#-}" != "$1" ] || [ "${1%.conf}" != "$1" ]; then
	set -- redis-server "$@"
fi

# allow the container to be started with `--user`
if [ "$1" = 'redis-server' -a "$(id -u)" = '0' ]; then
	chown -R redis .
	exec gosu redis "$0" "$@"
fi

exec "$@"

```

## v2ray

+ [v2ray-alpine](https://github.com/octowhale/gitbooks-docker2-docs/blob/master/998.dockerfiles/001.v2ray/v2ray.alpine.dockerfile)
+ [v2ray-ubuntu](https://github.com/octowhale/gitbooks-docker2-docs/blob/master/998.dockerfiles/001.v2ray/v2ray.ubuntu.dockerfile)

## ubuntu 替换源

+ [ubuntu-soruces](https://github.com/octowhale/gitbooks-docker2-docs/blob/master/998.dockerfiles/002.ubuntu-cn/ubuntu-cn.dockerfile)

## redis 编译安装

+ [redis:ubuntu1604](https://github.com/octowhale/gitbooks-docker2-docs/blob/master/998.dockerfiles/003.redis-ubuntu/redis-ubuntu.dockerfile)

