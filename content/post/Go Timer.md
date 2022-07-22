---
title: "Go Timer"
date: 2021-12-11T21:59:22+08:00
draft: false
categories: ["Go"]
tags: ["Go", "timer"]
summary: "定时器是经常使用的"
---

假如有需求需要定时执行某一程序，会用到定时器，不过在设置定时器后想主动取消，就需要借助下context。

Go Timer 主动停止

```go
package main

import (
   "context"
   "fmt"
   "runtime/debug"
   "sync"
   "time"
)

func main() {

   mt := timerTest()
   time.Sleep(time.Second * 30)
   for i, tt := range mt.c {
      fmt.Printf("k: %v, ti: %#v\n", i, tt)
   }
   fmt.Printf("k: %v, ti: %#v\n", "all", mt)
}

type mtimer struct {
   c  map[int]*context.CancelFunc
   rw sync.RWMutex
}

func timerC(mt *mtimer, i int) {
   defer func() {
      if err := recover(); err != nil {
         fmt.Println("i am recover" + string(debug.Stack()))
         fmt.Println(err)
      }
   }()
   t := time.NewTimer(time.Duration(i) * time.Second)
   ctx, cancel := context.WithCancel(context.Background())
   mt.rw.Lock()
   mt.c[i] = &cancel
   mt.rw.Unlock()
   select {
   case <-t.C:
      fmt.Printf("print: %d timer\n", i)
   case <-ctx.Done():
      fmt.Printf("print: %d stop\n", i)
      t.Stop()
      fmt.Printf("print: %d cancel\n", i)
      return
   }
}

//timerTest
func timerTest() mtimer {
   defer func() {
      if err := recover(); err != nil {
         fmt.Println("i am recover" + string(debug.Stack()))
         fmt.Println(err)
      }
   }()
   mt := mtimer{
      c: make(map[int]*context.CancelFunc),
   }

   for i := 1; i <= 5; i++ {
      go func(i int) {
         fmt.Printf("timer start: %v\n", i)
         timerC(&mt, i)
      }(i)
   }
   time.Sleep(time.Second * 1)
   i := 3
   fmt.Printf("start stop: %d\n", i)
   cancel := *mt.c[i]
   cancel()
   fmt.Printf("stop: %d\n", i)
   return mt
}
```

