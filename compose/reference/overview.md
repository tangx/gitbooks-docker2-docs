# Overview of docker-compose CLI

## Command options overview and help

使用 `docker-compose --help` 查看相关子命令

完整命令 `docker-compose [-f <arg>...] [options] [COMMAND] [ARGS...]` 实现构建管理服务。


## 使用 `-f` 指定一个或多个 compose 文件

使用 `-f` 指定 `compose file` 的 `路径` 与 `文件名`

### Specifying multiple Compose files

`docker-compose` 支持使用 `-f` 同时指定多个 `compose file`。
+ 当指定多个文件时， `docker-compose` 会将做个文件组合成一个文件。
+ `build` 的时候，按照指定文件的顺序进行。
+ 如果前后文件中都对同一个服务进行了配置，如果有冲突参数，那么后者将 `重载 override` 前者的参数。 **其他非冲突参数 `同时生效`**


举个例子：

如命令，指定了两个 `compose file`

```bash
$ docker-compose -f docker-compose.yml -f docker-compose.admin.yml run backup_db
```

两个 `compose file` 都存在 `webapp` 服务

1. `docker-compose.yml` 指定了一个 `webapp` 服务
```yaml
# docker-compose.yml

webapp:
  image: examples/web
  ports:
    - "8000:8000"
  volumes:
    - "/data"
```

2. `docker-compose.admin.yml` 同样指定了一个 `webapp` 服务。 相同 `filed` 的配置，将会被 `重载`。其他没有冲突的地方，则同时生效。

```yaml
# docker-compose.admin.yml

webapp:
  build: .
  environment:
    - DEBUG=1
```

+ `-f -`， 使用 `- (dash)` 表示 `标准输入(stdin)` 作为 `compose file`。当使用 `stdin` 时， 配置中的所有路径都是以 `当前目录` 的 `相对路径`.
+ `-f` 是可选的。 如果没有使用 `-f` ， 那么 `docker-compose` 会搜索 `当前目录` 及 `上级目录` 中搜索 `docker-compose.yml` 和 `docker-compose.override.yml` 文件
  + **目录结构说明**
    + `compose_test` 为一个标准 `docker-compose` 结构目录。所有文件都在 `compose_test` 目录下，可以正常运行。
    + `compose_t3` 为 `compose_test` 的同级目录
    + `compose_t2`, `compose_t4` 为 `compose_test` 的 子、孙 目录
  + **实验结果** : 使用 `docker-compose up` 命令可实现搜索的
    + [ ] ~同级目录： 不行~
    + [x] **子目录: 可以**
    + [x] **孙目录: 可以**

```bash
$ tree -a
.
├── compose_t3/
└── compose_test/
    ├── compose_t2/
    │   └── compose_t4/
    ├── app.py
    ├── docker-compose.v1.yml
    ├── docker-compose.yml
    ├── Dockerfile
    └── requirements.txt
```

+ 搜索路径时，必须存在 `docker-compose.yml` 文件。如果 `docker-compose.override.yml` 同时存在。两个文件会合并为一个文件。
  + 如果存在冲突，`docker-compose.override.yml` 中的配置会 `重载` `docker-compose.yml` 中的。

删除 `docker-compose.yml`， 只保留 `docker-compose.override.yml` 文件。启动时报错。

```bash

$ mv docker-compose.yml docker-compose.yml__

$ ls docker-compose.*
docker-compose.override.yml  docker-compose.v1.yml  docker-compose.yml__

$ docker-compose up -d
ERROR:
        Can not find a suitable configuration file in this directory or any
        parent. Are you in the right directory?

        Supported filenames: docker-compose.yml, docker-compose.yaml
```

同时存在 `docker-compose.yml` 和 `docker-compose.override.yml` 文件。

```bash
$ cat docker-compose.override.yml
version: '3'
services:
  web:
    build: .
    ports:
     - "5003:5000"
    volumes:
     - .:/code
  redis:
    image: "redis:alpine"


$ docker-compose up -d


$ docker container ls
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                                            NAMES
dfa3dce01fa9        redis:alpine        "docker-entrypoint..."   7 seconds ago       Up 6 seconds        6379/tcp                                         composetest_redis_1
34a9f6466e1d        composetest_web     "python app.py"          7 seconds ago       Up 6 seconds        0.0.0.0:5001->5000/tcp, 0.0.0.0:5003->5000/tcp   composetest_web_1


$ curl 127.0.0.1:5001
Hello from Docker! I have been seen 1 times.
$ curl 127.0.0.1:5001
Hello from Docker! I have been seen 2 times.
$ curl 127.0.0.1:5003
Hello from Docker! I have been seen 3 times.
$ curl 127.0.0.1:5003
Hello from Docker! I have been seen 4 times.
$ curl 127.0.0.1:5001
Hello from Docker! I have been seen 5 times.
```

> 注意：
> + 像端口这样的，因为宿主机不能同时监听两个相同的端口，
因此，映射端口是，宿主机端口相同，会报错。
宿主机端口不同，就属于两个不同的配置了，因此，叠加。
> + 类似于 volumes 这类配置，目录 bind 到容器中相同的时候，就产生了 override 的效果。

```bash
$ cp -a ./* ../compose_t3/

$ cat docker-compose.yml
version: '3'
services:
  web:
    build: .
    ports:
     - "5001:5000"
    volumes:
     - .:/code
  redis:
    image: "redis:alpine"

$ cat docker-compose.override2.yml
version: '3'
services:
  web:
    build: .
    ports:
     - "5001:5000"
    volumes:
     - ../compose_t3:/code
  redis:
    image: "redis:alpine"

$ grep return app.py ../compose_t3/app.py
app.py:    return 'Hello from Docker compose_test! I have been seen {} times.\n'.format(count)
../compose_t3/app.py:    return 'Hello from Docker compose_t3! I have been seen {} times.\n'.format(count)

$ docker-compose -f docker-compose.yml  -f docker-compose.override2.yml up -d
Creating network "composetest_default" with the default driver
Creating composetest_web_1 ...
Creating composetest_redis_1 ...
Creating composetest_web_1
Creating composetest_web_1 ... done

$ docker container ls
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES
6ea717e23b74        redis:alpine        "docker-entrypoint..."   9 seconds ago       Up 8 seconds        6379/tcp                 composetest_redis_1
6bec5939d3dd        composetest_web     "python app.py"          9 seconds ago       Up 8 seconds        0.0.0.0:5001->5000/tcp   composetest_web_1
df21e8152501        registry:2          "/entrypoint.sh /e..."   5 days ago          Up 47 hours         0.0.0.0:5000->5000/tcp   registryproxy_mirror_1

## 被 重载 了
$ curl 127.0.0.1:5001
Hello from Docker compose_t3! I have been seen 1 times.
```

### Specifying a path to a single Compose file

使用 `-f` 指定一个非当前目录的 `compose file`
+ 可能使用过 `命令行`
+ 可能是通过 [`COMPOSE_FILE 环境变量`](https://docs.docker.com/compose/reference/envvars/#compose_file) 定义
+ 或者是通过 `系统环境变量` 定义

For an example of using the `-f` option at the command line, suppose you are running the [Compose Rails sample](https://docs.docker.com/compose/rails/), and have a `docker-compose.yml` file in a directory called `sandbox/rails`. You can use a command like `docker-compose pull` to get the `postgress` image for the `db` service from anywhere by using the `-f` flag as follows:

```bash
$ docker-compose -f ~/sandbox/rails/docker-compose.yml pull db
Pulling db (postgres:latest)...
latest: Pulling from library/postgres
ef0380f84d05: Pull complete
50cf91dc1db8: Pull complete
d3add4cd115c: Pull complete
467830d8a616: Pull complete
089b9db7dc57: Pull complete
6fba0a36935c: Pull complete
81ef0e73c953: Pull complete
338a6c4894dc: Pull complete
15853f32f67c: Pull complete
044c83d92898: Pull complete
17301519f133: Pull complete
dcca70822752: Pull complete
cecf11b8ccf3: Pull complete
Digest: sha256:1364924c753d5ff7e2260cd34dc4ba05ebd40ee8193391220be0f9901d4e1651
Status: Downloaded newer image for postgres:latest
```

## Use `-p` to specify a project name

每个配置文件爱你都有个项目命令
+ 通过 `-p` 指定一个 `自定义` 的项目名。
+ 如果不使用 `-p`， `docker-compose` 会使用 `当前目录名称` 作为项目名。
+ 更多信息看 [COMPOSE_PROJECT_NAME 环境变量](https://docs.docker.com/compose/reference/envvars/#compose_project_name)

## Set up environment variables

You can set [environment variables](https://docs.docker.com/compose/reference/envvars/) for various `docker-compose` options, including the `-f` and `-p` flags.

For example,
+ the [COMPOSE_FILE environment variable](https://docs.docker.com/compose/reference/envvars/#compose_file) relates to the `-f` flag,
+ [COMPOSE_PROJECT_NAME environment variable](https://docs.docker.com/compose/reference/envvars/#compose_project_name) relates to the `-p` flag.
+ Also, you can set some of these variables in an [environment file](https://docs.docker.com/compose/env-file/).
