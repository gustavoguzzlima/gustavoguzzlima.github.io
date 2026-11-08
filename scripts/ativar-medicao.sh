#!/usr/bin/env bash
# ativar-medicao.sh — liga analytics e verificação do Search Console no site.
#
#   scripts/ativar-medicao.sh --cf-token <token> [--gsc-token <token>] [--no-push]
#
# Grava os tokens em hugo.toml, faz build, commita, empurra para main e espera
# o deploy do GitHub Pages publicar o beacon/meta tag. Rodar de novo é seguro
# (substitui o valor anterior).
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$ROOT"

die() { printf 'erro: %s\n' "$*" >&2; exit 1; }
CF="" ; GSC="" ; PUSH=1
while [ $# -gt 0 ]; do
  case "$1" in
    --cf-token)  [ $# -ge 2 ] || die "--cf-token exige valor"; CF="$2"; shift 2 ;;
    --gsc-token) [ $# -ge 2 ] || die "--gsc-token exige valor"; GSC="$2"; shift 2 ;;
    --no-push) PUSH=0; shift ;;
    -h|--help) sed -n '2,9p' "${BASH_SOURCE[0]}" | sed -e 's/^# \{0,1\}//' -e '/^$/d'; exit 0 ;;
    *) die "opção desconhecida: $1" ;;
  esac
done

[ -n "$CF" ] || [ -n "$GSC" ] || die "informe --cf-token e/ou --gsc-token"
for pair in "cf:$CF" "gsc:$GSC"; do
  name="${pair%%:*}" ; val="${pair#*:}"
  [ -z "$val" ] && continue
  printf '%s' "$val" | grep -qE '^[A-Za-z0-9_-]{10,120}$' || die "token $name com caracteres inesperados"
done

[ "$PUSH" = 1 ] && [ "$(git rev-parse --abbrev-ref HEAD)" != "main" ] \
  && die "branch atual não é main — use --no-push ou faça merge em main"

if [ -n "$CF" ]; then
  sed -i -E "s|^([[:space:]]*cloudflareToken[[:space:]]*=[[:space:]]*)'.*'[[:space:]]*$|\1'${CF}'|" hugo.toml
  grep -qF "cloudflareToken = '${CF}'" hugo.toml || die "não consegui gravar cloudflareToken em hugo.toml"
fi
if [ -n "$GSC" ]; then
  sed -i -E "s|^([[:space:]]*google[[:space:]]*=[[:space:]]*)'.*'[[:space:]]*$|\1'${GSC}'|" hugo.toml
  grep -qF "google = '${GSC}'" hugo.toml || die "não consegui gravar google em hugo.toml"
fi

HUGO="$(command -v hugo || true)"; [ -n "$HUGO" ] || HUGO="$HOME/.local/bin/hugo"
[ -x "$HUGO" ] || die "hugo não encontrado"
rm -rf .publicar-build
trap 'rm -rf "$ROOT/.publicar-build"' EXIT
"$HUGO" --minify --quiet --destination .publicar-build || die "build falhou"
if [ -n "$CF" ]; then
  grep -qF "data-cf-beacon" ".publicar-build/index.html" || die "beacon não apareceu no build"
fi
if [ -n "$GSC" ]; then
  grep -qF "google-site-verification" ".publicar-build/index.html" || die "meta tag não apareceu no build"
fi

git add -- hugo.toml
git diff --cached --quiet && { printf 'nada mudou em hugo.toml\n'; exit 0; }
git commit -q -m "infra(medicao): ativar analytics e verificacao do search console"
printf 'commit: %s\n' "$(git log -1 --format='%h %s')"

if [ "$PUSH" = 1 ]; then
  git push -q origin main || die "commit feito, push falhou — rode 'git push origin main' com a chave destravada"
  printf 'push ok — esperando o GitHub Pages publicar'
  ok=0
  for _ in $(seq 1 40); do
    sleep 10
    html="$(curl -fsS "https://gustavolima.dev.br/?cb=$RANDOM$RANDOM" || true)"
    if [ -n "$GSC" ] && ! printf '%s' "$html" | grep -qF "content=\"${GSC}\""; then printf '.'; continue; fi
    if [ -n "$CF" ] && ! printf '%s' "$html" | grep -qF "data-cf-beacon"; then printf '.'; continue; fi
    ok=1; break
  done
  printf '\n'
  [ "$ok" = 1 ] && printf 'no ar: beacon e/ou meta tag visíveis em https://gustavolima.dev.br/\n' \
                || printf 'aviso: deploy ainda não apareceu no HTML (verifique Actions do repo)\n'
fi

cat <<'EOF'

Search Console (faltam 2 cliques seus):
  1. https://search.google.com/search-console → Adicionar propriedade → "Prefixo do URL"
     → https://gustavolima.dev.br/  (o token acima já está no ar)
  2. Clique em "Verificar".
  3. Menu "Sitemaps" → enviar: sitemap.xml
EOF
