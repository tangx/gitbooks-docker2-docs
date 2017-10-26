FROM ubuntu

LABEL maintainer octowhale@github

# add user to run redis
RUN groupadd redis && useradd -r -g redis redis

# get gosu to run redis
### gosu 因为可以在 build 的时候复用缓存，因此单独做了一层。
ENV GOSU_VERSION 1.10

## 临时文件，哪一层用，哪一层装。 例如 wget
RUN fetchDeps="ca-certificates wget";   \
    dpkgArch=$(dpkg --print-architecture | awk -F- '{ print $NF }');    \
    cp -a /etc/apt/sources.list /etc/apt/sources.list.backup ;  \
    sed -i -e 's/archive.ubuntu.com/mirrors.163.com/g' -e '/security/d' /etc/apt/sources.list  ;   \
    apt-get update ;   \
    apt-get install -y --no-install-recommends $fetchDeps;  \
    rm -rf /var/lib/apt/lists/*     ;  \
    wget -O /usr/local/bin/gosu https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch;  \
    rm -rf /tmp/* ;     \
    chmod +x /usr/local/bin/gosu ; \
    gosu nobody true;   \
    apt-get purge -y --auto-remove $fetchDeps ; \
    mv /etc/apt/sources.list.backup /etc/apt/sources.list ;


### 安装 redis

ENV REDIS_VERSION 3.2.11
ENV REDIS_DOWNLOAD_URL http://download.redis.io/releases/redis-${REDIS_VERSION}.tar.gz
ENV REDIS_DOWNLOAD_SHA 31ae927cab09f90c9ca5954aab7aeecc3bb4da6087d3d12ba0a929ceb54081b5

RUN set -ex; \
    buildDeps='wget \
            gcc \
            libc6-dev   \
            make    \
            ' ; \
    cp -a /etc/apt/sources.list /etc/apt/sources.list.backup ;  \
    sed -i -e 's/archive.ubuntu.com/mirrors.163.com/g'  -e '/security/d' /etc/apt/sources.list ;\
    apt-get update; \
    apt-get install -y $buildDeps --no-install-recommends ;     \
    rm -rf /var/lib/apt/lists/* ;   \
    \
    wget -O redis.tar.gz "$REDIS_DOWNLOAD_URL"; \
    mkdir -p /usr/src/redis ;   \
    tar xf redis.tar.gz -C /usr/src/redis --strip-components=1  ;       \
    rm -f redis.tar.gz ;        \
    \
	grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 1$' /usr/src/redis/src/server.h; \
	sed -ri 's!^(#define CONFIG_DEFAULT_PROTECTED_MODE) 1$!\1 0!' /usr/src/redis/src/server.h; \
	grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 0$' /usr/src/redis/src/server.h; \
    \
    make -C /usr/src/redis -j "$(nproc)" ;      \
    make -C /usr/src/redis install ;    \
    rm -rf /usr/src/redis ;     \
    \
    apt-get purge -y --auto-remove $buildDeps ; \
    mv /etc/apt/sources.list.backup /etc/apt/sources.list ;     \
    \
    mkdir -p /data && chown redis:redis /data   ;

VOLUME /data
WORKDIR /data

COPY docker-entrypoint.sh /usr/local/bin/

EXPOSE 6379
ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD [ "redis-server" ]