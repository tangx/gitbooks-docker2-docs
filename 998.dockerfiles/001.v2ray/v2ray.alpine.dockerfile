FROM alpine:latest

RUN apk update   \
    && apk add ca-certificates wget  \
    && update-ca-certificates     \
    && rm -rf /var/cache/apk/*

ENV version="0.0.1-beta"      
ENV v2ray_version="v2.38"

    
    
RUN wget https://github.com/v2ray/v2ray-core/releases/download/${v2ray_version}/v2ray-linux-64.zip      \
    && unzip -q v2ray-linux-64.zip      \
    && mv v2ray-${v2ray_version}-linux-64/v2ray /usr/bin/v2ray  \
    && chmod +x /usr/bin/v2ray        \
    && rm -rf v2ray-linux-64.zip  \
    && rm -rf v2ray-${v2ray_version}-linux-64

    
ENTRYPOINT ["/usr/bin/v2ray", "-config=/etc/v2ray/config.json"]
