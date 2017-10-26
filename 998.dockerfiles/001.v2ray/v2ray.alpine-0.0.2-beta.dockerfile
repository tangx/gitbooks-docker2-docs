FROM alpine:latest

# 保留 https 是为了下次可以复用 cache
RUN fetchDeps="ca-certificates"    \
    && apk update   \
    && apk add $fetchDeps  \
    && update-ca-certificates     \
    && rm -rf /var/cache/apk/*

ENV version="0.0.2-beta"      
ENV v2ray_version="v2.38"


# 安装 wget 并在最后删除
RUN fetchDeps="wget"     \
    && apk update \
    && apk add $fetchDeps   \
    && wget https://github.com/v2ray/v2ray-core/releases/download/${v2ray_version}/v2ray-linux-64.zip      \
    && unzip -q v2ray-linux-64.zip      \
    && mv v2ray-${v2ray_version}-linux-64/v2ray /usr/bin/v2ray  \
    && chmod +x /usr/bin/v2ray        \
    && rm -rf v2ray-linux-64.zip  \
    && rm -rf v2ray-${v2ray_version}-linux-64   \
    && apk del $fetchDeps   \
    && rm -rf /var/cache/apk/*


# 将原来的 ENTRYPOINT 分为两部分，可以自定义配置文件位置。
# 但其实没这个必要

# ENTRYPOINT ["/usr/bin/v2ray"]
# CMD ["-config=/etc/v2ray/config.json"]

ENTRYPOINT ["/usr/bin/v2ray", "-config=/etc/v2ray/config.json"]