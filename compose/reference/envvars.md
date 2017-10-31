# Compose CLI environment variables

Several environment variables are available for you to configure the Docker Compose command-line behaviour.

Variables starting with DOCKER_ are the same as those used to configure the Docker command-line client.

## COMPOSE_PROJECT_NAME

设置 `project_name`。

This value is prepended along with the service name to the container on start up.
+ 例如，`project_name` 为 `myapp`
  + 两个服务： `db` 和 `web`
  + 那么启动后，容器名称分别为  `myapp_db_1` 和 `myapp_web_1`

+ `COMPOSE_PROJECT_NAME` 是可选的。如果不设置那么， `COMPOSE_PROJECT_NAME` 默认会使用 `docker-compose.yml` 所在目录名称。

```bash
$ pwd
/data/docker-compose/compose_test/compose_t2/compose_t4

$ docker-compose up -d
Creating network "composetest_default" with the default driver
Creating composetest_web_1 ...
Creating composetest_redis_1 ...
Creating composetest_web_1
Creating composetest_web_1 ... done
```

+ 在命令行中，可以通过 `docker-compose -p project_name` 指定

```bash
$ docker-compose -p myapp  up -d
Creating network "myapp_default" with the default driver
Creating myapp_web_1 ...
Creating myapp_redis_1 ...
Creating myapp_web_1
Creating myapp_web_1 ... done

$ docker-compose -p myapp down --volumes
Stopping myapp_redis_1 ... done
Stopping myapp_web_1   ... done
Removing myapp_redis_1 ... done
Removing myapp_web_1   ... done
Removing network myapp_default
```

## COMPOSE_FILE

指定 `compose file` 的位置。

+ 如果没有指定 `COMPOSE_FILE` ，`docker-compose` 会一次从 `当前目录` 向 `上级目录` 找 `docker-compose.yml` 文件，知道找到为止。
+ `COMPOSE_FILE` 支持指定多个 `compose file`
  + `COMPOSE_FILE=docker-compose.yml:docker-compose.prod.yml`
  + `linux` / `macOS` 中使用 `: (冒号)` 分隔
  + `windows` 中使用 `; (分号)` 分隔。
  + 可以使用 `COMPOSE_PATH_SEPARATOR` 变量自定义上述的 `分隔符` `(: / ;)`
  + 或者使用 `多个` `-f` 实现多 `compose file` 的情形。


## COMPOSE_PATH_SEPARATOR

为 `COMPOSE_FILE` 自定义多文件分隔符。


## COMPOSE_API_VERSION

Docker API 只支持 `确定版本号` 的客户端请求。 如果使用 `docker-compose` 是返回 `client and server don't have same version`，可以通过修改环境变量的方式，设置 `docker api` 和 `client` 版本号一致。

如果 `docker-compose` 和 `docker api` 版本号不一致，可能引发未知异常。


## DOCKER_HOST

Sets the `URL` of the `docker daemon`. As with the Docker client, defaults to `unix:///var/run/docker.sock`.


## DOCKER_TLS_VERIFY

当 `DOCKER_TLS_VERIFY` 值为 `非空字符串` 时，表示 `docker daemon` 启用 `TLS` 通信。


## DOCKER_CERT_PATH

为 `TLS` 验证指定证书路径。
+ 默认值： `~/.docker`

证书包括：
+ `ca.pem`
+ `cert.pem`
+ `key.pem`


## COMPOSE_HTTP_TIMEOUT

设置 `docker-compose` 请求 `docker daemon` 的超时时间
+ 单位 `秒`。
+ 默认值：60


## COMPOSE_TLS_VERSION

为 `TLS` 通信指定 `TLS 版本`
+ 默认值： `TLSv1`
+ 可选值： `TLSv1`, `TLSv1_1`, `TLSv1_2`


## COMPOSE_CONVERT_WINDOWS_PATHS

允许在定义 `volume` 时，将 `windows-style` 路径格式转换为 `Unix-style` 路径格式。Users of Docker Machine and Docker Toolbox on Windows should always set this.

+ 默认值：0
+ 可选值：
  + 启用： `true`, `1`
  + 禁用： `false`, `0`
