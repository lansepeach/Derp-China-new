# 用法
## 云主机
购买国内的 VPS 就行，建议在 618、双 11 过节的时候买良心云，打折力度大。
## 域名
这个 Dockerfile 要求 Derp 服务器必须使用域名，因此你必须提前准备好自己的域名。备案可以不用做，后期在 Nginx 上开不常见端口就行了。
## HTTPs 证书
建议通过 `Certbot` 等工具进行自动化SSL证书申请，可以参考 @frank-lam 的[使用 Certbot 为网站签发永久免费的 HTTPS 证书](https://www.frankfeekr.cn/2021/03/28/let-is-encrypt-cerbot-for-https/index.html)。
## 构建镜像
太懒了，没有把镜像打包上传，有需要的话自己构建一下：
```
git clone https://github.com/S4kur4/Derp-China.git && cd Derp-China && docker build . -t derpinchina:latest
```
第一次速度应该不会很快，但也不至于太慢，可以等会儿，先做下一步。
## 创建 tailscale 一次性认证 key
这个 key 是用来通过命令行将容器连接到你的 tailscale 里去的，前往 https://login.tailscale.com/admin/settings/keys 点击 "Generate auth key..." 创建一下，然后把 key 记录下来。

<img width="500" alt="image" src="https://github.com/S4kur4/Derp-China/assets/17521941/093b6608-9100-47b5-87d9-ac59f629d1b6">

## 修改配置
修改 `.env` 文件里的参数，方便起见就把 `TAILSCALE_DERP_HOSTNAME` 改成你自己的域名，然后把刚才记录下的 key 填进 `TAILSCALE_AUTH_KEY` 就行。

## 启动

```
docker-compose up -d
```
这时候你可以去看看刚刚申请的那个 key 是不是失效了，再检查下 tailscale 的机器列表里有没有把 Derp 容器加进去。如果 key 失效了，容器也被加进了机器列表，就没啥问题了。

另外也可以执行下面的命令检查一下 Derp 服务在回环地址是不是正常工作了：

```
curl http://127.0.0.1:444
```
正常情况下 curl 以后会返回下面的内容：

```html
<html><body>
<h1>DERP</h1>
<p>
  This is a
  <a href="https://tailscale.com/">Tailscale</a>
  <a href="https://pkg.go.dev/tailscale.com/derp">DERP</a>
  server.
</p>
```
可能会发现 tailscale.com 的 key 列表里刚刚申请的 key 并没有失效，说明容器没有成功登录至 tailscale。此时可以直接进入容器手动用 key 重新登录一下：
```
docker exec -it tailscale-derp /bin/sh
```
```
tailscale login --auth-key="你的key"
```
## 安装并配置 Nginx
这里不一定用 Nginx，换别的 caddy 什么的也行。只要配置个反代转发到 `http://127.0.0.1:444` 就行。公网端口建议开不常见端口，比如我开的 442。

我的 Nginx 配置给你参考：

```
# setup a upstream point to CodiMD server
upstream @derp {
    server 127.0.0.1:444;
    keepalive 300;
}

# for socket.io (http upgrade)
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}

# https server
server {
    listen 442 ssl;
    server_name derp.xxxx.xx;
    if ($host != 'derp.xxxx.xx'){
        return 403;
    }
    # setup certificate
    ssl_certificate /etc/letsencrypt/live/xxxx.xx/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/xxxx.xx/privkey.pem;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 5m;
    keepalive_timeout 70;

    location / {
      proxy_http_version 1.1;

      # set header for proxy protocol
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection $connection_upgrade;
      
      proxy_redirect off;
      proxy_read_timeout 300;
      proxy_connect_timeout 300;
      proxy_pass http://@derp;
    }
}
```
## 向 tailscale 添加 Derp
到 https://login.tailscale.com/admin/acls/file 添加你的 Derp 服务器，同样给出我的参考配置：

```
	"derpMap": {
		//"OmitDefaultRegions": true,
		//上面开启好像是只允许自定义Derp服务器
		"Regions": {
			"900": {
				"RegionID":   900,
				"RegionCode": "myderpserver",
				"Nodes": [
					{
						"Name":     "1",
						"RegionID": 900,
						"DERPPort": 443,
						"HostName": "derp.example.com",
					},
				],
			},
		},
	},
```
这里就结束了，最后使用 tailscale 命令行通过 `tailscale ping` 和 `tailscale status` 检查验证一下。
# 致谢
我是基于 @tijjjy 的 https://github.com/tijjjy/Tailscale-DERP-Docker 修改的，他在博客 [Self Host Tailscale Derp Server](https://tijjjy.me/2023-01-22/Self-Host-Tailscale-Derp-Server) 给大家详细 walkthrough 了，建议阅读一下，非常容易理解。
