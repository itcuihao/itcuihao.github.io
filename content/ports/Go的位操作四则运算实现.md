---
title: "Go的位操作四则运算实现"
date: 2018-08-02T00:26:55+08:00
draft: false
categories: ["Go", "Algorithms"]
tags: ["mathematics"]
---

```
package main

import "fmt"

func main() {
	a := 2
	b := 2
	fmt.Println(add(a, b))
	fmt.Println(sub(a, b))
	fmt.Println(mul(a, b))
	fmt.Println(div(a, b))
}
func add(a, b int) int {

	if b == 0 {
		return a
	}
	tmp := 0
	for b != 0 {
		tmp = (a & b) << 1
		a = a ^ b
		b = tmp
	}
	return a
}
func addr(a, b int) int {
	if b == 0 {
		return a
	}
	tmp := (a & b) << 1
	a = a ^ b
	return addr(a, tmp)
}

func sub(a, b int) int {
	return add(a, add(^b, 1))
}

func mul(a, b int) int {
	ans := 0
	for b != 0 {
		if b&1 != 0 {
			ans = add(ans, a)
		}
		a <<= 1
		b >>= 1
	}
	return ans
}

func div(a, b int) int {
	ans := 0
	for i := 31; i >= 0; i-- {

		if b <= (a >> uint64(i)) {
			ans += 1 << uint64(i)
			a -= b << uint64(i)
		}
	}
	return ans
}

```