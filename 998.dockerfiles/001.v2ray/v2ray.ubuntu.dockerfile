FROM alpine:latest


RUN apt-get update && apt-get install -y \
        wget        \
        unzip       \
    && rm -rf /var/lib/apt/lists/*
    
ENV version="0.0.1-beta"      
ENV v2ray_version="v2.38"

    
    
RUN wget https://github.com/v2ray/v2ray-core/releases/download/${v2ray_version}/v2ray-linux-64.zip      \
    && unzip -q v2ray-linux-64.zip      \
    && mv v2ray-${v2ray_version}-linux-64 /etc/v2ray        \
    && chmod +x /etc/v2ray/v2ray        \
    && rm -rf v2ray-linux-64.zip

    
ENTRYPOINT /etc/v2ray/v2ray 
