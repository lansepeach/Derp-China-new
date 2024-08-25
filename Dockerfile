# 使用最新的 Alpine 基础镜像
FROM alpine:latest

# 设置 Go 语言代理
ENV GOPROXY="https://goproxy.cn"

# 更新 Alpine 包仓库
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装必要的软件包
RUN apk add --no-cache curl iptables

# 安装 Go 语言和 Tailscale DERP
RUN curl -fsSL "https://dl.google.com/go/go1.23.0.linux-amd64.tar.gz" -o go.tar.gz \
    && tar -C /usr/local -xzf go.tar.gz \
    && rm go.tar.gz
# 将 Go 语言添加到系统路径中
ENV PATH="/usr/local/go/bin:$PATH"
# 使用 Go 安装 Tailscale DERP
RUN go install tailscale.com/cmd/derper@main

# 从 edge 仓库安装最新版本的 Tailscale
RUN apk add --no-cache tailscale --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community

# 复制初始化脚本并设置执行权限
COPY init.sh /init.sh
RUN chmod +x /init.sh

# 暴露必要的端口
EXPOSE 444/tcp
EXPOSE 3478/udp

# 设置容器的入口点为初始化脚本
ENTRYPOINT ["/init.sh"]
