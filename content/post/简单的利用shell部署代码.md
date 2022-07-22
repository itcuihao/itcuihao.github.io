---
title: "简单的利用shell部署代码💻"
date: 2018-07-22T18:22:23+08:00
draft: false

categories: ["Linux"]
tags: ["Shell"]
---

（一）介绍

>公司现在开发、测试、运维渐渐地有规模了，因此各个环境也应该相对独立。开发提交代码到develop分支后，发布开发环境，查看修改效果，确认无误，然后提交PR。运维拉取测试分支，发布测试环境，专供测试组使用。

现在分成三个脚本，大致目录结构如下:

```

root@ubuntu:/home/xg# tree -L 2
.
├── deploy.sh
├── release.sh
├── start.sh
├── tmp
│   ├── static
│   └── web
├── qddx
│   ├── conf
│   ├── qddx_out.log
│   ├── qddx_web
│   └── static
├── qdlg
│   ├── conf
│   ├── qdlg_out.log
│   ├── qdlg_web
│   └── static
├── tyxy
│   ├── conf
│   ├── tyxy_out.log
│   ├── tyxy_web
│   └── static
└── xg_code
    ├── bin
    ├── pkg
    └── src
```

 1. deploy.sh 从码云拉取代码，前端代码拷贝到 tmp/static 目录下；后端代码在 xg_code 中，编译到 tmp/ 下，命名为 web；
 1. release.sh 选择需要部署的文件夹名称，qddx/qdlg/tyxy 根据文件夹名称，将前后端文件拷贝到目录下;
 1. start.sh 输入需要启动的选项的文件夹名称启动对应的项目;

（二）脚本详细

1.DEPLOY.SH

```
#!/bin/bash
echo -e "\033[45;37m 部署测试学工系统\033[0m"
xg="/home/xg/tmp"
code_path="/home/xg/xg_code/src"
echo -e "\033[33m 拉取代码ing ...\033[0m"
cd $code_path/AntLinkCampus
git pull origin develop
echo -e "\033[33m 拷贝前端文件\033["
echo -e "\033[31m 拷贝ing... \033[0m"
rm -rf $xg/static/*
cp -a $code_path/AntLinkCampus/CampusUI/static $xg
cd $xg
echo -e "\033[33m 编译后端文件 \033[0m"
echo -e "\033[31m 编译ing ... \033[0m"
go build -i -v -ldflags "-w -s" -o $xg/web AntLinkCampus/CampusServer/apps/web
echo -e "\033[32m 编译完成 \033[0m"
echo -e "\033[32m 运行 release.sh 运行程序\033[0m"
```

2.RELEASE.SH

```
#!/bin/bash
echo -e "\033[45;37m 发布测试学工系统\033[0m"
echo -e "\033[34;42m 请选择学校（输入大学首字母）：\033[0m"
echo -e "\033[33;44m 青岛大学：qddx \033[0m"
echo -e "\033[33;44m 体育学院：tyxy\033[0m"
echo -e "\033[33;44m 青岛理工大学：qdlg\033[0m"
read -p "输入：" school
if [ "$school"x = "qddx"x ]
then
    echo -e "\033[32m开始部署青岛大学\033[0m"
elif [ "$school"x = "tyxy"x ]
then
    echo -e "\033[32m开始部署体育学院\033[0m"
elif [ "$school"x = "qdlg"x ]
then
    echo -e "\033[32m开始部署青岛理工大学\033[0m"
else
    echo -e "\033[41;37m没有此学校\033[0m"
    exit
fi
xg="/home/xg/"$school
tmp="/home/xg/tmp"
echo -e "\033[33m 拷贝前端文件\033[0m"
echo -e "\033[31m 拷贝ing... \033[0m"
rm -rf $xg/static/*
cp -a $tmp/static $xg
echo -e "\033[33m 拷贝后端文件\033[0m"
echo -e "\033[31m 拷贝ing... \033[0m"
web_pid=$(pgrep -f ${school}_web)
echo -e "\033[41;37m PID: ${web_pid} \033[0m"
if [ "$web_pid"x = x ]
then
    echo -e "\033[33m 移动后端文件\033[0m"
    cp $tmp/web $xg/${school}_web
    echo -e "\033[41;37m 请执行 start.sh 运行程序\033[0m"
else
echo -e "\033[33m 拷贝后端文件\033[0m"
    kill -9 $web_pid
    sleep 2s
    cp $tmp/web $xg/${school}_web
    echo -e "\033[41;37m 请执行 start.sh 运行程序\033[0m"
fi
```

3.START.SH

```
#!/bin/bash
echo -e "\033[45;37m 启动测试学工系统\033[0m"
echo -e "\033[34;42m 请选择学校（输入大学首字母）：\033[0m"
echo -e "\033[33;44m 青岛大学：qddx \033[0m"
echo -e "\033[33;44m 体育学院：tyxy\033[0m"
echo -e "\033[33;44m 青岛理工大学：qdlg\033[0m"
xg="/home/xg"
read -p "输入：" school
nohupweb(){
    cd $xg/$school
    nohup ./${school}_web > "${school}_out.log" 2>&1 &
    echo -e "\033[42;37m启动完成\033[0m"
}
if [ "$school"x = "qddx"x ]
then
    echo -e "\033[32m开始启动青岛大学\033[0m"
    nohupweb
elif [ "$school"x = "tyxy"x ]
then
    echo -e "\033[32m开始启动体育学院\033[0m"
    nohupweb
elif [ "$school"x = "qdlg"x ]
then
    echo -e "\033[32m开始启动青岛理工大学\033[0m"
    nohupweb
else
    echo -e "\033[41;37m没有此学校\033[0m"
    exit
fi
```

(三)Nginx代理

```nginx
#青岛大学学工系统代理配置
   server {
       #全局域
       listen       8088;
       server_name  localhost;
       #charset koi8-r;
       #access_log  logs/host.access.log  main;
       location /nginx {
           root   html;
           index  index.html index.htm;
       }
       #后台服务
       location /web {
          proxy_pass    http://127.0.0.1:8086;
       }
       location /api {
          proxy_pass    http://127.0.0.1:8086;
       }
       #前端web应用
       location / {
          root /home/xg/qddx/static;
          index login.html index.html index.htm;
       }
       #error_page  404              /404.html;
       # redirect server error pages to the static page /50x.html
       #
       error_page   500 502 503 504  /50x.html;
       location = /50x.html {
           root   html;
       }
   }
#体育学院学工系统代理配置
   server {
       #全局域
       listen       8089;
       server_name  localhost;
       #charset koi8-r;
       #access_log  logs/host.access.log  main;
       location /nginx {
           root   html;
           index  index.html index.htm;
       }
       #后台服务
       location /web {
          proxy_pass    http://127.0.0.1:8087;
       }
       location /api {
          proxy_pass    http://127.0.0.1:8087;
       }
       #前端web应用
       location / {
          root /home/xg/tyxy/static;
          index login.html index.html index.htm;
       }
       #error_page  404              /404.html;
       # redirect server error pages to the static page /50x.html
       #
       error_page   500 502 503 504  /50x.html;
       location = /50x.html {
           root   html;
       }
   }
#青岛理工大学学工系统代理配置
   server {
       #全局域
       listen       8084;
       server_name  localhost;
       #charset koi8-r;
       #access_log  logs/host.access.log  main;
       location /nginx {
           root   html;
           index  index.html index.htm;
       }
       #后台服务
       location /web {
          proxy_pass    http://127.0.0.1:8082;
       }
       location /api {
          proxy_pass    http://127.0.0.1:8082;
       }
       #前端web应用
       location / {
          root /home/xg/qdlg/static;
          index login.html index.html index.htm;
       }
       #error_page  404              /404.html;
       # redirect server error pages to the static page /50x.html
       #
       error_page   500 502 503 504  /50x.html;
       location = /50x.html {
           root   html;
       }
   }
```

>现在项目已经可以启动了，这次对环境是如何部署的有了初步了解，也学习了 Shell的编写，nohup后台启动