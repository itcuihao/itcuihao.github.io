---
title: "01 Matrix"
date: 2020-04-19T19:40:53+08:00
draft: false
categories: ["Algorithms"]
tags: ["Leetcode", "BFS"]
---

```text
给定一个由 0 和 1 组成的矩阵，找出每个元素到最近的 0 的距离。

两个相邻元素间的距离为 1 。

示例 1:
输入:

0 0 0
0 1 0
0 0 0
输出:

0 0 0
0 1 0
0 0 0
示例 2:
输入:

0 0 0
0 1 0
1 1 1
输出:

0 0 0
0 1 0
1 2 1
注意:

给定矩阵的元素个数不超过 10000。
给定矩阵中至少有一个元素是 0。
矩阵中的元素只在四个方向上相邻: 上、下、左、右。

来源：力扣（LeetCode）
链接：https://leetcode-cn.com/problems/01-matrix
著作权归领扣网络所有。商业转载请联系官方授权，非商业转载请注明出处。
```
先找出为0的元素位置，入队列，然后标记其他元素为-1，用-1来表示元素是否访问过。
对于队列中的坐标，对上下左右没有访问过的元素，进行距离+1的操作。

```go
package matrix

import (
	"fmt"
)

func updateMatrix(matrix [][]int) [][]int {
	if len(matrix) == 0 {
		return nil
	}
	maxRow, maxCel := len(matrix), len(matrix[0])
	zero := make([][]int, 0)
	for i := 0; i < maxRow; i++ {
		for j := 0; j < maxCel; j++ {
			if matrix[i][j] == 0 {
				zero = append(zero, []int{i, j})
			} else {
				matrix[i][j] = -1
			}
		}
	}

	around := [][]int{{0, 1}, {0, -1}, {1, 0}, {-1, 0}}

	for len(zero) > 0 {
		item := zero[0]
		x := item[0]
		y := item[1]
		fmt.Println("queue: ", zero)
		zero = zero[1:]

		for _, a := range around {
			ax, ay := x+a[0], y+a[1]
			fmt.Println("new:", ax, ay)
			if ax < 0 || ax >= maxRow || ay < 0 || ay >= maxCel {
				continue
			}
			fmt.Println("res:", matrix[ax][ay], matrix[x][y]+1)

			if matrix[ax][ay] == -1 {
				matrix[ax][ay] = matrix[x][y] + 1
				zero = append(zero, []int{ax, ay})
			}
			fmt.Println("matrix: ", matrix)

		}
	}
	return matrix
}
```

```text
queue:  [[0 0] [0 1] [0 2] [1 0] [1 2]]
new: 0 1
res: 0 1
matrix:  [[0 0 0] [0 -1 0] [-1 -1 -1]]
new: 0 -1
new: 1 0
res: 0 1
matrix:  [[0 0 0] [0 -1 0] [-1 -1 -1]]
new: -1 0
queue:  [[0 1] [0 2] [1 0] [1 2]]
new: 0 2
res: 0 1
matrix:  [[0 0 0] [0 -1 0] [-1 -1 -1]]
new: 0 0
res: 0 1
matrix:  [[0 0 0] [0 -1 0] [-1 -1 -1]]
new: 1 1
res: -1 1
matrix:  [[0 0 0] [0 1 0] [-1 -1 -1]]
new: -1 1
queue:  [[0 2] [1 0] [1 2] [1 1]]
new: 0 3
new: 0 1
res: 0 1
matrix:  [[0 0 0] [0 1 0] [-1 -1 -1]]
new: 1 2
res: 0 1
matrix:  [[0 0 0] [0 1 0] [-1 -1 -1]]
new: -1 2
queue:  [[1 0] [1 2] [1 1]]
new: 1 1
res: 1 1
matrix:  [[0 0 0] [0 1 0] [-1 -1 -1]]
new: 1 -1
new: 2 0
res: -1 1
matrix:  [[0 0 0] [0 1 0] [1 -1 -1]]
new: 0 0
res: 0 1
matrix:  [[0 0 0] [0 1 0] [1 -1 -1]]
queue:  [[1 2] [1 1] [2 0]]
new: 1 3
new: 1 1
res: 1 1
matrix:  [[0 0 0] [0 1 0] [1 -1 -1]]
new: 2 2
res: -1 1
matrix:  [[0 0 0] [0 1 0] [1 -1 1]]
new: 0 2
res: 0 1
matrix:  [[0 0 0] [0 1 0] [1 -1 1]]
queue:  [[1 1] [2 0] [2 2]]
new: 1 2
res: 0 2
matrix:  [[0 0 0] [0 1 0] [1 -1 1]]
new: 1 0
res: 0 2
matrix:  [[0 0 0] [0 1 0] [1 -1 1]]
new: 2 1
res: -1 2
matrix:  [[0 0 0] [0 1 0] [1 2 1]]
new: 0 1
res: 0 2
matrix:  [[0 0 0] [0 1 0] [1 2 1]]
queue:  [[2 0] [2 2] [2 1]]
new: 2 1
res: 2 2
matrix:  [[0 0 0] [0 1 0] [1 2 1]]
new: 2 -1
new: 3 0
new: 1 0
res: 0 2
matrix:  [[0 0 0] [0 1 0] [1 2 1]]
queue:  [[2 2] [2 1]]
new: 2 3
new: 2 1
res: 2 2
matrix:  [[0 0 0] [0 1 0] [1 2 1]]
new: 3 2
new: 1 2
res: 0 2
matrix:  [[0 0 0] [0 1 0] [1 2 1]]
queue:  [[2 1]]
new: 2 2
res: 1 3
matrix:  [[0 0 0] [0 1 0] [1 2 1]]
new: 2 0
res: 1 3
matrix:  [[0 0 0] [0 1 0] [1 2 1]]
new: 3 1
new: 1 1
res: 1 3
matrix:  [[0 0 0] [0 1 0] [1 2 1]]

```