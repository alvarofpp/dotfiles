# Agentes — `dotfiles`

O recorte deste repositório, lido pelo `/review-pr`. Um agente que atua num
contexto está apto a revisar **qualquer coisa** daquele contexto — código, doc,
config, unit. A revisão de um PR é a união dos contextos que o diff toca.

Os agentes deste repo moram no submódulo **`ai/`**, não na raiz: o `dotfiles` é
público e o `dotfiles-ai` não, então tudo de IA vive lá por segurança. É de lá
que sai o catálogo abaixo.

A coluna Agentes contém só nomes — é ela que o `task ai:agents-doc MODE=check`
valida. Instrução vai na Lente.

## Contextos

| Contexto | O que pertence a ele | Agentes | Lente |
|---|---|---|---|
| serviços da máquina | `home/.config/systemd/user/**`, `etc/wsl.conf`, `windows/.wslconfig` | `alienware` | `[Install]` é intencional? Unit que não deve subir no boot não tem. `Restart` sem `StartLimit*` é crash loop esperando acontecer. `Environment=PATH` cobre o binário chamado — a sessão do systemd não herda o PATH do shell. Unit de tick tem um `ExecStart` por passo, e a **ordem é a semântica**: passo novo no lugar errado muda o que o tick decide. |
| stow | `home/**`, `etc/**`, `windows/**`, `stow.sh`, `.stow-local-ignore` | `general-purpose` | O arquivo é stowável? **Colisão aborta o pacote inteiro**, não só o arquivo: um conflito em `.hermes/config.yaml` impediu todos os symlinks do `ai/` por uma semana, e o `./stow.sh` terminava em `✅` do mesmo jeito. Arquivo reescrito pela própria app (config de Electron, settings de terminal) nunca pode ser symlink — vai pro `.stow-local-ignore` como cópia sincronizada. Arquivo novo na raiz que não deve ser linkado entra lá também. |
| tasks | `home/Taskfile.yml`, `home/taskfiles/*.yml` | `general-purpose` | Idempotência: rodar duas vezes não pode diferir. Erro sai não-zero em vez de morrer num pipe. Taskfile incluído roda no diretório do Taskfile raiz — `.` aponta pro `$HOME`, não pro cwd. `summary` com Arguments/Examples como as vizinhas. Costura injetável (`GATE`, `STATE`, `CACHE`, `RATE_PROBE`) é o que torna a task testável sem rede — task nova que decide algo ganha a sua. |
| testes das tasks | `home/taskfiles/tests/*.sh` | `general-purpose` | O programa é **extraído** do `GitHub.yml`, nunca copiado: cópia envelhece e testa o passado. Cada caso nomeia o erro que ele impede, não o que ele confirma. Caso que depende de rede ou de Docker não entra — teste que só passa nesta máquina não é teste. |
| bootstrap | `setup.sh`, `*.sh` na raiz | `general-purpose` | Roda em máquina limpa? Assume brew em `/home/linuxbrew`? Idempotente? Health check que reporta ausência de config de máquina (`telegram.env`, `.zshrc.local`) sem falhar — ausência dessas é normal, silêncio sobre elas é que não. |
| docs | `README.md`, `CLAUDE.md` | `general-purpose` | Só estes dois no parent: `docs/` foi pro repo privado em 2026-09-03, e TODO/CHANGELOG deixaram de existir em 2026-09-05 (pendência é issue; decisão é um arquivo em `docs/decisions/` **de lá**, em commit separado). Doc que afirma número do repositório inteiro (contagem, cobertura medida, timestamp de geração) é bloqueante — é a fonte nº 1 de conflito entre PRs paralelos. |
| submódulo `ai/` | o ponteiro `ai` | `meta-librarian` | O diff traz só o SHA: leia o que mudou de verdade com `git diff --submodule=log`. Conteúdo (commands, agents, skills, rules) se revisa no repo `dotfiles-ai`, não aqui — mas confira se o bump acompanha a mudança da raiz que o exigiu. |

## Transversais

Entram numa revisão quando o **gatilho** dispara, não por padrão — revisor acordado
por reflexo é ruído no veredito e come o teto de rodadas do `/review-pr`. `sempre` é
o gatilho de quem entra em toda revisão; glob casa contra os arquivos do diff;
palavra casa, sem distinguir maiúscula, contra caminhos e texto do diff.

| Agente | Gatilho | Lente |
|---|---|---|
| `general-purpose` | `sempre` | lente **segredo**: este repo é **público**. Credencial, token, path de cliente ou qualquer dado privado que entre aqui é bloqueante, e o lugar certo é o submódulo `ai/`. Vale pra diff em qualquer contexto, doc inclusive. |

## Fora do mapa

Agentes que existem no catálogo e não revisam nada aqui, com o motivo:

- `document-crafter` — produz deck e documento formatado; não há o que revisar
  neste repo, que é config e shell.
- A família `seo-*` — o `ai/` os versiona pra uso em projetos de conteúdo.
  Nenhum tem domínio dentro deste repositório.

## Catálogo

<!-- catálogo gerado por `task ai:agents-doc` — não edite à mão -->

| Agente | Contexto (do frontmatter) |
|---|---|
| `alienware` | Agente operacional pra máquina "alienware" do Álvaro (WSL2 + Hermes services + Tailscale serve). Use quando o usuário tem problema cross-domain envolvendo qualquer combinação de Hermes (gateway/cc-bri |
| `document-crafter` | Use when the user wants to create or edit polished presentations (.pptx), documents (.docx, .pdf), spreadsheets (.xlsx), or visual pieces (posters, covers). Orchestrates pptx, docx, pdf, xlsx, canvas- |
| `meta-librarian` | Audita o inventário de skills, agents e commands (global ~/.claude/ + projeto .claude/ + plugins). Detecta overlaps, descrições ambíguas, artefatos órfãos que nunca disparam, candidatos a promover pro |
| `seo-backlinks` | Backlink profile analyst using free and paid sources. Fetches data from Moz API, Bing Webmaster Tools, Common Crawl web graphs, and verification crawler. Merges multi-source data with confidence-weigh |
| `seo-cluster` | Semantic topic clustering analysis using SERP overlap methodology. Expands seed keywords, performs pairwise SERP comparison, classifies intent, designs hub-and-spoke content architecture, and generate |
| `seo-content` | Content quality reviewer. Evaluates E-E-A-T signals, readability, content depth, AI citation readiness, and thin content detection. |
| `seo-dataforseo` | DataForSEO data analyst. Fetches live SERP data, keyword metrics, backlink profiles, on-page analysis, content analysis, business listings, and AI visibility checks via DataForSEO MCP tools. |
| `seo-drift` | SEO drift analysis agent. Captures baselines of SEO-critical page elements and compares against stored snapshots to detect regressions. Reports changes with severity classification. Only spawned when  |
| `seo-ecommerce` | E-commerce SEO analyst. Validates product schema, analyzes Google Shopping and Amazon marketplace visibility, identifies pricing gaps, and recommends product page optimizations. Spawned when e-commerc |
| `seo-geo` | GEO and AI search specialist. Analyzes AI crawler accessibility, llms.txt compliance, passage-level citability, brand mention signals, and platform-specific optimization for Google AI Overviews, ChatG |
| `seo-google` | Google SEO API analyst. Fetches CWV field data via CrUX, indexation status via GSC, and organic traffic via GA4 for enriched audit data. |
| `seo-image-gen` | SEO image analyst. Audits existing OG/social preview images, identifies missing or low-quality images, and creates an image generation plan with prompts for key pages. Does NOT auto-generate images. |
| `seo-local` | Local SEO specialist. Analyzes GBP signals, NAP consistency, citations, reviews, local schema, location page quality, and industry-specific local factors for brick-and-mortar, SAB, and multi-location  |
| `seo-maps` | Maps intelligence specialist. Geo-grid rank tracking, GBP profile auditing, review intelligence, cross-platform NAP verification, and competitor radius mapping via DataForSEO and free APIs. |
| `seo-performance` | Performance analyzer. Measures and evaluates Core Web Vitals and page load performance. |
| `seo-schema` | Schema markup expert. Detects, validates, and generates Schema.org structured data in JSON-LD format. |
| `seo-sitemap` | Sitemap architect. Validates XML sitemaps, generates new ones with industry templates, and enforces quality gates for location pages. |
| `seo-sxo` | Search Experience Optimization analyst. Performs SERP backwards analysis to detect page-type mismatches, derives user stories from intent signals, and scores pages from multiple persona perspectives.  |
| `seo-technical` | Technical SEO specialist. Analyzes crawlability, indexability, security, URL structure, mobile optimization, Core Web Vitals, and JavaScript rendering. |
| `seo-visual` | Visual analyzer. Captures screenshots, tests mobile rendering, and analyzes above-the-fold content using Playwright. |
