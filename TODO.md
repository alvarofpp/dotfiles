# TODO

## Next steps

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

### Multi-model (2026-04-26)

Detalhamento em [`ai/docs/multi-model-setup.md`](ai/docs/multi-model-setup.md) e regra global em [`ai/.claude/rules/multi-provider-handoff.md`](ai/.claude/rules/multi-provider-handoff.md). Resumo das decisões:

- **Arquitetura dual-tool**: Claude Code (Opus via assinatura Pro/Max) + função `claude-mini` (Claude Code apontado pra MiniMax M2.7 via API). Razão: Anthropic baniu OAuth de assinatura em ferramentas third-party em 2025; routers e ADEs alternativas exigiriam pagar API key Anthropic separada — regressão custosa.
- **Drop-in dir `~/.zshrc.d/`**: `home/.zshrc` source todos os `.zsh` desse dir; submódulo `ai/` popula via `ai/.zshrc.d/`. Mantém shell helpers de IA fora da raiz do dotfiles (regra de isolamento).
- **`~/.zshrc.local`** (não commitado): segredos e overrides locais. `MINIMAX_API_KEY` mora aqui.
- **Orquestração visual via emdash**: instalado dentro do WSL2 (`.deb` Linux + WSLg), não build Windows (file watching cross-boundary é quebrado, issue #1528).
- **Handoff entre sessões via `PLAN.md`**: sessões Claude Code são amarradas a um único provider via `ANTHROPIC_BASE_URL`, então não dá pra mixar Opus+MiniMax na mesma sessão. `PLAN.md` na raiz do projeto serve de "second brain" cross-provider — regra global em [`multi-provider-handoff.md`](ai/.claude/rules/multi-provider-handoff.md).
