# Lapidação: peso, og:image, mermaid e contraste

Base: `infra/medicao-blog` (7ffdbfb). Branch: `perf/lapida`. Nenhuma mudança de
tipografia, escala, espaçamento, paleta ou layout — só o que tinha defeito medido.

## Como medir

Chrome headless via CDP, cache desabilitado, viewport 1440×900 e 390×844, `gzip`
ligado no servidor local. Scripts da medição ficaram fora do repo (workspace da
task); o que reproduz em qualquer máquina:

```bash
HUGO_ENV=production hugo --minify -d /tmp/out --baseURL http://127.0.0.1:8099/
python3 -m http.server 8099 -d /tmp/out   # sem gzip: números só de corpo
# network/LCP/contraste: DevTools → Network (Disable cache) e Lighthouse
```

## Peso (bytes transferidos, gzip, cache frio)

| Página | Antes | Depois | Δ |
|---|---:|---:|---:|
| Home 1440 / 390 | 119.474 (6 req) | 18.432 (6 req) | **−84,6%** |
| Post 1440, diagrama na tela | 228.689 (32 req) | 229.146 (32 req) | +457 B |
| Post 390, diagrama fora da tela | 233.465 (32 req) | 11.393 (5 req) | **−95,1%** |

- Home: 109.329 B eram o avatar PNG. Agora 8.044 B (WebP 300×300, q85).
- Post 1440: o diagrama está visível no primeiro paint, então o mermaid carrega
  nos dois lados; a diferença (+457 B) é o CSS de contraste (+127 B) e as tags
  de compartilhamento no HTML (+338 B).
- Post 390: o diagrama começa em y=885, abaixo da dobra de 844 — com o import
  sob demanda ele não é baixado até o usuário chegar nele. 27 requisições de
  terceiro e ~217 KB saem do carregamento inicial.
- LCP local (sem rede real): home 104 → 88 ms; post 390 108 → 96 ms.

## og:image

`static/og-image.png` — 1200×630, 30.546 B, gerada por `scripts/gerar-og-image.sh`
(Chrome headless sobre `scripts/og-image.html`, tokens do próprio site). O HTML
declara `og:image`, `og:image:width/height/type/alt` e
`twitter:card=summary_large_image` na home e nos posts. Antes não havia imagem
nenhuma e o card era `summary`.

## Contraste AA (só o que reprovava)

Medido em DOM real, texto composto sobre o fundo efetivo. Tema claro já passava
(mínimo 4,74:1). No escuro, dois pares reprovavam:

| Par | Antes | Depois |
|---|---|---|
| `.lnt` (número de linha) sobre `rgb(46,46,51)` | `#8087a2` — 3,80:1 | `rgb(142,149,176)` — 4,55:1 |
| `.post-tags a` (chip) sobre `rgb(55,56,62)` | `rgb(155,156,157)` — 4,25:1 | `rgb(165,166,167)` — 4,79:1 |
| Diagrama mermaid no escuro | texto `rgb(51,51,51)` sobre `rgb(29,30,32)` — 1,32:1 | tema `dark` do mermaid |

As duas cores novas são as mesmas do tema, deslocadas o mínimo para cruzar 4,5:1.
Elas só se aplicam sob `[data-theme="dark"]` — o tema claro não muda um pixel.

## Comparação visual

Diff de pixel entre antes e depois (`shots/side/`):

| Par | Pixels diferentes | Delta máximo |
|---|---:|---:|
| Post 1440 e 390 | 0 | 0 |
| Home 1440 | 4,05% (só o avatar) | 17/255 |
| Home 390 | 10,4% (só o avatar) | 12/255 |
| Post 1440 escuro | 2,4% (diagrama + números de linha) | 181/255 |

Home: a única diferença é ruído de compressão WebP dentro do círculo do avatar,
0,035% dos pixels com delta acima de 8. Post no tema claro: idêntico byte a byte.

## Achado não corrigido

Três 404 por página: `favicon.ico`, `favicon-16x16.png`, `favicon-32x32.png`
(o tema emite os cinco `<link rel=icon>` e o site não tem nenhum dos arquivos).
São 3 requisições e ~1.980 B de resposta de erro por visita. Corrigir exige criar
o ícone — ativo de marca, decisão do fundador, não desta task.

## Regerar

```bash
scripts/gerar-og-image.sh          # refaz static/og-image.png
HUGO_ENV=production hugo --minify  # build de produção
```
