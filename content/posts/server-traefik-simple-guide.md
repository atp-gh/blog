+++
title = "Docker/NixOS使用traefik实现简单反代"
date = "2024-12-20"
updated = "2024-12-20"
description = "Easy reverse proxy setup with Traefik on Docker and NixOS."
tags = ["Traefik", "NixOS", "Docker"]
+++

## Docker

### http反代

先是traefik

基本结构是

```
入口(entrypoints)->路由(routers)->服务(services)
```

先解释几条配置
这个是docker启动traefik的基本配置,使用`command`传进去

```docker-compose.yml
    command:
      - --api.insecure=true # 开启8080端口的webui界面，可以看到traefik可视化面板
      - --providers.docker=true # 开启监控docker容器
      - --providers.docker.exposedbydefault=false # 默认不自动暴露容器,隐藏此容器
```

接下来是入口`entrypoints`,也使用`command`传进去,格式如下

```docker-compose.yml
    command:
      - --entrypoints.<entrypoints-name-1>.address=:80
      - --entrypoints.<entrypoints-name-2>.address=:443
```

定义监听的入口，对于反代来说，只需要监听`:80`和`:443`，也就是`http`和`https`的流量。将<entrypoints-name-1/2>自行替换成你想要的名字，如

```docker-compose.yml
    command:
      - --entrypoints.http.address=:80
      - --entrypoints.https.address=:443
```

或者

```docker-compose.yml
    command:
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
```

所以，我们先得到一个`traefik`容器的编排文件

docker的`traefik`网络需要提前创建好

```bash
docker network create --driver bridge traefik
```

traefik的docker-compose.yml

```yaml
version: "3"

services:
  reverse-proxy:
    # The official v3 Traefik docker image
    image: traefik:v3.2
    # Enables the web UI and tells Traefik to listen to docker
    command:
      - --api.insecure=true
      - --providers.docker=true
      - --providers.docker.exposedbydefault=false # 默认不自动暴露容器,隐藏此容器
      - --entrypoints.web.address=:80 # HTTP 入口点
      - --entrypoints.websecure.address=:443 # HTTPS 入口点
    ports:
      # The HTTP port
      - "80:80"
      - "443:443"
      # The Web UI (enabled by --api.insecure=true)
      - "8080:8080"
    volumes:
      # So that Traefik can listen to the Docker events
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - traefik
networks:
  traefik:
    external: true
```

下面启动示例syncthing
接下来，在需要启动的容器,使用labels将需要的参数传入
首先，需要启用traefik

```docker-compose.yml
    labels:
      - "traefik.enable=true"
```

然后，定义路由(routers)

```docker-compose.yml
    labels:
      - "traefik.http.routers.<routers-name-1>.xxxxxxx"
      - "traefik.tcp.routers.<routers-name-2>.xxxXXXX"
```

有不同协议，因为我只反代网页界面，仅使用`http`协议即可
将<routers-name-1/2>替换为你想要的路由名字，比如这里直接以`syncthing`命名
下面是http详细配置

```docker-compose.yml
    labels:
      - "traefik.http.routers.syncthing.rule=Host(`sync.example.com`)"
      - "traefik.http.routers.syncthing.entrypoints=web" # 设置入口为web,也就是80
```

rule=Host(`sync.example.com`)匹配域名
entrypoints=web匹配刚才定义的监听的入口,这里先使用http,所以使用web,监听:80端口
最后，定义服务(services),由于traefik自动监控容器，会自动把容器作为服务与路由关联起来，所以什么都不需要配置，除非容器暴露了多个端口
当容器只有一个端口的时候，traefik默认把流量传给这个端口,不需要额外指定端口
但容器有多个端口映射时，traefik不知道要把流量传给哪一个端口,所以需要额外配置来指定一个端口

```docker-compose.yml
    labels:
      - "traefik.http.services.<service-name>.loadbalancer.server.port=8384" # 如果暴露了多个端口，需要指定端口
```

<service-name>替换为容器名字，<service-name>与<routers-name>可以重名
记得添加syncthing容器与traefik容器同属一个网络，也就是`traefik`这个网络之中。

```docker-compose.yml
version: '3'
services:
  syncthing:
    image: syncthing/syncthing
    container_name: syncthing
    restart: unless-stopped
    ulimits:
      nproc: 65535
      nofile:
        soft: 65535
        hard: 65535
    volumes:
      - /var/syncthing:/var/syncthing
    environment:
      - PUID=1000
      - PGID=1000
    ports:
      - 8384:8384 # Web UI
      - 22000:22000/tcp # TCP file transfers
      - 22000:22000/udp # QUIC file transfers
      - 21027:21027/udp # Receive local discovery broadcasts
    labels:
      - "traefik.enable=true" # 启动traefik
      - "traefik.http.routers.syncthing.rule=Host(`sync.example.com`)" # 匹配域名
      - "traefik.http.routers.syncthing.entrypoints=web" # 设置入口为web,也就是80
      - "traefik.http.services.syncthing.loadbalancer.server.port=8384" # 如果暴露了多个端口，需要指定端口
      # 下面不需要，留着仅供参考
      # - "traefik.http.services.syncthing.loadbalancer.server.scheme=http" # 明确指定 HTTP
      # - "traefik.docker.network=traefik" # 指定docker容器网络
    networks:
      - traefik
networks:
  traefik:
    external: true

```

# 添加tls证书

traefik部分
在保留刚才的基础上
在`command`里面添加

```docker-compose.yml
      - "--certificatesresolvers.<resolver-name>.acme.tlschallenge=true" # 开启证书申请
      - "--certificatesresolvers.<resolver-name>.acme.email=yourmail@domain.com" # 你的邮箱
      - "--certificatesresolvers.<resolver-name>.acme.storage=/letsencrypt/acme.json" # 自动生成的证书配置存在这个地方
```

将<resolver-name>替换为你想要的名字，这里替换为`myresolver`
注意，需要添加一个储存卷来存放证书配置，以及可以把http关掉，及docker关闭:80端口,取消`entrypoints`的web设置
示例如下

```docker-compose.yml
version: '3'

services:
  reverse-proxy:
    # The official v3 Traefik docker image
    image: traefik:v3.2
    # Enables the web UI and tells Traefik to listen to docker
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false" # 默认不自动暴露容器,隐藏此容器
      - "--entrypoints.websecure.address=:443"           # HTTPS 入口点
      - "--certificatesresolvers.myresolver.acme.tlschallenge=true" # 开启证书申请
      - "--certificatesresolvers.myresolver.acme.email=your@mail.com" # 你的邮箱
      - "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json" # 自动生成的证书配置存在这个地方
    ports:
      - "443:443"
      # The Web UI (enabled by --api.insecure=true)
      - "8080:8080"
    volumes:
      # So that Traefik can listen to the Docker events
      - /var/run/docker.sock:/var/run/docker.sock
      - /root/letsencrypt:/letsencrypt # 储存证书配置
    networks:
      - traefik
    # - 下面是指定默认申请的证书，一般来说不需要这些配置，traefik会自动检测并申请tls证书
      # labels:
      # - "traefik.tls.stores.default.defaultgeneratedcert.resolver=myresolver" # 指定默认申请的resolver
      # - "traefik.tls.stores.default.defaultgeneratedcert.domain.main=example.org" # 指定主域名
      # - "traefik.tls.stores.default.defaultgeneratedcert.domain.sans=foo.example.org, bar.example.org"
networks:
  traefik:
    external: true
```

然后是syncthing
在路由配置把`entrypoints`改为websecure,即使用https
再在路由配置添加一个指定使用的证书resolver

```docker-compose.yml
    labels:
      - "traefik.http.routers.syncthing.entrypoints=websecure" # 设定入口为websecure也就是443
      - "traefik.http.routers.syncthing.tls.certresolver=myresolver" # 指定证书申请的resolver
```

最终配置如下

```docker-compose.yml
version: '3'
services:
  syncthing:
    image: syncthing/syncthing
    container_name: syncthing
    restart: unless-stopped
    ulimits:
      nproc: 65535
      nofile:
        soft: 65535
        hard: 65535
    volumes:
      - /var/syncthing:/var/syncthing
    environment:
      - PUID=1000
      - PGID=1000
    ports:
      - 8384:8384 # Web UI
      - 22000:22000/tcp # TCP file transfers
      - 22000:22000/udp # QUIC file transfers
      - 21027:21027/udp # Receive local discovery broadcasts
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=traefik"
      # 当容器只有一个端口的时候，traefik默认把流量传给这个端口,不需要额外指定端口
      # 但容器有多个端口映射时，traefik不知道要把流量传给哪一个端口,所以需要额外指定一个端口
      - "traefik.http.services.syncthing.loadbalancer.server.port=8384"
      - "traefik.http.routers.syncthing.rule=Host(`sync.example.com`)"
      - "traefik.http.routers.syncthing.entrypoints=websecure" # 设定入口为websecure也就是443
      - "traefik.http.routers.syncthing.tls.certresolver=myresolver" # 指定证书申请的resolver
      # - 下面配置不需要，留着仅供参考
      # - "traefik.http.routers.syncthing.tls=true" # 开启tls
      # - "traefik.http.services.syncthing.loadbalancer.server.scheme=http" # 明确指定 HTTP
    networks:
      - traefik
networks:
  traefik:
    external: true
```

然后就有tls证书了，且强制使用https

下面是官方示例配置

```docker-compose.yml
version: "3.3"

services:

  traefik:
    image: "traefik:v3.2"
    container_name: "traefik"
    command:
      #- "--log.level=DEBUG"
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entryPoints.websecure.address=:443"
      - "--certificatesresolvers.myresolver.acme.tlschallenge=true"
      #- "--certificatesresolvers.myresolver.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory"
      - "--certificatesresolvers.myresolver.acme.email=postmaster@example.com"
      - "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json"
    ports:
      - "443:443"
      - "8080:8080"
    volumes:
      - "./letsencrypt:/letsencrypt"
      - "/var/run/docker.sock:/var/run/docker.sock:ro"

  whoami:
    image: "traefik/whoami"
    container_name: "simple-service"
    labels:
      - "traefik.enable=true"
      # 因为这个容器只暴露一个80端口，所以不需要特别指定端口
      - "traefik.http.routers.whoami.rule=Host(`whoami.example.com`)"
      - "traefik.http.routers.whoami.entrypoints=websecure"
      - "traefik.http.routers.whoami.tls.certresolver=myresolver"
```

## NixOS

有了docker的基础，配置较为简单，易于理解，基本是把docker的相关配置变成json的形式，直接使用nix语言进行配置
示例`traefik.nix`

```traefik.nix
{
  config,
  pkgs,
  host,
  ...
}:
{
  # 开启syncthing和netdata
  services = {
      syncthing = {
          enable = true;
      };
  };
  services.netdata = {
    enable = true;
  };
  # 开启 traefik
  services.traefik = {
    enable = true;

    # 静态配置
    staticConfigOptions = {
      # 需要日志可以添加下面的配置
      # log = {
        # level = "INFO";
        # filePath = "${config.services.traefik.dataDir}/traefik.log";
        # format = "json";
      # };

      # 定义入口，名字是websecure,仅设置:443
      entryPoints = {
        # web = {
        #   address = ":80";
        # };
        websecure= {
          address = ":443";
        # 在下面动态配置已经指定过了
	      # http.tls.certResolver = "myresolver";
        };
      };

      # 定义证书申请器,myresolver是我定义的证书申请器的名字，名字可以随便起
      certificatesResolvers.myresolver.acme = {
	    tlschallenge = true;
        email = "example@email.com";
        storage = "${config.services.traefik.dataDir}/acme.json";
      #   httpChallenge.entryPoint = "web";
      };

      # 开启面板
      api.dashboard = true;
      # Access the Traefik dashboard on <Traefik IP>:8080 of your server
      api.insecure = true;
    };

    # 动态配置
    dynamicConfigOptions = {
      # 使用http协议
      http = {
        routers = {
          # 定义2个路由名字，一个是syncthing，一个是netdata,名字可以随便起
          syncthing= {
            # 定义入口为websecure,也就是443
	          entryPoints = [ "websecure" ];
            # 设置规则为匹配域名
            rule = "Host(`sync.example.com`)";
            # 指定跟路由相关联的服务(service)
            service = "syncthing";
            # 指定路由使用的证书申请器
	          tls.certresolver = "myresolver";
          };
          # 第二个路由，跟第一个同理
          netdata= {
	          entryPoints = [ "websecure" ];
            rule = "Host(`data.example.com`)";
            service = "netdata";
	          tls.certresolver = "myresolver";
          };
        };
        # 定义服务
        services = {
          # 定义2个服务名字，一个叫syncthing,一个叫netdata，名字可以随便起，可以与入口，路由的名字重名
          syncthing = {
            loadBalancer = {
              # server里面配置webui界面监听的地址即可
              servers = [
                {
                  url = "http://localhost:8384";
                }
              ];
              # syncthing不加下面这行配置无法正常访问,其他请略过这个
              passHostHeader = false;
            };
          };
          netdata = {
            loadBalancer = {
              servers = [
                {
                  url = "http://localhost:19999";
                }
              ];
            };
          };
        };
     };
    };
  };
}

```

然后，在配置文件中引用`traefik.nix`

```
{
  config,
  pkgs,
  host,
  ...
}:
{
  ...
  imports = [
    traefik.nix
  ];
  ...
}
```

然后，重构系统

```bash
sudo nixos-rebuild switch
```

或者
使用flake

```bash
sudo nixos-rebuild switch --flake .#"$HOSTNAME"
```

访问域名，确认反代成功

## 参考

1. https://doc.traefik.io/traefik/
2. https://github.com/anandslab/docker-traefik
3. https://blog.eleven-labs.com/en/using-traefik-as-a-reverse-proxy/
4. https://github.com/korridor/reverse-proxy-docker-traefik
5. https://wiki.nixos.org/wiki/Traefik
6. https://blog.outv.im/2022/traefik/#traefik-%E6%98%AF%E4%BB%80%E4%B9%88%EF%BC%9F
