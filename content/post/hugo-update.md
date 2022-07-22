---
title: "Blog更新汇总"
date: 2022-07-07T07:48:44+08:00
draft: false
categories: ["hugo"]
tags: ["hugo"]
summary: "更新点滴"
---

---

## 添加[utteranc](https://github.com/utterance)评论

首先github授权[utteranc](https://utteranc.es/)。

针对`github-style`主题，在`themes/github-style/layouts/partials/`下，创建`utteranc.html`文件。

```html
{{ if .Site.Params.Utteranc.enable }}
<script src="https://utteranc.es/client.js"
        repo="{{ .Site.Params.Utteranc.owner }}/{{ .Site.Params.Utteranc.repo }}",
        issue-term="title"
        label="💬"
        theme="{{ .Site.Params.Utteranc.theme }}",
        crossorigin="anonymous"
        async>
</script>
<noscript>Please enable JavaScript to view the <a href="https://github.com/utterance">comments powered by utterances.</a></noscript>
{{ end }}

```

然后，修改`themes/github-style/layouts/_default/single.html`文件

```
{{ define "content" }}
{{ partial "toc.html" .}}
{{ partial "post.html" .}}
{{ partial "gitalk.html" . }}
{{ partial "utteranc.html" . }} // 添加
{{end }}
```

最后，在`config.toml`中增加配置

```toml
[params]
  [params.utteranc]
    enable = true
    owner = "your_github_name"
    repo = "blog"
    issueTerm = "pathname"
    theme = "icy-dark"
```