# Medição do blog

O que existe para provar tráfego: analytics, Search Console e uma linha de base datada.
Nada aqui é conteúdo — é o relógio da série histórica.

## Decisão: Cloudflare Web Analytics (R$ 0/mês)

Escolhido em 2026-11-06. Custo: **R$ 0** — o produto não tem plano pago.

- Site fora do Cloudflare usa **snippet** (não exige mudar DNS nem proxy):
  <https://developers.cloudflare.com/web-analytics/get-started> → "Sites not proxied through Cloudflare".
- Sem cookie, sem fingerprint, sem banner de consentimento.
- Zero infraestrutura: nada para instalar, expor, atualizar ou fazer backup.

Avaliados e descartados:

| Opção | Custo | Por que não |
|---|---|---|
| Plausible CE self-hosted | R$ 0 de licença | Exige endpoint **público** e dois bancos em container (Postgres + ClickHouse), além de TLS, patch e backup. O host é único, com IP residencial e sem on-call. A própria doc chama de "a real commitment". |
| Umami Cloud Hobby | R$ 0 (100k eventos/mês) | Retenção de 6 meses e 1 site; mesmas limitações da CF sem ganho hoje (o site não tem CTA para evento customizado). |

Limitações conhecidas da escolha (registradas, não escondidas): janela de 6 meses
(dado bruto só 7 dias; depois é agregado a ~10%, com amostragem maior em sites de
pouco tráfego para manter a confiança), sem export, sem eventos customizados, sem UTM
e o beacon é bloqueado por adblockers. Quando conversão e série maior que 6 meses
importarem, o caminho é self-host (GoatCounter/Umami) com subdomínio público —
decisão do fundador, não default.

## Linha de base — 2026-11-06 (America/Maceió, UTC-3)

| Métrica | Valor | Como foi medido |
|---|---|---|
| URLs no sitemap | 16 (8 en + 8 pt-br) | `curl /sitemap.xml` → `/en/sitemap.xml` + `/pt-br/sitemap.xml` |
| Páginas de conteúdo | 2 (1 post × 2 idiomas) + 2 homes | sitemap |
| Páginas indexadas no Google | não mensurável ainda (propriedade não verificada) | pendente Search Console |
| Sessões | 0 medido — sem analytics até hoje | pendente beacon |
| Último build publicado | 2026-08-05 09:29 UTC | header `last-modified` |
| Último commit | 2026-08-05 00:37 -03 | `git log -1` |

Este é o zero da série. A partir do primeiro dia com beacon no ar, cada mês entra em
`docs/serie-historica.md` (uma linha por mês: sessões, visitantes, top páginas, indexadas).

## Ativar (uma vez, 2 tokens)

1. **Cloudflare Web Analytics** — <https://dash.cloudflare.com/sign-up/web-analytics>
   (conta grátis, sem cartão) → Web Analytics → *Add a site* → hostname
   `gustavolima.dev.br` → *Manage site* → copiar o `token` do snippet JS.
2. **Search Console** — <https://search.google.com/search-console> → *Adicionar
   propriedade* → **Prefixo do URL** → `https://gustavolima.dev.br/` → método
   **Tag HTML** → copiar só o `content="..."`.
3. Rodar, na raiz do repo, com a chave SSH destravada:

   ```sh
   scripts/ativar-medicao.sh --cf-token <token-cf> --gsc-token <token-gsc>
   ```

   O script grava os tokens em `hugo.toml`, builda, commita, empurra para `main` e
   espera o deploy publicar. Tokens de beacon/verificação são públicos por natureza.
4. No Search Console: clicar **Verificar** e depois *Sitemaps* → enviar `sitemap.xml`.

## Publicar um post (um comando)

```sh
scripts/novo-post.sh meu-post --title "Meu post" --title-en "My post"   # cria o par em draft
# ... escrever os dois arquivos ...
scripts/publicar.sh content/posts/meu-post.pt-br.md content/posts/meu-post.en.md
```

`publicar.sh` valida o front matter, marca `draft: false`, builda, confere que as duas
páginas nasceram, commita (`post(<slug>): publicar`) e empurra para `main` — o push
dispara o deploy do GitHub Pages.

## Rotina mensal (5 min, dia 1)

1. Abrir o painel do Cloudflare Web Analytics e anotar: sessões, visitantes, top 5 páginas.
2. Search Console → *Páginas* indexadas e *Sitemaps* (status).
3. Acrescentar a linha do mês em `docs/serie-historica.md`.
