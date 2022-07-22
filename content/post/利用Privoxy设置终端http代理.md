---
title: "利用Privoxy设置终端http代理🚀"
date: 2018-07-22T19:10:51+08:00
draft: false

categories: ["Linux"]
tags: ["代理"]
---

>使用 [Privoxy](http://www.privoxy.org/) 将sock5代理映射为http代理

 1.安装Privoxy

```
sudo apt-get update
sudo apt-get install privoxy
```

 2.配置Privoxy

`vim /etc/privoxy/config`

>查找 listen-address,注释掉(vim 查找 /listen-address)

```
#listen-address  127.0.0.1:8118
#listen-address  [::1]:8118
在最后一行后边加上
forward-socks5 / 127.0.0.1:1080 .
listen-address 127.0.0.1:1081
```

 3.重启Privoxy

根据系统不同使用不同命令

```
sudo service privoxy restart
或者
sudo systemctl restart privoxy
```

 4.终端设置

这样就完成了sock5到http代理的映射,然后就可以配置终端代理

对当前终端有效

```
export http_proxy=http://127.0.0.1:1081
export https_proxy=http://127.0.0.1:1081
```

测试是否生效

```
curl www.google.com
看是否有数据返回
```

取消设置

```
unset http_proxy
unset https_proxy
```

可以加入 .bash_profile，添加别名，方便使用

```
vim ~/.bash_profile
alais chproxy="export http_proxy=http://127.0.0.1:1081 && export https_proxy=http://127.0.0.1:1081"
alais unchproxy="unset http_proxy && unset https_proxy"
source ~/.bash_profile
```

 5.卸载

`sudo apt-get remove privoxy`

⇲带飞

别人想访问 Google，利用SwitchyOmega

provixy配置：

```
vim /etc/privoxy/config
listen-address 0.0.0.0:1081
sudo systemctl restart privoxy
```

然后让别人利用 SwitchyOmega 与我连接同一网络，
新建情景模式

```
参数 | 值
---|---
代理规则 | http
代理地址| ifconfig查看
代理端口| 1081
```

如果别人想终端走你的代理

```
那么两人需要连接同一网络，查看自己的IP，让他在终端执行
export http_proxy=http://ip:1081 && export https_proxy=http://ip:1081
```