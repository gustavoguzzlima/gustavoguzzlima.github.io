---
title: "Welcome"
date: 2026-08-04
draft: false
tags: ["blog"]
---

Welcome to my blog. I write about software, systems, and the things I learn while building them.

This site is bilingual — every article is available in English and Portuguese (pt-BR). Use the language switch in the header to change.

The plan: technical articles about whatever I'm working on, with full markdown support — syntax-highlighted code, math with KaTeX, and diagrams with Mermaid.

```go
package main

import "fmt"

func main() {
    fmt.Println("First post, hello!")
}
```

A diagram to prove the pipeline:

{{< mermaid >}}
flowchart LR
    A[Write markdown] --> B[Hugo build] --> C[GitHub Pages]
{{< /mermaid >}}
