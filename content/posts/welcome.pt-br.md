---
title: "Bem-vindo"
date: 2026-08-04
draft: false
tags: ["blog"]
---

Bem-vindo ao meu blog. Escrevo sobre software, sistemas e as coisas que aprendo construindo-os.

Este site é bilíngue — todos os artigos estão disponíveis em inglês e português (pt-BR). Use o seletor de idioma no cabeçalho para alternar.

O plano: artigos técnicos sobre o que eu estiver trabalhando, com suporte completo a markdown — código com syntax highlighting, matemática com KaTeX e diagramas com Mermaid.

```go
package main

import "fmt"

func main() {
    fmt.Println("Primeiro post, olá!")
}
```

Um diagrama para provar o pipeline:

{{< mermaid >}}
flowchart LR
    A[Escrever markdown] --> B[Build Hugo] --> C[GitHub Pages]
{{< /mermaid >}}
