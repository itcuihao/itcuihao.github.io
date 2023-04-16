#!/bin/bash
# 需要初始化 public 文件夹 git remote
hugo

echo "Hugo to GitHub Pages"

cd public && 
pwd &&
git add . ; git commit -m "update" ; git push -u origin gh-pages -f

echo "Push to GitHub Pages"
