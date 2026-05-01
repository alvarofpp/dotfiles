# TODO

## Next steps

### Hermes WebUI + plugin claude_code (2026-04-28)

- ~~**Tailscale serve HTTPS pendente**~~ — **resolvido em 2026-04-30**. Causa real: ACL do tailnet bloqueando porta 443. `tailscale debug netmap` mostra explicitamente quais portas inbound são aceitas (no caso, 80, 8080, 8787, 4097). Workaround sem mexer em ACL: rodar `tailscale serve --https=8080` em vez de 443. URL fica `https://<host>.<tailnet>.ts.net:8080`, cert continua válido. Para fix definitivo, editar ACL no admin (https://login.tailscale.com/admin/acls) liberando 443. Diagnóstico completo capturado na skill `tailscale-diag`.

- **WSL2 mirrored networking falhou** — retentado em 2026-04-30 com Docker Desktop encerrado completamente, `firewall=false` no `.wslconfig`, e `wsl --shutdown` limpo. Mesmo assim eth0 voltou em `172.27.x.x` e `tailscale status --json` mantém `Self.Endpoints=None`. Sem visibility no Event Viewer (precisa admin no PowerShell), diagnóstico esgotado. Pivotamos pra rodar `tailscale serve` no Windows host (peer `alienware-win` tem endpoints anunciáveis e alcança WSL via NAT forwarding default). Se algum Windows update mudar comportamento, retestar mirrored.

- **Outros projetos no `projects.yaml`** — adicionados `infra` e `cozinha-app`. Faltam outros se vierem (ai-agency etc.). Agora dá pra adicionar via `task ai:projects-add NAME=foo PATH=/abs/path` ou via tool no chat do Hermes (`claude_code_add_project`).

- **Limpar stow do submódulo `ai/`** — `stow ai` ainda falha por conflitos pré-existentes em `~/.hermes/SOUL.md`, `~/.hermes/config.yaml` e dirs de `~/.claude/` que não estão no `.stow-local-ignore`. Hoje o `~/.taskfiles/AI.yml` (que stow gerenciaria após `stow ai`) não está symlinkado, mas o include do `home/Taskfile.yml` usa path absoluto `$HOME/dotfiles/ai/taskfiles/AI.yml` então funciona. Pra um stow limpo do `ai/`, ignorar `.hermes/SOUL.md`, `.hermes/config.yaml` e os outros conflitos no `.stow-local-ignore`.

- **PR upstream em `hermes-webui` pra tornar `SESSION_TTL` configurável** (2026-05-01) — hoje tem patch local em `/home/alvaro/projetos/hermes-webui/api/auth.py:27` mudando o TTL de 24h pra 90 dias (`7776000`). Constante hardcoded, então `git pull` no upstream conflita. Proposta: ler de env var `HERMES_WEBUI_SESSION_TTL` (segundos) com fallback pro default atual de 86400. Pontos de mudança: `api/auth.py` (constante + uso na linha 157 e 244), `.env.example` (documentar), e teste em `tests/test_auth_sessions.py:92` (`test_session_ttl_is_24_hours` precisa virar parametrizado ou checar via env). Service systemd (`~/.config/systemd/user/hermes-webui.service`) já tem `EnvironmentFile=%h/.config/hermes-webui/secrets.env`, então setar lá após merge resolve sem patch local.

### opencode standalone (2026-04-28)

- **Revisar UX mobile do opencode** — após uns dias usando `opencode serve` via Tailscale pelo celular (`http://100.64.95.14:4097`), avaliar se a UI oficial (Astro + Solid.js, focada em desktop) é boa o suficiente em smartphone. Se a experiência ficar ruim, plugar [`hosenur/portal`](https://github.com/hosenur/portal) — frontend community mobile-first que conecta no mesmo backend via API do `opencode serve`. Setup, arquitetura e migration path documentados em [`ai/docs/opencode.md`](ai/docs/opencode.md).

### Pós-auditoria de skills (2026-04-25)

- **Setup do venv do plugin SEO** — manual, fora do git:
  ```bash
  cd ~/.claude/skills/seo && python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
  ```
  Sem o venv, scripts de seo-audit/seo-backlinks/seo-google etc. não rodam.

- **Auditar as 15 skills copiadas pro projeto Matria** (`~/alvarofpp/matria/.claude/skills/`). Foram copiadas as-is no commit `f0bccaa` para preservar guidance projeto-específica. Próxima passada deve:
  - Manter só o que é genuinamente Matria-específico (tokens, paths, voz, personas)
  - Remover conteúdo já coberto pela versão global generalizada (evitar drift duplicado)
  - Casos LIGHT (8 skills) provavelmente podem ser deletados — a global limpa basta

- **Splits incompletos da Batch 6** (opcional) — duas skills ficaram acima do target ~250 linhas:
  - `laravel-l10n/SKILL.md` — 353 linhas (split parcial; PHP examples + middleware/notification ainda inline)
  - `code-review/SKILL.md` — 256 linhas (6 acima do target; restante é processo agnóstico de linguagem)

### Multi-model setup (2026-04-26)

- **Criar `~/.zshrc.local`** com `MINIMAX_API_KEY` (não commitado). Sem isso a função `claude-mini` falha com mensagem instrutiva. Pega chave em https://platform.minimax.io/.
- **Validar emdash spawn de agentes** — bug `stripAnsi` (`Cannot find module '@shared/text/stripAnsi'`) que afetava v0.4.50 sumiu na v1.1.3 (instalada 2026-04-27 via `releases.emdash.sh`). Ainda assim, abrir um worktree e confirmar que `claude-mini` funciona dentro dele antes de remover esta nota. Bonus: a v1 trouxe auto-update embutido pra `.deb`, então provavelmente não precisa mais baixar `.deb` manualmente.

### Stow do submódulo `ai/` (2026-04-27)

- **Symlinks ad-hoc em `~/.claude/`** — durante a sessão de hoje criei manualmente os 9 symlinks de config (`commands`, `agents`, `hooks`, `plugins`, `rules`, `skills`, `CLAUDE.md`, `RTK.md`, `settings.json`) porque `stow ai` ainda não tinha o ignore de runtime. Após o submodule bump (`849a4c3` em `ai/`, `9b6b2ef` no parent), `stow ai` agora roda limpo. Pra padronizar e tornar `stow -D ai` reversível: `rm` os 9 symlinks ad-hoc e rodar `stow ai` pra recriar via stow. Comportamento funcional idêntico, só fica "owned by stow" em vez de manual.

## Pending tasks

- **Banana extension não instalada** — o plugin claude-seo tem `extensions/banana/` (geração de imagem via Gemini/MCP) que não foi copiado. Se quiser usar `seo-image-gen` em modo geração real, rodar install.sh oficial do plugin com `CLAUDE_SEO_TAG=v1.9.0` ou copiar manualmente.

- **Skill `pdf` — case-sensitivity** (warning Fase 1 não resolvido): SKILL.md cita `REFERENCE.md` e `FORMS.md` mas os arquivos existem em lowercase (`reference.md`, `forms.md`). Em Linux case-sensitive isso pode quebrar refs. Verificar se runtime normaliza casing ou se é bug latente.

- **Relatórios da auditoria em `/tmp/`** — volátil. Se quiser preservar, mover para `~/dotfiles/ai/docs/skills-audit/`:
  - `/tmp/skills-audit-fase1-20260425-1036.md` (inventário 113 skills)
  - `/tmp/skills-audit-fase2-20260425-1139.md` (rubric 28 skills)
  - `/tmp/skills-audit-plano-20260425-1139.md` (plano 6 batches)

## Decisões e convenções

Movidas para [`ai/docs/skills-conventions.md`](ai/docs/skills-conventions.md). Cobre frontmatter válido, regra de `name` casando com slug, escopo global vs projeto, description de gatilho, progressive disclosure, e setup do plugin SEO.

### Hermes — plugin claude_code (2026-04-28)

Detalhamento em [`ai/docs/hermes-overview.md`](ai/docs/hermes-overview.md) e [`ai/docs/hermes-claude-code.md`](ai/docs/hermes-claude-code.md). Resumo das decisões:

- **Bridge daemon host↔container** — Hermes corre o agent em container Docker (`terminal.backend: docker`, hardening etapa 5). Plugin `hermes-claude-code` precisa rodar tmux + claude no host. Solução: daemon systemd no host (`hermes-cc-bridge.service`) escuta Unix socket; plugin (no container) é cliente fino via socket bind-mounted path-preserving.
- **`/remote-control` Anthropic-only** — exige claude.ai OAuth, não funciona com providers terceiros. Toolset suporta apenas opus/sonnet/haiku. MiniMax fica fora, é usado direto via Hermes WebUI nativo apontando workspace pro projeto.
- **Workspaces do Hermes WebUI** — `~/.hermes/webui/workspaces.json` lista dotfiles, infra, cozinha-app, Home. Default trocado de `dummy-project` pra `dotfiles`.
- **Tasks `ai:*`** — health/restart/logs dos services + projects-list/add/remove pra gerenciar projects.yaml do plugin via CLI. Definidas em `ai/taskfiles/AI.yml`, incluídas pelo `home/Taskfile.yml` via path absoluto `$HOME/dotfiles/ai/taskfiles/AI.yml` (path relativo `../ai/...` quebra com symlink do stow).
- **`.hermes.md` per-projeto** — Matria tem o seu (políticas LGPD/RDS prod/Swarm). `~/.hermes/SOUL.md` cobre identidade/políticas globais. Hermes carrega ambos automaticamente.

### Skills + agente alienware (2026-04-30)

Criadas 4 skills + 1 agente envelope no submodule `ai/.claude/`, fruto da sessão de debug do Tailscale serve do ai-agency:

- **`hermes-ops`** (original) — operação dos services Hermes em systemd-user (gateway/cc-bridge/webui), plugin hermes-expose (lockfile, expose_*, projects.yaml), drop-ins versionados, gotcha do dir-real vs symlink-de-dir
- **`tailscale-diag`** (original) — diagnóstico de `tailscale serve` self-hosted: árvore de decisão em 6 passos, leitura de packet filter via `tailscale debug netmap`, distinção Lock vs ACL, interpretação de `Self.Endpoints=None`, antipadrão "deve ser ACL" quando 403 vem do app
- **`wsl-networking`** (original) — modos NAT vs mirrored, Docker Desktop bloqueando shutdown, plano B (Tailscale-no-Windows), regra dura "nunca Funnel"
- **`linux-ops`** (fork MIT) — sysadmin Linux genérico baseado em [`majiayu000/claude-skill-registry/administering-linux`](https://github.com/majiayu000/claude-skill-registry) + references/* derivados de [`L3DigitalNet/Claude-Code-Plugins/linux-sysadmin`](https://github.com/L3DigitalNet/Claude-Code-Plugins) (systemd, sysctl, lvm/btrfs/ext4, sshd/fail2ban/apparmor/selinux, nftables/iptables/ufw/firewalld) + troubleshooting-guide próprio. Atribuição em `linux-ops/NOTICE.md`.
- **`alienware`** (agent) — orquestrador cross-domain das 3 skills core (hermes-ops, tailscale-diag, wsl-networking) + adjacentes (linux-ops, docker-patterns, runbook-authoring, python-expert). Triagem antes de rodar comando + sequência padrão de diagnóstico em 6 passos + 3 playbooks por sintoma + regras duras (não Funnel, confirmar destrutivos, paths absolutos).

Drop-ins systemd novos (`ai/.config/systemd/user/`):
- `restart.conf` em hermes-{gateway,cc-bridge,webui} — `Restart=always` + `RestartSec=60` + `StartLimitIntervalSec=0` pra resiliência a queda longa de net
- Conversão de **symlink-de-dir** pra **dir-real + symlink-de-files** nos 3 `*.service.d/` runtime (systemd-user não segue symlink-de-dir; gotcha capturado em `hermes-ops` skill)

Mensagem de erro mais explícita no `orchestrator.py` do plugin hermes-expose quando `task` não está no PATH.

### Multi-model (2026-04-26)

Detalhamento em [`ai/docs/multi-model-setup.md`](ai/docs/multi-model-setup.md) e regra global em [`ai/.claude/rules/multi-provider-handoff.md`](ai/.claude/rules/multi-provider-handoff.md). Resumo das decisões:

- **Arquitetura dual-tool**: Claude Code (Opus via assinatura Pro/Max) + função `claude-mini` (Claude Code apontado pra MiniMax M2.7 via API). Razão: Anthropic baniu OAuth de assinatura em ferramentas third-party em 2025; routers e ADEs alternativas exigiriam pagar API key Anthropic separada — regressão custosa.
- **Drop-in dir `~/.zshrc.d/`**: `home/.zshrc` source todos os `.zsh` desse dir; submódulo `ai/` popula via `ai/.zshrc.d/`. Mantém shell helpers de IA fora da raiz do dotfiles (regra de isolamento).
- **`~/.zshrc.local`** (não commitado): segredos e overrides locais. `MINIMAX_API_KEY` mora aqui.
- **Orquestração visual via emdash**: instalado dentro do WSL2 (`.deb` Linux + WSLg), não build Windows (file watching cross-boundary é quebrado, issue #1528).
- **Handoff entre sessões via `PLAN.md`**: sessões Claude Code são amarradas a um único provider via `ANTHROPIC_BASE_URL`, então não dá pra mixar Opus+MiniMax na mesma sessão. `PLAN.md` na raiz do projeto serve de "second brain" cross-provider — regra global em [`multi-provider-handoff.md`](ai/.claude/rules/multi-provider-handoff.md).
