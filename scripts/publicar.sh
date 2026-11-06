#!/usr/bin/env bash
# publicar.sh — publica um par bilíngue de posts em um comando.
#
#   scripts/publicar.sh <pt-br.md> <en.md> [--slug <slug>] [--no-push] [--dry-run]
#
# Fluxo: valida o front matter dos dois arquivos, copia para content/posts/,
# normaliza draft:false e date, roda o build do Hugo, confere que as duas
# páginas nasceram, commita (conventional commit) e empurra para o GitHub —
# o push em main dispara o deploy do GitHub Pages.
#
# --dry-run  valida a entrada e mostra o que seria publicado; não toca no repo.
# --no-push  commita local, não empurra (para teste/revisão).
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$ROOT"

die() { printf 'erro: %s\n' "$*" >&2; exit 1; }
usage() { sed -n '2,14p' "${BASH_SOURCE[0]}" | sed -e 's/^# \{0,1\}//' -e '/^$/d'; }

PT="" ; EN="" ; SLUG="" ; PUSH=1 ; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --slug)   [ $# -ge 2 ] || die "--slug exige valor"; SLUG="$2"; shift 2 ;;
    --no-push) PUSH=0; shift ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) die "opção desconhecida: $1 (veja --help)" ;;
    *)  if   [ -z "$PT" ]; then PT="$1"
        elif [ -z "$EN" ]; then EN="$1"
        else die "argumento extra: $1"; fi
        shift ;;
  esac
done

[ -n "$PT" ] && [ -n "$EN" ] || { usage; die "faltou arquivo — todo post é um par pt-br + en"; }
for f in "$PT" "$EN"; do [ -f "$f" ] || die "arquivo não existe: $f"; done

# --- slug -------------------------------------------------------------------
base="$(basename -- "$PT")"
case "$base" in
  *.pt-br.md) base="${base%.pt-br.md}" ;;
  *.md)       base="${base%.md}" ;;
  *)          die "esperava um .md (ex.: meu-post.pt-br.md)" ;;
esac
slug="${SLUG:-$base}"
printf '%s' "$slug" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$' \
  || die "slug inválido: '$slug' (use minúsculas, números e hífen)"

# --- front matter -----------------------------------------------------------
check_fm() { # $1=arquivo
  local fence sep
  fence="$(head -1 -- "$1")"
  case "$fence" in
    '---') sep=':' ;;
    '+++') sep='=' ;;
    *) die "sem front matter (--- ou +++) na primeira linha de $1" ;;
  esac
  grep -qE "^[[:space:]]*title[[:space:]]*${sep}" "$1" || die "sem 'title' no front matter de $1"
  grep -qE "^[[:space:]]*draft[[:space:]]*${sep}[[:space:]]*true" "$1" \
    && printf 'aviso: %s está como draft; publicar vai marcar draft: false\n' "$1" >&2
  return 0
}
check_fm "$PT"
check_fm "$EN"

if [ "$DRY" = 1 ]; then
  printf 'dry-run ok\n  slug: %s\n  pt-br: %s\n  en: %s\n' "$slug" "$PT" "$EN"
  printf 'nada foi copiado, buildado ou commitado.\n'
  exit 0
fi

[ "$PUSH" = 1 ] && [ "$(git rev-parse --abbrev-ref HEAD)" != "main" ] \
  && die "branch atual não é main — faça merge em main ou use --no-push"

# --- normaliza e copia ------------------------------------------------------
TODAY="$(date +%F)"
prep() { # $1=origem $2=destino
  local fence sep
  fence="$(head -1 -- "$1")"
  case "$fence" in '---') sep=':' ;; '+++') sep='=' ;; esac
  awk -v sep="$sep" -v today="$TODAY" '
    NR==1 { print; infm=1; next }
    infm && /^(---|\+\+\+)[[:space:]]*$/ {
      if (!hdate)  print "date" sep " " today
      if (!hdraft) print "draft" sep " false"
      print; infm=0; next
    }
    infm && /^[[:space:]]*draft[[:space:]]*[:=]/ { print "draft" sep " false"; hdraft=1; next }
    infm && /^[[:space:]]*date[[:space:]]*[:=]/  { print; hdate=1; next }
    { print }
  ' "$1" > "$2"
}

mkdir -p content/posts
DST_PT="content/posts/${slug}.pt-br.md"
DST_EN="content/posts/${slug}.en.md"
for d in "$DST_PT" "$DST_EN"; do
  [ -e "$d" ] || continue
  # reeditar um draft criado por novo-post.sh é o caso normal: só colide
  # quando o destino é outro arquivo.
  case "$d" in
    "$PT"|"$EN") ;;
    *) die "já existe $d — escolha outro slug ou remova o arquivo" ;;
  esac
done

cleanup() { rm -rf "$ROOT/.publicar-build"; }
trap cleanup EXIT

# desfaz a cópia se o build falhar (draft continua draft, nada commitado)
revert_dest() {
  for pair in "$DST_PT:$PT" "$DST_EN:$EN"; do
    d="${pair%%:*}" ; s="${pair#*:}"
    if [ "$d" = "$s" ]; then
      git checkout -q -- "$d" 2>/dev/null || rm -f -- "$d"
    else
      rm -f -- "$d"
    fi
  done
}

prep "$PT" "$DST_PT.tmp" && mv -- "$DST_PT.tmp" "$DST_PT"
prep "$EN" "$DST_EN.tmp" && mv -- "$DST_EN.tmp" "$DST_EN"

# --- build ------------------------------------------------------------------
HUGO="$(command -v hugo || true)"
[ -n "$HUGO" ] || HUGO="$HOME/.local/bin/hugo"
[ -x "$HUGO" ] || die "hugo não encontrado"

if ! "$HUGO" --minify --quiet --destination .publicar-build; then
  revert_dest
  die "build do Hugo falhou — nada foi commitado"
fi

for page in ".publicar-build/posts/${slug}/index.html" ".publicar-build/pt-br/posts/${slug}/index.html"; do
  [ -f "$page" ] || { revert_dest; die "página não foi gerada: $page (slug/url customizado?)"; }
done

# --- commit -----------------------------------------------------------------
git add -- "$DST_PT" "$DST_EN"
git diff --cached --quiet && { die "nada a commitar"; }

git commit -q -m "post(${slug}): publicar"

if [ "$PUSH" = 1 ]; then
  git push -q origin main || { die "commit feito, push falhou — rode 'git push origin main' com a chave destravada"; }
  printf 'publicado: %s\n' "$(git log -1 --format='%h %s')"
  printf 'url: https://gustavolima.dev.br/posts/%s/ (deploy leva ~1 min)\n' "$slug"
  printf 'url pt-br: https://gustavolima.dev.br/pt-br/posts/%s/\n' "$slug"
else
  printf 'commit local: %s (não empurrado)\n' "$(git log -1 --format='%h %s')"
fi
