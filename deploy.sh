#!/bin/bash

hugo

echo "Hugo to GitHub Pages"

cd public

pwd

git add . ; git commit -m "update" ; git push -u origin gh-pages -f

echo "Push to GitHub Pages"
