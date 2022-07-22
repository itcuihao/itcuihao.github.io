---
title: "BinaryTree的遍历"
date: 2019-04-21T19:35:37+08:00
draft: false
categories: ["Algorithms"]
tags: ["tree","Leetcode"]
---

在二叉树中有各种各样的遍历算法，下面然我们来看看它们是怎么实现的。

二叉树的结构：
```
type TreeNode struct {
	Val   int
	Left  *TreeNode
	Right *TreeNode
}
```

**递归**

_前序遍历_

```
func preorderTraversal(root *TreeNode) []int {
	var l []int
	if root == nil {
		return l
	}

	l = append(l, root.Val)
	l = append(l, preorderTraversal(root.Left)...)
	l = append(l, preorderTraversal(root.Right)...)

	return l
}
```

_中序遍历_

```
func inorderTraversal(root *TreeNode) []int {
	var l []int
	if root == nil {
		return l
	}

	l = append(l, inorderTraversal(root.Left)...)
	l = append(l, root.Val)
	l = append(l, inorderTraversal(root.Right)...)

	return l
}
```

_后序遍历_

```
func postorderTraversal(root *TreeNode) []int {
	l := []int{}
	if root == nil {
		return l
	}

	l = append(l, postorderTraversal(root.Left)...)
	l = append(l, postorderTraversal(root.Right)...)
	l = append(l, root.Val)

	return l
}
```

**非递归**

_前序遍历_

```
func preorderFor(root *TreeNode) []int {
	var (
		l         []int
		tempStack []*TreeNode
	)

	for root != nil || len(tempStack) > 0 {
		l = append(l, root.Val)

		if root.Left != nil {
			if root.Right != nil {
				tempStack = append(tempStack, root.Right)
			}
			root = root.Left
		} else if root.Right != nil {
			root = root.Right
		} else {

			if len(tempStack) == 0 {
				break
			}

			root = tempStack[len(tempStack)-1]
			tempStack = tempStack[:len(tempStack)-1]
		}
	}

	return l
}
```

_中序遍历_

```
func inorder(root *TreeNode) []int {
	var res []int
	if root == nil {
		return res
	}
	var stack []*TreeNode

	cur := root
	for cur != nil || len(stack) > 0 {
		for cur != nil {
			stack = append(stack, cur)
			cur = cur.Left
		}
		cur = stack[len(stack)-1]
		stack = stack[:len(stack)-1]
		res = append(res, cur.Val)
		cur = cur.Right
	}
	return res
}
```

**后序遍历**

```

func portorder(root *TreeNode) []int {
	l := []int{}
	tempStack := []*TreeNode{}

	for root != nil || len(tempStack) > 0 {
		if root != nil {
			tempStack = append(tempStack, root)
			l = append(l, root.Val)
			root = root.Right
		} else {
			root = tempStack[len(tempStack)-1]
			tempStack = tempStack[:len(tempStack)-1]
			root = root.Left
		}
	}
	lt := len(l)
	for i := 0; i < lt/2; i++ {
		l[i], l[lt-i-1] = l[lt-i-1], l[i]
	}
	return l
}

```

---

**源码地址**

[leetcode94](https://github.com/itcuihao/leetcode-go/tree/master/problems/0094.binary-tree-inorder-traversal)

[leetcode144](https://github.com/itcuihao/leetcode-go/tree/master/problems/0144.binary-tree-preorder-traversal)

[leetcode145](https://github.com/itcuihao/leetcode-go/tree/master/problems/0145.binary-tree-postorder-traversal)