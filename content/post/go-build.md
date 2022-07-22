---
title: "Go Build"
date: 2021-12-19T23:16:12+08:00
draft: false
categories: ["Go"]
tags: ["Go", "command"]
summary: "Go常利用此命令进行编译打包"
---

---
在Go中利用此命令进行编译打包

>go build [-o output] [build flags] [packages]

利用build编译时，会忽略`_test.go`结尾的文件；

build时会默认使用文件名作为编译后的名字，如果是windows平台，则会添加exe的后缀。

`-o` 标识指定编译后文件的输出位置以及文件名；

## 解释

```go
-a
	force rebuilding of packages that are already up-to-date.
-n
	print the commands but do not run them.
-p n
	the number of programs, such as build commands or
	test binaries, that can be run in parallel.
	The default is GOMAXPROCS, normally the number of CPUs available.
-race
	enable data race detection.
	Supported only on linux/amd64, freebsd/amd64, darwin/amd64, windows/amd64,
	linux/ppc64le and linux/arm64 (only for 48-bit VMA).
-msan
	enable interoperation with memory sanitizer.
	Supported only on linux/amd64, linux/arm64
	and only with Clang/LLVM as the host C compiler.
	On linux/arm64, pie build mode will be used.
-v
	print the names of packages as they are compiled.
-work
	print the name of the temporary work directory and
	do not delete it when exiting.
-x
	print the commands.

-asmflags '[pattern=]arg list'
	arguments to pass on each go tool asm invocation.
-buildmode mode
	build mode to use. See 'go help buildmode' for more.
-compiler name
	name of compiler to use, as in runtime.Compiler (gccgo or gc).
-gccgoflags '[pattern=]arg list'
	arguments to pass on each gccgo compiler/linker invocation.
-gcflags '[pattern=]arg list'
	arguments to pass on each go tool compile invocation.
-installsuffix suffix
	a suffix to use in the name of the package installation directory,
	in order to keep output separate from default builds.
	If using the -race flag, the install suffix is automatically set to race
	or, if set explicitly, has _race appended to it. Likewise for the -msan
	flag. Using a -buildmode option that requires non-default compile flags
	has a similar effect.
-ldflags '[pattern=]arg list'
	arguments to pass on each go tool link invocation.
-linkshared
	build code that will be linked against shared libraries previously
	created with -buildmode=shared.
-mod mode
	module download mode to use: readonly, vendor, or mod.
	By default, if a vendor directory is present and the go version in go.mod
	is 1.14 or higher, the go command acts as if -mod=vendor were set.
	Otherwise, the go command acts as if -mod=readonly were set.
	See https://golang.org/ref/mod#build-commands for details.
-modcacherw
	leave newly-created directories in the module cache read-write
	instead of making them read-only.
-modfile file
	in module aware mode, read (and possibly write) an alternate go.mod
	file instead of the one in the module root directory. A file named
	"go.mod" must still be present in order to determine the module root
	directory, but it is not accessed. When -modfile is specified, an
	alternate go.sum file is also used: its path is derived from the
	-modfile flag by trimming the ".mod" extension and appending ".sum".
-overlay file
	read a JSON config file that provides an overlay for build operations.
	The file is a JSON struct with a single field, named 'Replace', that
	maps each disk file path (a string) to its backing file path, so that
	a build will run as if the disk file path exists with the contents
	given by the backing file paths, or as if the disk file path does not
	exist if its backing file path is empty. Support for the -overlay flag
	has some limitations: importantly, cgo files included from outside the
	include path must be in the same directory as the Go package they are
	included from, and overlays will not appear when binaries and tests are
	run through go run and go test respectively.
-pkgdir dir
	install and load all packages from dir instead of the usual locations.
	For example, when building with a non-standard configuration,
	use -pkgdir to keep generated packages in a separate location.
-tags tag,list
	a comma-separated list of build tags to consider satisfied during the
	build. For more information about build tags, see the description of
	build constraints in the documentation for the go/build package.
	(Earlier versions of Go used a space-separated list, and that form
	is deprecated but still recognized.)
-trimpath
	remove all file system paths from the resulting executable.
	Instead of absolute file system paths, the recorded file names
	will begin with either "go" (for the standard library),
	or a module path@version (when using modules),
	or a plain import path (when using GOPATH).
-toolexec 'cmd args'
	a program to use to invoke toolchain programs like vet and asm.
	For example, instead of running asm, the go command will run
	'cmd args /path/to/asm <arguments for asm>'.
	The TOOLEXEC_IMPORTPATH environment variable will be set,
	matching 'go list -f {{.ImportPath}}' for the package being built.
```

## 常用命令

### 交叉编译

```go
// 编译Linux 64位可执行的包
// CGO_ENABLED的值将影响你的程序编译后的属性：是静态的还是动态链接的，为0则采用纯静态编译
// GOOS 代表编译的目标系统
// GOARCH 代表编译的处理器体系结构
// -ldflags="-w -s" 其中-w为去掉调试信息（无法使用gdb调试），-s为去掉符号表，可减少编译后文件体积
CGO_ENABLE=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o main main.go
```

### 检测项目中的变量逃逸

```go
go build -gcflags="-m -m" main.go
```

