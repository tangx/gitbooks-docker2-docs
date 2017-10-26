# Docker Compose 案例

## 准备

+ 安装 docker
+ 安装 docker-compose

## Step1: Setup

1. 创建一个目录

```bash
$ mkdir compose_test
$ cd compose_test
```

2. 创建一个 `app.py`，运维 web 程序

```python
#!/usr/bin/python
#
# filename: app.py

from flask import Flask
from redis import Redis

app = Flask(__name__)
redis = Redis(host='redis', port=6379)  # host='redis' redis 为 `redis container` 的 `容器名`

@app.route('/')
def hello():
    count = redis.incr('hits')
    return 'Hello World! I have been seen {} times.\n'.format(count)

if __name__ == "__main__":
    app.run(host="0.0.0.0", debug=True)

```

> 注意： ** `host='redis'` 中的 `redis` 为 *运行 redis 程序的容器的容器名*，端口使用默认的 `6789` **

3. 创建 `requirements.txt`，安装 python 组件

```ini
flask
redis
```


## Step 2: Create a Dockerfile

在同级目录中，创建 Dockerfile， 启动任务时，可以构建镜像

```Dockerfile
FROM python:3.4-alpine
ADD . /code
WORKDIR /code
RUN pip install -i https://mirrors.ustc.edu.cn/pypi/web/simple -r requirements.txt
CMD ["python", "app.py"]
```

+ `FROM` 使用 `python:3.4-alpine` 镜像作为基础镜像
+ `ADD` 将当前目录 `.` 放入镜像 `/code`
+ `WORKDIR` 将工作目录设置为 `/code`
+ `RUN` 安装 python 依赖，在国内使用 `中科大` 的源，加速下载
+ `CMD` 设置镜像入口为 `python app.py`


## Step 3: Define services in a Compose file

创建 `docker-compose.yml`， 编写发布步骤

```yaml
# docker-compose.yaml

version: '3'
services:
  web:
    build: .
    ports:
     - "5001:5000"
  redis:
    image: "redis:alpine"
```

`compose` 定义了两个 `服务` : `web` 和 `redis`
+ `web` 服务
  + `build`: 使用当前目录的 `Dockerfile` build 的镜像
  + `ports`: 映射宿主机 5001 端口到容器的 5000 端口，与 `docker run -p 5001:5000` 同。
    + `Flask` 默认端口 5000
    + 由于我本机的 5000 端口已经跑了 `docker registry proxy`，因此修改了端口映射。
+ `redis` 服务
  + 使用 Docker Hub 中的 `redis` 镜像

## Step 4: Build and run your app with Compose

1. 使用命令 `docker-compose up` 服务

```bash
$ docker-compose up

Starting composetest_web_1 ...
composetest_redis_1 is up-to-date
Starting composetest_web_1 ... error

ERROR: for composetest_web_1  Cannot start service web: driver failed programming external connectivity on endpoint composetest_web_1 (92e55e324676835b2d5053a8aa6eafbb639f96d1f9dfe5203e2d7a66deb793c1): Bind for 0.0.0.0:5000 failed: port is already allocated

ERROR: for web  Cannot start service web: driver failed programming external connectivity on endpoint composetest_web_1 (92e55e324676835b2d5053a8aa6eafbb639f96d1f9dfe5203e2d7a66deb793c1): Bind for 0.0.0.0:5000 failed: port is already allocated
ERROR: Encountered errors while bringing up the project.

############################################################################
# 第一此启动出错，是因为本机已经跑了一个容器 `registry-proxy` 占用了 5000 端口
# 因此，将 docker-compose 中的端口映射从 `5000:5000` 修改为了 `5001:5000`
############################################################################

$ docker-compose up
Recreating composetest_web_1 ...
composetest_redis_1 is up-to-date
Recreating composetest_web_1 ... done
Attaching to composetest_redis_1, composetest_web_1
redis_1  | 1:C 25 Sep 08:08:25.420 # oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo
redis_1  | 1:C 25 Sep 08:08:25.477 # Redis version=4.0.2, bits=64, commit=00000000, modified=0, pid=1, just started
redis_1  | 1:C 25 Sep 08:08:25.477 # Warning: no config file specified, using the default config. In order to specify a config file use redis-server /path/to/redis.conf
redis_1  | 1:M 25 Sep 08:08:25.478 * Running mode=standalone, port=6379.
redis_1  | 1:M 25 Sep 08:08:25.478 # WARNING: The TCP backlog setting of 511 cannot be enforced because /proc/sys/net/core/somaxconn is set to the lower value of 128.
redis_1  | 1:M 25 Sep 08:08:25.478 # Server initialized
redis_1  | 1:M 25 Sep 08:08:25.478 # WARNING overcommit_memory is set to 0! Background save may fail under low memory condition. To fix this issue add 'vm.overcommit_memory = 1' to /etc/sysctl.conf and then reboot or run the command 'sysctl vm.overcommit_memory=1' for this to take effect.
redis_1  | 1:M 25 Sep 08:08:25.478 # WARNING you have Transparent Huge Pages (THP) support enabled in your kernel. This will create latency and memory usage issues with Redis. To fix this issue run the command 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' as root, and add it to your /etc/rc.local in order to retain the setting after a reboot. Redis must be restarted after THP is disabled.
redis_1  | 1:M 25 Sep 08:08:25.478 * Ready to accept connections
web_1    |  * Running on http://0.0.0.0:5000/ (Press CTRL+C to quit)
web_1    |  * Restarting with stat
web_1    |  * Debugger is active!
web_1    |  * Debugger PIN: 326-358-579
```

访问主机 `htpp://docker_host_ip:5001` 查看结果

![003.quick-hello-world-1.png](003.quick-hello-world-1.png)

使用命令 `docker container ls` 查看当前运行的主机

```bash
$ docker container ls
CONTAINER ID        IMAGE               COMMAND                  CREATED              STATUS              PORTS                    NAMES
54870af6fd43        redis:alpine        "docker-entrypoint..."   About a minute ago   Up 7 seconds        6379/tcp                 composetest_redis_1
c80b129f2730        composetest_web     "python app.py"          About a minute ago   Up 7 seconds        0.0.0.0:5001->5000/tcp   composetest_web_1
```


2. 使用 `docker image ls` 命令查看本地镜像

```bash
$ docker image ls
REPOSITORY              TAG                 IMAGE ID            CREATED             SIZE
composetest_web         latest              e2c21aa48cc1        4 minutes ago       93.8MB
python                  3.4-alpine          84e6077c7ab6        7 days ago          82.5MB
redis                   alpine              9d8fa9aa0e5b        3 weeks ago         27.5MB
```

使用命令 `docker inspect <image_tag>/<image_id>` 查看具体信息

5. 重新打开一个终端，进入到 `docker-compose.yml` 所在目录，使用命令 `docker-compose down` 关闭服务

```bash
$ docker-compose down
Stopping composetest_web_1   ... done
Stopping composetest_redis_1 ... done
Removing composetest_web_1   ... done
Removing composetest_redis_1 ... done
Removing network composetest_default
```

或者直接在 `docker-compose up` 的终端中 `Ctrl+C` 退出进程

使用 `docker-compose stop` 后， `容器关闭，但不删除`

```bash
$ docker container ps -a
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                     PORTS                    NAMES
78b2acf2d71f        redis:alpine        "docker-entrypoint..."   25 seconds ago      Exited (0) 9 seconds ago                            composetest_redis_1
7d34fdcd3f91        composetest_web     "python app.py"          25 seconds ago      Exited (0) 9 seconds ago                            composetest_web_1
```

## Step 5: Edit the Compose file to add a bind mount

编辑 `docker-compose.yml`，增加 [volumes bind mount](https://docs.docker.com/engine/admin/volumes/bind-mounts/)

`volumes` 将 `.:/code` 本地目录映射到了容器中
+ 与 `docker run -v host_path:container_path` 相同
+ 与 `docker run` 不同的是，`docker-compose` 可以使用相对目录，而 `docker run` 只能使用绝对目录

```yaml
version: '3'
services:
  web:
    build: .
    ports:
     - "5000:5000"

    ## 映射本地目录到容器中
    volumes:
     - .:/code

  redis:
    image: "redis:alpine"
```

通过目录映射，可以方便的在本地修改文件并查看效果，而不用 `rebuild` 镜像


## Step 6: Re-build and run the app with Compose

```bash
$ docker-compose up
Creating network "composetest_default" with the default driver
Creating composetest_web_1 ...
Creating composetest_redis_1 ...
Creating composetest_web_1
Creating composetest_redis_1 ... done
Attaching to composetest_web_1, composetest_redis_1
web_1    |  * Running on http://0.0.0.0:5000/ (Press CTRL+C to quit)
...
```

> Shared folders, volumes, and bind mounts
> + If your project is outside of the `Users` directory (`cd ~`), then you need to share the drive or location of the Dockerfile and volume you are using. If you get runtime errors indicating an application file is not found, a volume mount is denied, or a service cannot start, try enabling file or drive sharing. Volume mounting requires shared drives for projects that live outside of `C:\Users` (Windows) or `/Users` (Mac), and is required for any project on Docker for Windows that uses Linux containers. For more information, see Shared Drives on Docker for Windows, File sharing on Docker for Mac, and the general examples on how to Manage data in containers.
> + If you are using Oracle VirtualBox on an older Windows OS, you might encounter an issue with shared folders as described in this VB trouble ticket. Newer Windows systems meet the requirements for Docker for Windows and do not need VirtualBox.


## Step 7: Update the application

现在代码目录已经映射到容器中了，因此我们不需要 rebuild 惊喜就可以看到修改后的效果。

1. 重开一个终端窗口，修改 `app.py` 文件。 `Hello World` 改为 `Hello from Docker`.

```python
# return 'Hello World! I have been seen {} times.\n'.format(count)
return 'Hello from Docker! I have been seen {} times.\n'.format(count)
```

2. 刷新窗口，查看结果

![003.quick-hello-world-2.png](003.quick-hello-world-2.png)


## Step 8: Experiment with some other commands

+ `docker-compose up -d` : 后台运行
+ `docker-compose ps`

```bash
$ docker-compose ps
       Name                      Command               State           Ports         
-------------------------------------------------------------------------------------
composetest_redis_1   docker-entrypoint.sh redis ...   Up      6379/tcp              
composetest_web_1     python app.py                    Up      0.0.0.0:5001->5000/tcp
```

+ `docker-compose run` : 一次性命令。 例如查看 `web` 服务的环境变量

```bash
$ docker-compose run web env
PATH=/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=8ad8bfde60ca
TERM=xterm
LANG=C.UTF-8
GPG_KEY=97FC712E4C024BBEA48A61ED3A5CA953F73C700D
PYTHON_VERSION=3.4.7
PYTHON_PIP_VERSION=9.0.1
HOME=/root
```

+ `docker-compose stop`: 停止服务
+ `docker-compose down`: 关闭所有容器并删除，默认保留 `数据卷`
  + `docker-compose down --volumes`: 同时也删除容器使用的 `数据卷`  

> 注意： `docker-compose` 都必须指定 `docker-compose.yml` 。否则会报错
>> + `default`: 使用当前目录下的 `docker-compose.yml` 或 `docker-compose.yaml`
>> + 或者使用 `docker-compose -f path/compose_name.yml subcommand`

```
$ docker-compose ps
ERROR:
        Can't find a suitable configuration file in this directory or any
        parent. Are you in the right directory?

        Supported filenames: docker-compose.yml, docker-compose.yaml
```
