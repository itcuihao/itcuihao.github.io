---
title: "[译]Go并发代码审查"
date: 2022-06-11T12:44:51+08:00
draft: false
categories: ["Go"]
tags: ["Go", "wiki", "译"]
summary: "本页是对Go代码审查意见列表的补充。这个列表的目的是为了帮助在审查Go代码时发现与并发有关的bug。"
---

---

>原文：[CodeReviewConcurrency](https://github.com/golang/go/wiki/CodeReviewConcurrency)

>自己水平有限，仅供参考，如有错误，请指正。联系方式可评论，或者邮件 itcuihao@gmail.com

本页是对Go代码审查意见列表的补充。这个列表的目的是为了帮助在审查Go代码时发现与并发有关的bug。

你也可以只读一遍这个列表，以刷新你的记忆，并确保你知道所有这些并发性的问题。

*⚠️这个页面是由社区撰写和维护的。它包括有争议的信息，可能会有误导或不正确。*

---

不充分的同步性和竞争条件

- [HTTP处理函数是线程安全的吗？](https://github.com/golang/go/wiki/CodeReviewConcurrency#http-handlers)
- [全局函数和变量受到突变器的保护或其他线程安全的保护？](https://go.dev/doc/articles/race_detector#Unprotected_global_variable)
- [对字段和变量的读取是受保护的？](https://github.com/golang/go/wiki/CodeReviewConcurrency#sync-balance)
- [循环变量作为参数传入goroutine函数？](https://go.dev/doc/articles/race_detector#Race_on_loop_counter)
- [线程安全类型的方法不返回指向受保护结构的指针？](https://github.com/golang/go/wiki/CodeReviewConcurrency#return-pointer)
- [在`Load()`之后对`sync.Map`的`Load()`或`Delete()`调用不是一个竞争条件？](https://github.com/golang/go/wiki/CodeReviewConcurrency#sync-map-race)

测试

- [在CI/CD中用`-race`标志运行测试？](https://go.dev/doc/articles/race_detector)

可扩展性

- [故意创建一个容量为零的通道？](https://github.com/golang/go/wiki/CodeReviewConcurrency#zero-cap-ch)
- [没有使用`sync.RWMutex`来保护非常短的操作？](https://github.com/golang/go/wiki/CodeReviewConcurrency#rwmutex)

时间

- [停止`time.Ticker`使用`defer tick.Stop()`？](https://github.com/golang/go/wiki/CodeReviewConcurrency#ticker-stop)
- [比较`time.Time`使用`Equal()`而不是`==`？](https://github.com/golang/go/wiki/CodeReviewConcurrency#time-eq)
- [在`time.Time`的参数`time.Since()`中保持单调的成分？](https://github.com/golang/go/wiki/CodeReviewConcurrency#time-since)
- [通过`t.Before(u)`比较系统时间时，将单调成分从参数中剥离？](https://github.com/golang/go/wiki/CodeReviewConcurrency#time-before)

## 不充分的同步性和竞争条件

### 从多个goroutine并发调用HTTP处理函数是否安全？

我们很容易忽视HTTP处理程序应该是线程安全的，因为它们通常不是从项目代码的任何地方明确调用的，而只是从HTTP服务器的内部调用。

### 未保护的变量

是否有一些不受`mutex`保护的字段或变量访问，其中字段或变量是一个原始的或不明确的线程安全的类型（如atomic.Value），而这个字段可以从一个并发的goroutine中更新？由于非原子的硬件写入和潜在的内存可见性问题，即使对原始变量跳过同步读取也是不安全的。

也请看典型的数据竞赛：[原始的不受保护的变量](https://go.dev/doc/articles/race_detector#Primitive_unprotected_variable)。

### 未保护的指针

一个线程安全类型的方法没有返回一个指向受保护结构的指针？这是一个微妙的bug，它导致了前一项中描述的不受保护的访问问题。例子：

```go
type Counters struct {
	mu   sync.Mutex
	vals map[Key]*Counter
}

func (c *Counters) Add(k Key, amount int) {
    c.mu.Lock()
    defer c.mu.Unlock()
    count, ok := c.vals[k]
    if !ok {
    	count = &Counter{sum: 0, num: 0}
    	c.vals[k] = count
    }
    count.sum += amount
    count.n += 1
}

func (c *Counters) GetCounter(k Key) *Counter {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.vals[k] // BUG! 返回一个指向结构的指针，该结构必须被保护。
}
```

一个可能的解决方案是在`GetCounter()`中返回一个拷贝，而不是一个指向结构的指针。

```go
type Counters struct {
    mu   sync.Mutex
    vals map[Key]Counter // 注意，现在我们是直接存储计数器，而不是指针。
}

...

func (c *Counters) GetCounter(k Key) (count Counter, exists bool) {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.vals[k]
}
```

###

如果有一个以上的`goroutine`可以更新一个`sync.Map`，你不会根据之前`m.Load()`调用的成功与否来调用`m.Store()`或`m.Delete()`？换句话说，下面的代码是饶舌的。

```go
var m sync.Map

// 可以从多个goroutine中同时调用
func DoSomething(k Key, v Value) {
	existing, ok := m.Load(k)
	if !ok {
		m.Store(k, v) // 竞争条件——两个goroutines可以并行地执行这个程序
		... 一些其他的逻辑，假设`k`中的值现在是映射中的`v`。
    }
    ...
}
```

这样的竞争条件在某些情况下可能是良性的：例如，`Load()`和`Store()`调用之间的逻辑是计算要缓存在映射中的值，这种计算总是返回相同的结果，不会产生副作用。

>⚠️可能会有误导性的信息。"竞赛条件 "可以指逻辑错误，就像这个例子一样，它可能是良性的。但这个短语也常用于指违反内存模型的情况，而这绝不是良性的。

如果竞赛条件不是良性的，请使用`sync.Map.LoadOrStore()`和`LoadAndDelete()`方法来修复它。

## 扩展性

### 通道

创建一个零容量的通道，就像`make(chan *Foo)`一样，这是故意的吗？一个向零容量通道发送消息的`goroutine`会被阻塞，直到另一个`goroutine`收到这个消息。在`make()`调用中省略容量可能只是一个错误，这将限制代码的可扩展性，而且很可能单元测试不会发现这样的错误。

>⚠️误导性的信息。缓冲通道与非缓冲通道相比，本质上没有增加 "可扩展性"。然而，缓冲通道可以很容易地掩盖死锁和其他基本的设计错误，而这些错误在非缓冲通道中会立即显现。

### 锁

与普通的`sync.Mutex`相比，用`sync.RWMutex`锁定会产生额外的开销，此外，目前[Go中RWMutex的实现可能存在一些扩展性问题](https://github.com/golang/go/issues/17973)。除非情况非常明确（比如一个`RWMutex`用于同步许多只读操作，每个操作持续数百毫秒或更多，而需要独占锁的写操作很少发生），否则应该有一些基准来证明`RWMutex`确实有助于提高性能。一个典型的例子是，RWMutex肯定是弊大于利的，那就是对一个结构中的变量的简单保护。

```go
type Box struct {
	mu sync.RWMutex // 不要这样做 -- 利用Mutex代替
	x  int
}

func (b *Box) Get() int {
	b.mu.RLock()
	defer b.mu.RUnlock()
	return b.x
}

func (b *Box) Set(x int) {
	b.mu.Lock()
	defer b.mu.Unlock()
	b.x = x
}
```

## 时间

### 定时器

`Time.Ticker`是否使用`defer tick.Stop()`停止？
当循环中使用`ticker`的函数返回时，不停止`ticker`是一种内存泄漏。

### 时间比较

`time.Time`结构是否使用`Equal()`方法进行比较，而不仅仅是`==`？
引用[`time.Time`的文档](https://pkg.go.dev/time/#Time)。

>请注意，Go `==`操作符不仅要比较时间瞬间，还要比较位置和单调的时钟读数。因此，如果不首先保证所有值都设置了相同的`Location`（可以通过使用`UTC()`或`Local()`方法来实现），并且通过设置`t = t.Round(0)`来剥离单调的时钟读数，则不应将时间值用作地图或数据库键。一般来说，首选`t.Equal(u)`而不是`t == u`，因为`t.Equal()`使用了最精确的比较，并且正确处理了只有一个参数有单调时钟读数的情况。

### time.Since

在调用`time.Since(t)`之前，单调成分没有从t中剥离出来？这是上一条的结果。如果在调用`time.Since()`函数之前（通过调用`UTC()`、`Local()`、`In()`、`Round()`、`Truncate()`或`AddDate()`）将单调成分从`time.Time`结构中剥离，那么在很多情况下`time.Since()`的结果可能是负数，例如在最初获得起始时间和调用`time.Since()`的时刻之间，系统时间已经通过`NTP`进行了同步。如果单调成分没有被剥离，`time.Since()`将总是返回一个正的持续时间。

### time.Before

如果你想通过`t.Before(u)`来比较系统时间，你是否从参数中剥离单调成分，例如通过`u.Round(0)`？这是与[时间比较](#时间比较)相关的另一点。有时，您需要仅通过存储在其中的系统时间来比较两个`time.Time`结构，具体而言。在将这些时间结构之一存储在磁盘上或通过网络发送之前，您可能需要这样做。例如，想象一下某种遥测代理，它定期将遥测指标和时间一起推送给某个远程系统。

```go
var latestSentTime time.Time

func pushMetricPeriodically(ctx context.Context) {
	t := time.NewTicker(time.Second)
	defer t.Stop()
	for {
		select {
		case <-ctx.Done: return
		case <-t.C:
			newTime := time.Now().Round(0) // 剥离单调成分，只比较系统时间
			// 检查新的时间是否较晚，以避免在系统时间向后设置时扰乱遥测数据。
            // 在NTP同步时向后设置。
			if latestSentTime.Before(newTime) {
				sendOverNetwork(NewDataPoint(newTime, metric()))
				latestSentTime = newTime
			}
		}
	}
}
```

如果不调用`Round(0)`，即剥去单调成分，这段代码就会出错。

## 阅读列表

[Go代码审查意见](https://github.com/golang/go/wiki/CodeReviewComments)：审查Go代码的检查表，不针对并发性。

Go并发性：

- [Go内存模型](https://go.dev/ref/mem)
- [《Effective Go》中关于并发性的部分](https://go.dev/doc/effective_go#concurrency)
- Go博客中的帖子。
    - [通过交流分享内存](https://go.dev/blog/codelab-share)
    - [Go并发模式：计时，继续](https://go.dev/blog/concurrency-timeouts)
    - [Go并发模式：上下文](https://go.dev/blog/context)
    - [Go并发模式：管线和取消](https://go.dev/blog/pipelines)
    - [高级Go并发模式](https://go.dev/blog/io2013-talk-concurrency)（视频）
    - [重新思考经典的并发模式](https://www.youtube.com/watch?v=5zXAHh5tJqQ)（视频）
- [了解现实世界中Go的并发性错误](https://songlh.github.io/paper/go-study.pdf)

并发，但不是针对Go的：

[Mechanical Sympathy：单写者原则](https://mechanical-sympathy.blogspot.com/2011/09/single-writer-principle.html)