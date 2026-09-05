# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A dotfiles repo managed with [GNU Stow](https://www.gnu.org/software/stow/). Stow packages are directories that mirror the target filesystem tree; symlinks are created at the target root.

## Stow Packages

| Package | Target | Contents |
|---------|--------|----------|
| `home/` | `$HOME` | zsh, fzf, bat, eza, zoxide, atuin, git, taskfiles, rtk config |
| `ai/` | `$HOME` | Claude Code config (`.claude/`) + shell drop-ins (`.zshrc.d/`). **Separate git submodule** (`dotfiles-ai`) |
| `etc/` | `/etc` | `wsl.conf` (requires sudo) |
| `windows/` | `/mnt/c/Users/alvar` | `.wslconfig` (requires sudo) |

## Key Commands

```bash
./stow.sh              # Symlink all packages to their targets
./stow.sh --dry-run    # Preview without applying (detects WSL2 vs other platforms)
stow --delete home     # Unlink a single package (alias: unstow)
./setup.sh             # Full system bootstrap (brew, packages, fonts, plugins, health check)
```

## Docs

Este repo **não tem** `TODO.md`, `CHANGELOG.md` nem `AGENTS.md`. O `AGENTS.md` foi pro submódulo privado em 2026-09-03, porque descrevia o fluxo autônomo de review inteiro (board, repos de cliente, quais camadas de segurança existem e quais nunca foram exercitadas) num repositório público. `TODO.md` e `CHANGELOG.md` deixaram de existir em 2026-09-05, aqui e em todos os repos do board — eram a fonte nº 1 de conflito entre PRs de agentes paralelos.

- **Pendência do parent é issue** em [`alvarofpp/dotfiles`](https://github.com/alvarofpp/dotfiles/issues). Não recriar `TODO.md`.
- **Decisão do parent** vira um arquivo em [`ai/docs/decisions/`](ai/docs/decisions/README.md) (`YYYY-MM-DD-slug.md` + linha no topo do índice) — commit separado, porque é outro repositório.
- O `AGENTS.md` foi arquivado em [`ai/docs/agents-dotfiles.md`](ai/docs/agents-dotfiles.md). Sem ele na raiz, o `task gh:review-ready` barra este repo: PR aqui não ganha revisor automático até alguém rodar `/agents-doc` de novo.

O submódulo `ai/` é o repositório **privado** — o critério de admissão é privacidade, não o tema. Nasceu focado em IA, mas hoje abriga também config de serviços self-hosted (`.hermes/`, `docker/`, `.config/homepage/`). Conteúdo de IA / Claude Code / Hermes / opencode e qualquer config privada vivem **só nele** ([`ai/README.md`](ai/README.md), [`ai/docs/decisions/`](ai/docs/decisions/README.md), [`ai/docs/DEV_ONBOARDING.md`](ai/docs/DEV_ONBOARDING.md), [`ai/docs/GLOSSARY.md`](ai/docs/GLOSSARY.md)). Parent é repo público; não adicionar IA na raiz.

## Architecture Notes

- **`ai/` is a git submodule** pointing to `alvarofpp/dotfiles-ai`. Changes there require separate commits/pushes. The main repo tracks a submodule pointer.
- **`.stow-local-ignore`** excludes non-dotfile assets (README, setup.sh, iterm/, etc.) from stow operations. Edit this when adding new top-level files that shouldn't be symlinked. The `ai/` submodule has its **own** `.stow-local-ignore` that filters Claude Code runtime dirs (`backups/`, `cache/`, `file-history/`, `sessions/`, `history.jsonl`, etc.) so `stow ai` only links stable config (`commands/`, `agents/`, `skills/`, `rules/`, `hooks/`, `plugins/`, `CLAUDE.md`, `RTK.md`, `settings.json`).
- **Taskfiles** (`home/Taskfile.yml` + `home/taskfiles/`) provide global tasks via `task` (aliased as `t`). Namespaces: `cc:` (Claude Code), `docker:`, `gh:` (GitHub Project "Agentes" — `home/taskfiles/GitHub.yml`), `op:`, `py:`, `ai:` (Hermes services + plugin claude_code + opencode standalone — `ai/taskfiles/AI.yml`) e `svc:` (stack Docker dos serviços locais do notebook: Traefik + homepage + o `svc-ctl`, unit systemd-user que faz a homepage subir/descer projeto e Orca — `ai/taskfiles/Services.yml`; manual em `ai/docs/homepage.md`). Os dois últimos são incluídos via path absoluto `$HOME/dotfiles/...` pra resolver o symlink do stow.
- **O namespace `gh:` é o fluxo autônomo de review** — 36 tasks que operam o GitHub Project "Agentes" (`alvarofpp/projects/3`). O Status da issue **é** a máquina de estados: cada tick lê uma coluna, tria (`prep`), implementa (`dispatch`), revisa (`pr-tick`), destrava (`unblock`, `answer`, `unstick`), confere (`settle`) e fecha (`close`). O **merge é o único passo humano**, junto de `Backlog → Ready` e `Dropped`. A referência completa — os oito Status, a ordem exata do tick, o vocabulário (labels `agent:*`, marcadores, `impl:`/`review:`/`agent:`), sub-issues, os portões de segurança e os modos de falha conhecidos — está em **[`ai/docs/gh-board-flow.md`](ai/docs/gh-board-flow.md)**; não duplique aqui.
- **systemd-user**: `home/.config/systemd/user/gh-board-defaults.{service,timer}` roda a cada 15 min o tick do GitHub Project — `gate-watch`, `sync`, `reap`, `unblock`, `answer`, `prep`, `dispatch`, `pr-tick`, `review-requested`, `unstick`, `settle`, `close`, `pr-board`, `done` e `notify`, nessa ordem. Units do submódulo `ai/` (Hermes, opencode, svc-ctl, orca-serve) ficam em `ai/.config/systemd/user/`.
- **RTK (Rust Token Killer)** is installed via brew and configured at `home/.config/rtk/filters.toml`. Claude Code hooks transparently rewrite commands through `rtk` for token savings.
- **Shell**: zsh with oh-my-zsh, headline theme, Catppuccin Mocha syntax highlighting, fzf-tab plugin.
- **Shell drop-ins**: `home/.zshrc` sources `$HOME/.zshrc.d/*.zsh` (drop-in dir, populated by the `ai/` submodule — keeps AI-related shell helpers out of the dotfiles root) and `$HOME/.zshrc.local` if present (uncommitted secrets/overrides like `MINIMAX_API_KEY`).
- **Platform**: WSL2 (Linux on Windows). The `windows/` package targets the Windows host filesystem.
- **`windows-terminal-settings.json`** (root) is a **manual copy** of the live Windows Terminal config at `/mnt/c/Users/alvar/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json` — **not stowed, not symlinked**. A symlink can't work: Windows won't follow a symlink into the WSL ext4, and WT rewrites the file atomically (clobbering any link). Edit the real file for effect, then `cp` it back over the repo copy before committing. See `ai/DECISION_LOG.md` (2026-07-14).
