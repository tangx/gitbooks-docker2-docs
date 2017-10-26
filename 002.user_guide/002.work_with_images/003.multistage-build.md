# 多阶构建 multi-stage-build

> https://docs.docker.com/engine/userguide/eng-image/multistage-build/#use-multi-stage-builds

> 推荐链接： http://blog.alexellis.io/mutli-stage-docker-builds/

+ 使用一个 `Dockerfile`
+ 可以使用多个 `FROM`
+ 每个 `FROM` 的父镜像可以不同
+ 从每个 `FROM` 开始都是一个相对独立的 `build` 过程
+ 从之前的 `build` 结果中只 `提取` 需要的内容，其他舍弃


## 如何使用

**multi-stage dockerfile**

```dockerfile
# builder
FROM golang:1.7.3
WORKDIR /go/src/github.com/alexellis/href-counter/
RUN go get -d -v golang.org/x/net/html  
COPY app.go .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

# publisher
FROM alpine:latest  
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=0 /go/src/github.com/alexellis/href-counter/app .
CMD ["./app"]  
```

在 `publisher` 中，使用了 `COPY --from=0` 从上一次 `build` 的结果中提取了编译结果。源代码和其他不需要的文件就放弃了。

### build stage 别名

```dockerfile
# builder
FROM golang:1.7.3 as builder
WORKDIR /go/src/github.com/alexellis/href-counter/
RUN go get -d -v golang.org/x/net/html  
COPY app.go    .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

# publisher
FROM alpine:latest  
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /go/src/github.com/alexellis/href-counter/app .
CMD ["./app"]  
```

+ 在 `builder` 阶段，对 `FROM` 指定使用了 `别名` `(as builder)`。
+ 相应的，在 `publisher` 阶段， `COPY` 指令使用了 `--from=builder` 指定提取来源。
  + 使用 `as <name>` 别名，即使调整 `build` 顺序也不会影响结果。
