# Blog

Source of https://gustavoguzzlima.github.io/blog/ — a bilingual (EN/PT-BR) Hugo blog with the PaperMod theme.

## Writing a post

Every article exists as a translation pair in `content/posts/`:

- `content/posts/my-post.en.md` (English)
- `content/posts/my-post.pt-br.md` (Portuguese)

Draft in one language first, set `draft: true` in the front matter while writing, then preview:

```sh
hugo server -D
```

## Markdown features

- GFM (tables, footnotes, task lists)
- Syntax highlighting (Chromium-based, via Hugo)
- KaTeX math — add `math: true` to the post's front matter
- Mermaid diagrams — `{{< mermaid >}}...{{< /mermaid >}}`
- Built-in client-side search (see `/search/`)

## Building & deploying

- Build: `hugo` (outputs to `public/`, but the site is deployed via GitHub Actions)
- Deploy: push to `main` — the workflow in `.github/workflows/` builds with Hugo v0.164.0 (extended) and deploys to GitHub Pages.

## License

All original writing is licensed under CC BY 4.0 — see `LICENSE`.
