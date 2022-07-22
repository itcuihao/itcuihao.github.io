---
title: "[译]Go代码审查意见"
date: 2022-06-11T09:49:33+08:00
draft: false
categories: ["Go"]
tags: ["Go", "wiki",  "译"]
toc: true
summary: "本页收集了审查Go代码时的常见解释，以便于通过速记来参考单一的详细解释。这是一份常见错误的清单，而不是一份全面的风格指南。"
---

---

>原文：[CodeReviewComments](https://github.com/golang/go/wiki/CodeReviewComments)

>自己水平有限，仅供参考，如有错误，请指正。联系方式可评论，或者邮件 itcuihao@gmail.com

本页收集了审查Go代码时的常见解释，以便于通过速记来参考单一的详细解释。这是一份常见错误的清单，而不是一份全面的风格指南。

你可以把它看作是[Effective Go](https://go.dev/doc/effective_go)的一个补充。

与测试有关的其他评论可在[Go Test Comments](https://github.com/golang/go/wiki/TestComments)找到。

在编辑这个页面之前，请[讨论修改](https://go.dev/issue/new?title=wiki%3A+CodeReviewComments+change&body=&labels=Documentation)，即使是小的修改。许多人都有意见，这里不是编辑战争的地方。

## 格式化

在你的代码上运行[gofmt](https://pkg.go.dev/cmd/gofmt/)，可以自动修复大部分的机械风格问题。几乎所有的Go代码都使用gofmt。本文档的其余部分将讨论非机械式风格问题。

另一种方法是使用[goimports](https://pkg.go.dev/golang.org/x/tools/cmd/goimports)，它是 `gofmt`的超集，可以根据需要增加（和删除）导入行。

<h1>zhushi</h1>
## 注释句子
见[Effective Go Commentary](https://go.dev/doc/effective_go#commentary)。记录声明的注释应该是完整的句子，即使这看起来有点多余。这种方法使它们在被提取到`godoc`文档中时格式化得很好。注释应该以被描述事物的名称开始，以句号结束。

```go
// Request represents a request to run a command.
type Request struct { ...

// Encode writes the JSON encoding of req to w.
func Encode(wo io.Writer, req *Request) { ...
```

以此类推。

## 上下文

context.Context类型的值携带安全证书、跟踪信息、最后期限和取消信号，跨越API和进程的界限。Go程序在整个函数调用链中明确地传递Context，从传入的RPC和HTTP请求到传出的请求。

大多数使用Context的函数应该接受它作为其第一个参数:

```
func F(ctx context.Context, /* other arguments */) {}
```

一个没有特定请求的函数可以使用context.Background()，但即使你认为不需要，也要在传递Context方面犯错。默认情况下是传递一个Context；只有在你有充分的理由说明它是错误的情况下才可以直接使用context.Background()。

不要给结构类型添加Context成员；而是给该类型上需要传递Context的每个方法添加一个ctx参数。有一个例外是那些签名必须符合标准库或第三方库中的接口的方法。

不要创建自定义的Context类型或在函数签名中使用其他的Context接口。

如果你有应用数据需要传递，把它放在一个参数中，放在接收器中，放在全局中，或者，如果真的需要，可以放在Context值中。

Context是不可改变的，所以可以传递同一个ctx，共享同一个截止日期、取消信号、凭证、父级跟踪等多个调用。

## 复制

为了避免意外的别名，在从其他包中复制结构时要小心。例如，bytes.Buffer类型包含一个`[]byte`切片。如果你拷贝一个`Buffer`，拷贝中的片断可能会与原结构中的数组产生别名，导致后续的方法调用产生意想不到的效果。

一般来说，如果一个`T`类型的值的方法与指针类型`*T`有关，就不要复制它。

## Rand加密

不要使用软件包`math/rand`来生成密钥，即使是用之便弃。不加种子，生成器是完全可预测的。用time.Nanoseconds()做种子，也只有几个比特的熵。相反，使用crypto/rand的Reader，如果你需要文本，打印成十六进制或base64。

```go
import (
	"crypto/rand"
	// "encoding/base64"
	// "encoding/hex"
	"fmt"
)

func Key() string {
	buf := make([]byte, 16)
	_, err := rand.Read(buf)
	if err != nil {
		panic(err)  // 超出随机性，绝不会发生
	}
	return fmt.Sprintf("%x", buf)
	// or hex.EncodeToString(buf)
	// or base64.StdEncoding.EncodeToString(buf)
}
```

## 声明空切片

在声明空片时，最好选择

```go
var t []string // t==nil
```

而不是

```go
t := []string{} // t!=nil
```

前者声明的是一个空的切片值，而后者是非空的，但长度为零。它们在功能上是等价的--它们的`len`和`cap`都是0--但是首选风格应该是空切片。

请注意，在有限的情况下，非0但0长度的切片是首选，比如在对JSON对象进行编码时（`nil`切片编码为`null`，而`[]string{}`编码为JSON数组`[]`）。

在设计接口时，避免区分nil切片和非nil的零长度切片，因为这可能会导致微妙的编程错误。

关于Go中nil的更多讨论，请参见Francesc Campoy的讲座[Understanding Nil](https://www.youtube.com/watch?v=ynoY2xz-F8s)。

## 文档注释

所有顶层的、导出的名字都应该有文档注释，正如非重要的未导出的类型或函数声明一样。关于注释惯例的更多信息，请参见[Effective Go Commentary](https://go.dev/doc/effective_go#commentary)。

## 不使用恐慌
见[Effective Go Errors](https://go.dev/doc/effective_go#errors)。不要在正常的错误处理中使用`panic`，使用错误和多个返回值。

## 错误字符串

错误字符串不应大写（除非以专有名词或缩略语开头），也不应以标点符号结尾，因为它们通常是在其他背景下打印的。也就是说，使用`fmt.Errorf("something bad")`而不是`fmt.Errorf("Something bad")`，这样`log.Printf("Reading %s: %v", filename, err)`的格式就不会在信息中间出现虚假的大写字母。这不适用于日志记录，因为日志记录是隐含的面向行的，并且不在其他消息内组合。

## 例子

当添加一个新的包时，包括预期使用的例子：一个可运行的例子，或者一个展示完整调用序列的简单测试。

阅读更多关于[可测试的Example()函数](https://go.dev/blog/examples)。

## Goroutine寿命

当你生成goroutine时，要清楚地说明它们何时（或是否）退出。

goroutine可以通过阻塞通道发送或接收而泄漏：即使被阻塞的通道无法到达，垃圾收集器也不会终止一个goroutine。

即使goroutine没有泄漏，当它们不再需要时，让它们继续飞行也会导致其他微妙的、难以诊断的问题。在封闭的通道上发送消息会引起恐慌。在 "不需要结果之后"修改仍在使用的输入，仍然会导致数据竞争。让goroutines在飞行中停留任意长的时间会导致不可预知的内存使用。

尽量保持并发代码的简单性，使goroutine的寿命足够明显。如果这不可行，就记录下goroutines退出的时间和原因。

## 处理错误

见[Effective Go Errors](https://go.dev/doc/effective_go#errors)。不要使用`_`变量丢弃错误。如果一个函数返回一个错误，检查它以确保函数成功。处理错误，返回错误，或者，在真正特殊的情况下，使用`panic`。

## 导入

避免重命名导入，除非是为了避免名称冲突；好的软件包名称不应该需要重命名。在发生碰撞的情况下，最好把本地的或项目特定的导入重命名。

导入是按组织分组的，它们之间有空行。标准库包总是在第一组。

```go
package main

import (
	"fmt"
	"hash/adler32"
	"os"

	"github.com/foo/bar"
	"rsc.io/goversion/version"
)
```

[goimports](https://pkg.go.dev/golang.org/x/tools/cmd/goimports)会为你做这个。

## 导入空

只为其副作用而导入的包（使用 `import _ "pkg"` 语法）应该只在程序的主包中导入，或者在需要它们的测试中导入。

## 导入点

`import .`形式在测试中可能很有用，由于循环依赖关系，不能成为被测试包的一部分。

```go
package foo_test

import (
	"bar/testutil" // also imports "foo"
	. "foo"
)
```

在这种情况下，测试文件不可能在包foo中，因为它使用了bar/testutil，它导入了foo。所以我们使用`import .`的形式，让文件假装是包foo的一部分，尽管它不是。除了这种情况，不要在你的程序中使用`import .`。它使程序更难阅读，因为它不清楚像Quux这样的名字是当前包中的顶级标识符还是导入包中的顶级标识符。

## 带内错误

在C语言和类似语言中，函数返回-1或null这样的值是很常见的，以示错误或丢失结果。

```go
// Lookup返回key的值，如果没有key的映射，则返回""。
func Lookup(key string) string

// 如果不检查带内错误值，就会导致错误。
Parse(Lookup(key))  //返回 "解析失败的值"，而不是 "没有键的值"
```

Go对多个返回值的支持提供了一个更好的解决方案。与其要求客户检查带内的错误值，一个函数应该返回一个额外的值来表明其其他返回值是否有效。这个返回值可以是一个错误，或者在不需要解释时是一个布尔值。它应该是最终的返回值。

```go
// Lookup返回key的值，如果没有key的映射，则ok=false。
func Lookup(key string) (value string, ok bool)
```

这可以防止调用者错误地使用返回结果。

```go
Parse(Lookup(key))  // 编译时错误
```

并鼓励更健壮和可读的代码。

```go
value, ok := Lookup(key)
if !ok {
	return fmt.Errorf("no value for %q", key)
}
return Parse(value)
```

这个规则适用于导出的函数，但对未导出的函数也很有用。

像`nil`、`""`、`0`和`-1`这样的返回值，当它们是一个函数的有效结果时，也就是说，调用者不需要对它们进行与其他值不同的处理。

一些标准库函数，如`strings`包中的函数，返回带内错误值。这大大简化了字符串处理的代码，但代价是要求程序员更加勤奋。一般来说`Go`代码应该为错误返回额外的值。

## 缩进错误流程

尽量使正常的代码路径保持最小的缩进，并缩进错误处理，首先处理它。这可以提高代码的可读性，因为它允许在视觉上快速扫描正常路径。

例如，不要写:

```go
if err != nil {
	// 错误处理
} else {
	// 正常代码
}
```

相反的，应该是：

```go
if err != nil {
	// 错误处理
	return // 或者continue等
}
// 正常代码
```

如果`if`语句有一个初始化语句，如：

```go
if x, err := f(); err != nil {
	// 错误处理
	return
} else {
	// 使用 x
}
```

那么这可能需要将短变量声明移到它自己的一行。

```go
x, err := f()
if err != nil {
	// 错误处理
	return
}
// 使用 x
```

## 首字母缩写

名称中的单词如果是首字母缩写或缩略语（如 “URL”或 “NATO”），其大小写要一致。例如，“URL”应显示为 “URL”或“url”（如 “urlPony”，或“URLPony”），而不是 “Url”。作为一个例子。ServeHTTP不是ServeHttp。对于有多个初始化“词” 的标识符，使用例如 “xmlHTTPRequest”或 “XMLHTTPRequest”。

这个规则也适用于 "ID"，当它是 "标识符 "的简称时（这几乎是所有的情况，当它不是 "自我"、"超我 "中的 "ID "时），所以写 "appID "而不是 "appId"。

由协议缓冲区编译器生成的代码不受这一规则影响。人写的代码要比机器写的代码有更高的标准。

## 接口

Go接口通常属于使用接口类型值的包，而不是实现这些值的包。实现包应该返回具体的（通常是指针或结构体）类型：这样一来，新的方法可以被添加到实现中，而不需要大量的重构。

不要在API的实现者一方定义接口，“为了嘲弄”；相反，要设计API，使其可以使用真正实现的公共API来测试。

不要在使用之前就定义接口：如果没有一个真实的使用例子，就很难看出一个接口是否有必要，更不用说它应该包含哪些方法。

```go
package consumer  // consumer.go

type Thinger interface { Thing() bool }

func Foo(t Thinger) string { … }
```

```go
package consumer // consumer_test.go

type fakeThinger struct{ … }
func (t fakeThinger) Thing() bool { … }
…
if Foo(fakeThinger{…}) == "x" { … }
```

```go
// 不要这么做！！！
package producer

type Thinger interface { Thing() bool }

type defaultThinger struct{ … }

func (t defaultThinger) Thing() bool { … }

func NewThinger() Thinger { return defaultThinger{ … } }
```

而是返回一个具体的类型，让消费者模拟生产者的实现。

```go
package producer

type Thinger struct{ … }

func (t Thinger) Thing() bool { … }

func NewThinger() Thinger { return Thinger{ … } }
```

## 行长度

Go代码中没有严格的行长限制，但要避免令人不舒服的长行。同样地，如果行的长度更容易阅读，就不要添加换行符来保持短行，例如，如果它们是重复的。

大多数时候，当人们“不自然地”换行时（在函数调用或函数声明的中间，或多或少，比如说，尽管周围有一些例外），如果他们有合理数量的参数和合理短的变量名称，换行是不必要的。长行似乎与长名字相伴，摆脱长名字有很大的帮助。

换句话说，断行是因为你所写的内容的语义（作为一般规则），而不是因为行的长度。如果你发现这样做产生的行太长，那么改变名称或语义，你可能会得到一个好结果。

实际上，这与关于一个函数应该有多长的建议完全一样。没有“永远不要让一个函数超过N行”的规则，但绝对存在一个太长的函数，以及太多重复的小函数，解决方法是改变函数边界的位置，而不是开始计算行数。

## 混杂大写字母

见[Effective Go Mixed Caps](https://go.dev/doc/effective_go#mixed-caps)。即使打破了其他语言的惯例，这也适用。例如，一个未导出的常量是`maxLength`而不是`MaxLength`或`MAX_LENGTH`。

另见[首字母缩写](https://github.com/golang/go/wiki/CodeReviewComments#initialisms)。

## 命名返回参数

考虑一下它在godoc中会是什么样子。命名返回参数如：

```go
func (n *Node) Parent1() (node *Node) {}
func (n *Node) Parent2() (node *Node, err error) {}
```

在godoc中会有重复，最好使用:

```go
func (n *Node) Parent1() *Node {}
func (n *Node) Parent2() (*Node, error) {}
```

另一方面，如果一个函数返回两个或三个相同类型的参数，或者一个结果的含义在上下文中并不清楚，那么在某些情况下添加名称可能是有用的。不要为了避免在函数中声明一个var而对返回参数进行命名；这样做是以不必要的API的冗长为代价来换取一个小的实现的简洁性。

```go
func (f *Foo) Location() (float64, float64, error)
```

不如：

```go
// Location返回f的纬度和经度。
// 负值分别意味着南边和西边。
func (f *Foo) Location() (lat, long float64, err error)
```

如果函数只有寥寥几行，裸返是可以的。一旦它是一个中等规模的函数，就要明确你的返回值。推论：为了使用裸返，而去命名返回参数，是不值得的。文档的清晰性总是比在你的函数中节省一两行更重要。

最后，在某些情况下，你需要命名一个结果参数，以便在一个延迟闭包中改变它。这是一直可以的。

>裸返：使用命名返回参数后，返回语句通常称为裸返或裸返回。

## 裸返回

一个没有参数的返回语句会返回指定的返回值。这就是所谓的“裸”返回。

```go
func split(sum int) (x, y int) {
	x = sum * 4 / 9
	y = sum - x
	return
}
```
见[命名返回参数](https://github.com/golang/go/wiki/CodeReviewComments#named-result-parameters)。

## 包注释

包注释，像所有由godoc呈现的注释一样，必须出现在包子句的旁边，不能有空行。

```go
// math包提供基本的常数和数学函数。
package math
```

```go
/*
template包实现了数据驱动的模板，用于生成HTML等文本输出。
输出，如HTML。
....
*/
package template
```

对于`package main`的注释，其他样式的注释在二进制名称后面也是可以的（如果它在前面，可以大写），例如，对于目录`seedgen`中的`package main`，你可以写。

```go
// Binary seedgen ...
package main
```

或者

```go
// Command seedgen ...
package main
```

或者

```go
// Program seedgen ...
package main
```

或者

```go
// The seedgen command ...
package main
```

或者

```go
// The seedgen program ...
package main
```

或者

```go
// Seedgen ..
package main
```

这些都是例子，合理的变体也是可以接受的。

请注意，以小写字母开始的句子不在软件包注释可接受的选项之列，因为这些注释是公开可见的，应该用正确的英语书写，包括将句子的第一个单词大写。当二进制名称是第一个词时，即使它与命令行调用的拼写不严格匹配，也需要大写。


关于注释惯例的更多信息，见[Effective Go Commentary](https://go.dev/doc/effective_go#commentary)。

## 传递值

不要为了节省几个字节而将指针作为函数参数传递。如果一个函数自始至终只把它的参数`x`称为`*x`，那么这个参数就不应该是一个指针。常见的例子包括传递一个指向字符串（`*string`）的指针或一个指向接口值（`*io.Reader`）的指针。在这两种情况下，值本身是一个固定的大小，可以直接传递。这个建议不适用于大型结构体，甚至是可能增长的小型结构体。

## 接收者名称

一个方法的接收者的名字应该反映它的身份；通常一个或两个字母的类型缩写就足够了（如“c”或“cl”代表 “客户”）。不要使用诸如 “me”、“this”或“self ”这样的通用名称，这些是面向对象语言的典型标识，它们赋予了方法以特殊的含义。在Go中，一个方法的接收者只是另一个参数，因此，应该相应的命名。这个名字不需要像方法参数那样具有描述性，因为它的作用是显而易见的，而且没有任何记录性的作用。它可以非常简短，因为它几乎会出现在该类型的每一个方法的每一行中；熟悉的东西就是简洁的。也要保持一致：如果你在一个方法中称接收器为“c”，不要在另一个方法中称它为 “cl”。

## 接收器类型

选择在方法上使用值接收器还是指针接收器可能很困难，特别是对新的Go程序员来说。如果有疑问，请使用指针，但有时值接收器是有意义的，通常是出于效率的考虑，如小型不变的结构或基本类型的值。一些有用的准则：

- 如果接收器是一个map、func或chan，不要使用一个指针。如果接收方是一个片断，并且该方法没有对切片进行重新划分或重新分配，就不要使用指向它的指针。
- 如果方法需要变动接收器，接收器必须是一个指针。
- 如果接收器是一个包含`sync.Mutex`或类似同步字段的结构，接收器必须是一个指针以避免复制。
- 如果接收器是一个大的结构体或数组，那么指针式的接收器会更有效。多大才算大？假设它相当于把所有的元素作为参数传递给方法。如果这感觉太大，那么对于接收器来说也是太大了。
- 函数或方法，无论是并发的还是从这个方法中调用的，都会对接收器进行变更吗？当方法被调用时，一个值类型会创建一个接收器的副本，所以外部的更新不会被应用到这个接收器上。如果变化必须在原始接收器中可见，接收器必须是一个指针。
- 如果接收方是一个结构体、数组或切片，并且它的任何元素是一个指向可能发生变化的东西的指针，那么最好是一个指针式的接收方，因为它将使读者更清楚地了解其意图。
- 如果接收器是一个小的数组或结构，自然是一个值类型（例如，`time.Time`类型），没有可变的字段，也没有指针，或者只是一个简单的基本类型，如`int`或`string`，值接收器是有意义的。一个值接收器可以减少可能产生的垃圾量；如果一个值被传递给一个值方法，可以使用堆上拷贝而不是在堆上分配。(编译器试图聪明地避免这种分配，但它不可能总是成功）。在没有进行分析之前，不要因为这个原因选择一个值接收器类型。
- 不要混用接收器类型。为所有可用的方法选择指针或结构类型。

最后，当有疑问时，使用指针型接收器。

## 有用的测试失败

测试失败时应提供有用的信息，说明什么地方出了问题，用什么输入，实际得到了什么，以及预期得到了什么。写一堆assertFoo助手可能是很诱人的，但要确保你的助手产生有用的错误信息。假设调试你失败的测试的人不是你，也不是你的团队。一个典型的Go测试失败的情况如下

```go
if got != tt.want {
	t.Errorf("Foo(%q) = %d; want %d", tt.in, got, tt.want) // 或者 Fatalf, 如果测试不能通过
})
```

注意，这里的顺序是`实际`!= `预期`，而且消息也使用这个顺序。有些测试框架鼓励把这些东西倒过来写：`0 != x`，"预期0，得到x"，以此类推。Go则不然。

如果这看起来像大量的输入，你可能想写一个[表驱动测试](https://github.com/golang/go/wiki/TableDrivenTests)。

在使用不同输入的测试助手时，另一个常见的技术是用不同的TestFoo函数来包装每个调用者，从而使测试以该名称失败。

```go
func TestSingleValue(t *testing.T) { testHelper(t, []int{80}) }
func TestNoValues(t *testing.T)    { testHelper(t, []int{}) }
```

在任何情况下，你都有责任在失败时给将来调试你的代码的人一个有用的信息。

## 变量名称

Go中的变量名应该是短的而不是长的。这对范围有限的局部变量来说尤其如此。倾向于用`c`表示`lineCount`。倾向于用`i`来表示`sliceIndex`。

基本规则：名字使用的时间离其声明越远，名字的描述性越强。对于一个方法接收器来说，一个或两个字母就足够了。常见的变量，如循环索引和读取器可以是一个字母（`i`，`r`）。更加不寻常的东西和全局变量需要更多的描述性名称。