+++
title = "cloudfront配置服务器cdn并使用acme.sh自动获取证书"
date = "2024-02-26"
updated = "2024-02-26"
description = "Configuring CloudFront CDN with automatic SSL certificates via acme.sh"
tags = ["CDN", "Acme"]
+++

# 1.CloudFront配置

先创建一个`分配` 。

![](https://img.0pt.icu/learn/cloudfront-cdn-acme/1.png)

源域输入服务器的ip加上`.nip.io`。

为什么是`.nip.io`请查看这个官网。

[https://nip.io/](https://nip.io/)

如我的服务器ip是`1.234.34.64`，那么，我的源域是`1.234.34.64.nip.io`。

其他根据自己的需求配置，如果

![](https://img.0pt.icu/learn/cloudfront-cdn-acme/2.png)

源请求策略可以设置成AllViewer，可以避免502错误。

![](https://img.0pt.icu/learn/cloudfront-cdn-acme/3.png)这个SSL证书必须要选，点击`请求证书`可以申请一个免费证书。

![](https://img.0pt.icu/learn/cloudfront-cdn-acme/4.png)

选择`请求公有证书`，点击`下一步`。

![](https://img.0pt.icu/learn/cloudfront-cdn-acme/5.png)

点击`为此证书添加另一个名称`，添加你的域名与这个域名的泛域名。

图中所例，域名是`abc.com`

泛域名是`*.abc.com`

验证方式选择`DNS验证`。密钥算法一般来说随意。点击`请求`。

![](https://img.0pt.icu/learn/cloudfront-cdn-acme/6.png)

点进去。

![](https://img.0pt.icu/learn/cloudfront-cdn-acme/7.png)

添加CNAME到你的域名的DNS记录中。

等一会，`等待验证`变为`已颁发`后，CloudFront这边的证书即可申请完成。

转到刚才创建`分配`，选择刚才申请的SSL证书，点击创建。

![](https://img.0pt.icu/learn/cloudfront-cdn-acme/8.png)

记住这个`分配域名`。

这时候点击编辑。

![](https://img.0pt.icu/learn/cloudfront-cdn-acme/9.png)

图例的证书就当作选了。

点击添加项目，将你需要DNS的子域名写上去。

![](https://img.0pt.icu/learn/cloudfront-cdn-acme/10.png)

点击保存更改。

然后，需要在你的域名的dns处，添加CNAME记录。

name是你的解析出来的域名，如图例就是test和ok，

value是，刚才记住的分配域名。

# 2.acme.sh配置

来到服务器处，需要给服务器这边也申请一个证书（不能使用自签名证书）。

默认Nginx已经配置完成。

我使用docker部署nginx。

```bash
curl https://get.acme.sh | sh -s email=youremail@example.com
# youremail@example.com请替换为你自己的邮箱
source .bashrc
acme.sh --set-default-ca --server letsencrypt
```

[https://github.com/acmesh-official/acme.sh/wiki/dnsapi](https://github.com/acmesh-official/acme.sh/wiki/dnsapi)

[https://github.com/acmesh-official/acme.sh/wiki/dnsapi2](https://github.com/acmesh-official/acme.sh/wiki/dnsapi)

请再这俩个链接中找到i自己使用dns的提供商，并按照给出的步骤申请。

我使用Cloudflare，根据链接里面给出的方法。

您可以从 Cloudflare 个人资料页面的 API 令牌部分下获取您的全球 API 密钥。单击全局 API 密钥旁边的“查看”，验证您的 Cloudflare 密码，它将显示给您。它是一个 32 个字符的十六进制字符串，必须通过将环境变量 您可以从 Cloudflare 个人资料页面的 API 令牌部分下获取您的全球 API 密钥。单击全局 API 密钥旁边的“查看”，验证您的 Cloudflare 密码，它将显示给您。它是一个 32 个字符的十六进制字符串，必须通过将环境变量 `CF_Key` 设置为其值来提供给 acme.sh。您还必须将  设置为其值来提供给 acme.sh。您还必须将  设置为其值来提供给 acme.sh。您还必须将 `CF_Email` 设置为与您的 Cloudflare 帐户关联的电子邮件地址;这是您在登录 Cloudflare 时输入的电子邮件地址。 设置为与您的 Cloudflare 帐户关联的电子邮件地址;这是您在登录 Cloudflare 时输入的电子邮件地址。

```bash
export CF_Key="763eac4f1bcebd8b5c95e9fc50d010b4"
export CF_Email="youremail@example.com"
# 域名替换成自己的域名，这是申请域名极其泛域名的证书
https://img.0pt.icu/learn/cloudfront-cdn-acme/acme.sh --issue --dns dns_cf -d example.com -d '*.example.com'
```

等待证书申请完成。

之后，安装证书到指定路径。

```bash
acme.sh --installcert -d example.com \
--key-file   /your/path/example.com.key \
--fullchain-file /your/path/example.com.cer
```

请把/your/path/换成你指定的路径下面。

这里我是将它放在nginx的映射目录下面，这样，证书文件可以映射进容器，供nginx使用。

在nginx配置的server块添加选择证书的相关配置。

```
ssl_certificate /your/docker/path/0pt.icu.cer;
ssl_certificate_key /your/docker/path/0pt.icu.key;
```

这里把/your/docker/path/替换成证书文件实际在docker里面的路径，注意跟上面那个宿主机的路径有差别。

然后重载nginx。我的nginx容器名叫nginx

```
docker exec nginx nginx -s reload
```

# 3.nginx从CloudFront上获取客户端真实IP地址

![](https://img.0pt.icu/learn/cloudfront-cdn-acme/11.png)

点击策略。

![](https://img.0pt.icu/learn/cloudfront-cdn-acme/12.png)

点击源请求。

![](https://img.0pt.icu/learn/cloudfront-cdn-acme/13.png)点击创建源请求策略。

![](https://img.0pt.icu/learn/cloudfront-cdn-acme/14.png)

名称与描述随意。其他如图配置。

若有需求，Add header可以再添加，但是一定要选图示的这个CloudFront-Viewer-Address。

然后点击创建。

![](https://img.0pt.icu/learn/cloudfront-cdn-acme/15.png)

返回分配的这个页面，点击行为。

![](https://img.0pt.icu/learn/cloudfront-cdn-acme/16.png)

选中第一个，然后点击编辑。

![](https://img.0pt.icu/learn/cloudfront-cdn-acme/17.png)、

找到这个地方，将源请求策略换成刚才创建的那个。

![](https://img.0pt.icu/learn/cloudfront-cdn-acme/18.png)

保存更改。

转到服务器上。

在nginx配置的server块添加标头的相关配置。

```
set_real_ip_from 0.0.0.0/0;
real_ip_header CloudFront-Viewer-Address;
```

如果使用其他CDN，想显示真实ip，可以参考下面。

## Cloudflare

使用Cloudflare后，在Nginx配置中相应位置添加如下代码以获取用户真实IP

```
set_real_ip_from 0.0.0.0/0;
real_ip_header CF-Connecting-IP;
```

## Gcore CDN

可参考Gcore官方博文[https://gcore.com/docs/web-security/get-an-actual-ip-addresses-of-visitors-from-the-x-forward-for-header](https://lot.pm/go/?url=https://gcore.com/docs/web-security/get-an-actual-ip-addresses-of-visitors-from-the-x-forward-for-header)X-Real-Ip请求头似乎已经被Vercel弃用，或仅提供给付费用户。

```
set_real_ip_from 0.0.0.0/0;
real_ip_header X-Forwarded-For;
```

## AWS Cloudfront

需要利用到CloudFront-Viewer-Address请求头，但该请求头默认未启用，需手动前往Cloudfront控制面板开启。开启方法可参考[如何从CloudFront上获取客户端真实IP地址](https://lot.pm/go/?url=https://blog.bitipcman.com/get-client-ip-from-cloudfront-viewer-header/)。开启后，使用以下代码获取访客真实IP。

```
set_real_ip_from 0.0.0.0/0;
real_ip_header CloudFront-Viewer-Address;
```

## Netlify

Netlify不支持X-Forwarded-For请求头，获取访客真实IP需使用专属请求头X-Nf-Client-Connection-Ip。

```
set_real_ip_from 0.0.0.0/0;
real_ip_header X-Nf-Client-Connection-Ip;
```

## Vercel

Vercel支持多个请求头转发用户IP，分别是X-Forwarded-For，X-Vercel-Forwarded-For和X-Real-Ip，其中X-Forwarded-For和X-Real-Ip内容相同，X-Vercel-Forwarded-For大部分情况下内容和X-Forwarded-For以及X-Real-Ip相同。

**区别在于X-Forwarded-For和X-Real-Ip的值可以被覆盖，而X-Vercel-Forwarded-For不能。**

假设Vercel的CDN节点是A，那么访客B（IP:1.2.3.4）请求A节点，一般情况下X-Forwarded-For，X-Vercel-Forwarded-For和X-Real-Ip的结果就都是1.2.3.4，但是假如访客B向Vercel CDN节点发送了一个值为8.8.8.8的X-Forwarded-For请求头，那么X-Forwarded-For和X-Real-Ip的值将会被改为8.8.8.8，而X-Vercel-Forwarded-For则仍然是1.2.3.4。这也就是说X-Forwarded-For和X-Real-Ip有一定几率被伪造，所以除非你在Vercel前还用了另一个CDN/代理服务器，否则一般情况下用X-Vercel-Forwarded-For获取访客真实IP更保险。

## Bunny CDN

使用Bunny CDN获取访客真实IP，需要先在CDN面板关闭IP匿名化，关闭后使用以下代码获取访客真实IP。

```
set_real_ip_from 0.0.0.0/0;
real_ip_header X-Forwarded-For;
```

## 阿里云CDN

```
set_real_ip_from 0.0.0.0/0;
real_ip_header Ali-CDN-Real-IP;
```

## 其他CDN

除CDN厂商有特殊说明外，一般情况下使用X-Forwarded-For请求头获取访客IP。


```bash
acme.sh --installcert -d 0pt.icu \
--key-file   /var/lib/docker/volumes/nginx/_data/nginx/cert/0pt.icu.key \
--fullchain-file /var/lib/docker/volumes/nginx/_data/nginx/cert/0pt.icu.cer
```

## 参考
[使用CDN后，Nginx如何获取访客（客户端）真实IP](https://lot.pm/nginx-and-cdn-real-ip-address.html)
