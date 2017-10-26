FROM ubuntu

RUN cp -a /etc/apt/sources.list /etc/apt/sources.list.backup    \
    \
# 更换源
    && sed -i -e 's/archive.ubuntu.com/mirrors.163.com/g' -e '/security/d' /etc/apt/sources.list   \
    && apt-get update   \
# 安装
    && apt-get install -y --no-install-recommends wget  \
# 安装完成后删除
    && apr-get purge --auto-remove wget \
# 清空缓存
    && rm -rf /var/lib/apt/lists/*  \
# 恢复源
    && mv /etc/apt/sources.list.backup /etc/apt/sources.list

