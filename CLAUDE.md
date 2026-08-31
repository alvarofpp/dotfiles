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

- [`TODO.md`](TODO.md) — pendências forward-looking do parent (sem conteúdo de IA).
- [`CHANGELOG.md`](CHANGELOG.md) — mudanças release-worthy (Keep-a-Changelog).
- [`docs/DECISION_LOG.md`](docs/DECISION_LOG.md) — decisões médias do parent.
- [`AGENTS.md`](AGENTS.md) — recorte do repo em contextos de revisão, lido pelo `/review-pr`. Pré-requisito do fluxo autônomo; catálogo gerado por `task ai:agents-doc`. Os agentes deste repo vêm do submódulo `ai/`.

O submódulo `ai/` é o repositório **privado** — o critério de admissão é privacidade, não o tema. Nasceu focado em IA, mas hoje abriga também config de serviços self-hosted (`.hermes/`, `docker/`, `.config/homepage/`). Conteúdo de IA / Claude Code / Hermes / opencode e qualquer config privada vivem **só nele** ([`ai/README.md`](ai/README.md), [`ai/TODO.md`](ai/TODO.md), [`ai/CHANGELOG.md`](ai/CHANGELOG.md), [`ai/DECISION_LOG.md`](ai/DECISION_LOG.md), [`ai/docs/DEV_ONBOARDING.md`](ai/docs/DEV_ONBOARDING.md), [`ai/docs/GLOSSARY.md`](ai/docs/GLOSSARY.md)). Parent é repo público; não adicionar IA na raiz.

## Architecture Notes

- **`ai/` is a git submodule** pointing to `alvarofpp/dotfiles-ai`. Changes there require separate commits/pushes. The main repo tracks a submodule pointer.
- **`.stow-local-ignore`** excludes non-dotfile assets (README, setup.sh, iterm/, etc.) from stow operations. Edit this when adding new top-level files that shouldn't be symlinked. The `ai/` submodule has its **own** `.stow-local-ignore` that filters Claude Code runtime dirs (`backups/`, `cache/`, `file-history/`, `sessions/`, `history.jsonl`, etc.) so `stow ai` only links stable config (`commands/`, `agents/`, `skills/`, `rules/`, `hooks/`, `plugins/`, `CLAUDE.md`, `RTK.md`, `settings.json`).
- **Taskfiles** (`home/Taskfile.yml` + `home/taskfiles/`) provide global tasks via `task` (aliased as `t`). Namespaces: `cc:` (Claude Code), `docker:`, `gh:` (GitHub Project "Agentes" — `home/taskfiles/GitHub.yml`), `op:`, `py:`, `ai:` (Hermes services + plugin claude_code + opencode standalone — `ai/taskfiles/AI.yml`) e `svc:` (stack Docker dos serviços locais do notebook: Traefik + homepage + o `svc-ctl`, unit systemd-user que faz a homepage subir/descer projeto e Orca — `ai/taskfiles/Services.yml`; manual em `ai/docs/homepage.md`). Os dois últimos são incluídos via path absoluto `$HOME/dotfiles/...` pra resolver o symlink do stow. `ai:` inclui as tasks de Hermes (`restart`, `logs-*`, `projects-*`, `update`) mais as de opencode (`restart-opencode`, `logs-opencode`, `opencode-sync-agent`). `gh:` opera o board e roda o **fluxo autônomo de review** em cima dele. O Status da issue é a máquina de estados e cada tick lê uma coluna: `prep` tria (`/issue-prep`: repo apto, enunciado executável, labels, sem assignee de outro), `dispatch` implementa ou aplica review, `pr-tick` revisa, `settle` confere critérios de aceite, `unblock` destrava o que esperava resposta humana, `close` fecha issue e worktree (em `Dropped`, fecha o PR antes, sem mesclar). O **merge é o único passo humano**. `trusted` guarda o `unblock` (só quem tem acesso de escrita destrava issue parada; o `prep` não tem portão de autoria — issue em Ready passou pela sua mão, e quem procura injeção no texto é o `/issue-prep`), `agents-ready` o interruptor de consentimento (stack `svc:` de pé), `review-ready` o pré-requisito por repo (`AGENTS.md`), `reap` solta lock de agente morto, `pr-board` dá Status aos cards de PR e `notify` avisa no Telegram **cada etapa** — uma mensagem por transição de Status (ID+título, link, status novo com o anterior, ação), configurado em `~/.config/gh-board/telegram.env`, sem ele o tick segue calado. Os de sempre seguem: `repos`, `link`, `unlink`, `sync`, `defaults`, `issues`, `issue-status`, `repo-path`, `labels`, `status`, `orca`, `done`. A lista de repos não vive no código, sai do próprio Project.
- **systemd-user**: `home/.config/systemd/user/gh-board-defaults.{service,timer}` roda a cada 15 min o tick do GitHub Project — `sync`, `reap`, `unblock`, `prep`, `dispatch`, `pr-tick`, `settle`, `close`, `pr-board`, `done` e `notify`, nessa ordem. Units do submódulo `ai/` (Hermes, opencode, svc-ctl, orca-serve) ficam em `ai/.config/systemd/user/`.
- **RTK (Rust Token Killer)** is installed via brew and configured at `home/.config/rtk/filters.toml`. Claude Code hooks transparently rewrite commands through `rtk` for token savings.
- **Shell**: zsh with oh-my-zsh, headline theme, Catppuccin Mocha syntax highlighting, fzf-tab plugin.
- **Shell drop-ins**: `home/.zshrc` sources `$HOME/.zshrc.d/*.zsh` (drop-in dir, populated by the `ai/` submodule — keeps AI-related shell helpers out of the dotfiles root) and `$HOME/.zshrc.local` if present (uncommitted secrets/overrides like `MINIMAX_API_KEY`).
- **Platform**: WSL2 (Linux on Windows). The `windows/` package targets the Windows host filesystem.
- **`windows-terminal-settings.json`** (root) is a **manual copy** of the live Windows Terminal config at `/mnt/c/Users/alvar/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json` — **not stowed, not symlinked**. A symlink can't work: Windows won't follow a symlink into the WSL ext4, and WT rewrites the file atomically (clobbering any link). Edit the real file for effect, then `cp` it back over the repo copy before committing. See `docs/DECISION_LOG.md` (2026-07-14).
