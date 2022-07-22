---
title: "Catch and Redirect Panic"
date: 2018-07-30T22:11:59+08:00
draft: false
categories: ["Go"]
tags: ["panic"]
---

>面试的时候，面试官问程序panic了该怎么办；那就recover呀；后来想了下是不是守护进程呀。

那panic之后一般log会随着后台log一起打印，这样就不方便定位排查了。
将panic信息重定向输出到单独的文件，就方便啦。

由于Linux与Windows的差异导致syscall方法也不一致，代码如下：

- Linux

```
func Catch(path string) error {
	// Linux Uncomment
	file, err := os.OpenFile(path, os.O_RDWR|os.O_CREATE|os.O_APPEND, 0666)
	globalf = file
	if err != nil {
		return err
	}

	t := fmt.Sprintf("panic time: %s", time.Now().Format("2006-01-02 15:04:05"))
	file.Write([]byte(t))
	file.Write([]byte("\n"))

	if err = syscall.Dup2(int(file.Fd()), int(os.Stderr.Fd())); err != nil {
		return err
	}
	return nil
}
```

- Windows

```
func Catch(path string) error {
	// windows uncomment
	file, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_APPEND, 0666)
	globalf = file
	if err != nil {
		return err
	}

	t := fmt.Sprintf("panic time: %s", time.Now().Format("2006-01-02 15:04:05"))
	file.Write([]byte(t))
	file.Write([]byte("\r\n"))

	lp := syscall.NewLazyDLL(kdll).NewProc(ssh)

	seh := syscall.STD_ERROR_HANDLE
	v, _, err := lp.Call(uintptr(seh), uintptr(file.Fd()))
	if v == 0 {
		return err
	}
	return nil
}
```

没有想到好办法，在使用时屏蔽掉其他系统的代码即可。
[项目地址](https://github.com/itcuihao/gcrash)