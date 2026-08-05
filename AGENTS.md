# AGENTS.md

Bilingual (EN/PT-BR) Hugo blog on GitHub Pages. PaperMod theme (git submodule), Hugo v0.164.0 extended (installed at `~/.local/bin/hugo`, pinned in CI).

## Rules

- **Terse output.** Be brief; no long explanations unless asked.
- **Public repo.** Never commit secrets, tokens, or personal data. Content is CC BY 4.0 (see LICENSE).
- **Every post is a translation pair**: `content/posts/foo.en.md` + `content/posts/foo.pt-br.md`. Missing half silently breaks the bilingual site — don't create single-language posts.

## Workflow

- Preview: `hugo server -D` (drafts visible)
- Build: `hugo --minify` (output to `public/` — gitignored, never commit it)
- Deploy: push to `main` — GitHub Actions builds and deploys automatically. No manual deploy steps.
- Front matter: `draft: true` while writing, `math: true` only for posts using KaTeX.

## Gotchas

- Theme is a submodule (`themes/PaperMod`). Site-level overrides go in `layouts/` (`_partials/extend_head.html` for KaTeX, `_shortcodes/mermaid.html` for diagrams). Don't edit theme files for site changes.
- Mermaid: `{{< mermaid >}}...{{< /mermaid >}}` — loads JS from CDN at runtime.
- KaTeX: requires `math: true` in post front matter; loads from CDN.
- Search is client-side, built at build time (`/search/`); new posts appear automatically.
- Hugo version matters: workflow pins `0.164.0` extended — keep local install in sync.
