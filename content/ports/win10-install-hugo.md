---
title: "Win10 Install Hugo"
date: 2019-04-14T10:47:50+08:00
draft: false

categories: ["随记"]
tags: ["hugo"]
---

# install choco

打开PowerShell，粘贴下面的命令，回车。

```
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
```

[参考链接](https://chocolatey.org/install#installing-chocolatey)

# install hugo

```
choco install hugo -confirm
```

[参考链接](https://gohugo.io/getting-started/installing/)

