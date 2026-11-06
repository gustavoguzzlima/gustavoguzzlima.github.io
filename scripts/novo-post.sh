#!/usr/bin/env bash
# novo-post.sh — cria o par de drafts (pt-br + en) com front matter do PaperMod.
#
#   scripts/novo-post.sh <slug> --title "Título" --title-en "Title" [--tags a,b]
#
# Cria content/posts/<slug>.pt-br.md e <slug>.en.md com draft: true.
# Publicar depois: scripts/publicar.sh content/posts/<slug>.pt-br.md content/posts/<slug>.en.md
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$ROOT"

die() { printf 'erro: %s\n' "$*" >&2; exit 1; }

[ $# -ge 1 ] || die "uso: scripts/novo-post.sh <slug> --title \"...\" --title-en \"...\""
SLUG="$1"; shift
TITLE="" ; TITLE_EN="" ; TAGS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --title)    [ $# -ge 2 ] || die "--title exige valor"; TITLE="$2"; shift 2 ;;
    --title-en) [ $# -ge 2 ] || die "--title-en exige valor"; TITLE_EN="$2"; shift 2 ;;
    --tags)     [ $# -ge 2 ] || die "--tags exige valor"; TAGS="$2"; shift 2 ;;
    *) die "opção desconhecida: $1" ;;
  esac
done

printf '%s' "$SLUG" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$' \
  || die "slug inválido: '$SLUG' (minúsculas, números e hífen)"
[ -n "$TITLE" ]    || die "faltou --title (pt-br)"
[ -n "$TITLE_EN" ] || die "faltou --title-en"

TODAY="$(date +%F)"
mkdir -p content/posts

for pair in "pt-br:$TITLE" "en:$TITLE_EN"; do
  lang="${pair%%:*}" ; title="${pair#*:}"
  dst="content/posts/${SLUG}.${lang}.md"
  [ -e "$dst" ] && die "já existe $dst"
  {
    printf -- '---\n'
    printf 'title: "%s"\n' "$title"
    printf 'date: %s\n' "$TODAY"
    printf 'draft: true\n'
    [ -n "$TAGS" ] && printf 'tags: [%s]\n' "$TAGS"
    printf -- '---\n\n'
  } > "$dst"
  printf 'criado: %s\n' "$dst"
done

printf '\nquando estiver pronto: scripts/publicar.sh content/posts/%s.pt-br.md content/posts/%s.en.md\n' "$SLUG" "$SLUG"
