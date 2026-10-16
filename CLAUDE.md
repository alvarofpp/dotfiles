# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A dotfiles repo managed with [GNU Stow](https://www.gnu.org/software/stow/). Stow packages are directories that mirror the target filesystem tree; symlinks are created at the target root.

## Stow Packages

| Package | Target | Contents |
|---------|--------|----------|
| `home/` | `$HOME` | zsh, fzf, bat, eza, zoxide, atuin, git, taskfiles, rtk config |
| `private/` | `$HOME` | Claude Code config (`.claude/`) + shell drop-ins (`.zshrc.d/`). **Separate git submodule** (`dotfiles-private`) |
| `etc/` | `/etc` | `wsl.conf` (requires sudo) |
| `windows/` | `/mnt/c/Users/alvar` | `.wslconfig` — **copiado, não symlinkado** (ver Architecture Notes) |

## Key Commands

```bash
./stow.sh              # Symlink all packages to their targets
./stow.sh --dry-run    # Preview without applying (detects WSL2 vs other platforms)
stow --delete home     # Unlink a single package (alias: unstow)
./setup.sh             # Full system bootstrap (brew, packages, fonts, plugins, health check)
```

## Docs

Este repo **não tem** `TODO.md` nem `CHANGELOG.md` — deixaram de existir em 2026-09-05, aqui e em todos os repos do board, porque eram a fonte nº 1 de conflito entre PRs de agentes paralelos.

O `AGENTS.md` **voltou** pra raiz em 2026-09-08. Ele tinha saído em 2026-09-03 por descrever o fluxo autônomo inteiro (board, repos de cliente, quais camadas de segurança nunca foram exercitadas) num repositório público; a versão de volta é o recorte que pode ser público — stow, tasks, testes de task, bootstrap, serviços da máquina, docs e o ponteiro do submódulo.

- **Pendência é issue em [`alvarofpp/dotfiles-private`](https://github.com/alvarofpp/dotfiles-private/issues)** — inclusive a do parent (`home/taskfiles/`, `stow.sh`). **Nunca** abrir issue em `alvarofpp/dotfiles`: ele é público, e a issue carrega detalhe do fluxo e de repos de cliente. Commit no parent referencia `Refs alvarofpp/dotfiles-private#N`. Não recriar `TODO.md`.
- **Decisão do parent** vira um arquivo em [`private/docs/decisions/`](private/docs/decisions/README.md) (`YYYY-MM-DD-slug.md`) — commit separado, porque é outro repositório. **Sem índice**: o diretório já é o índice, e uma linha compartilhada por todos os PRs abertos é conflito por construção.
- O recorte **privado** de 2026-09-03 segue arquivado em [`private/docs/agents-dotfiles.md`](private/docs/agents-dotfiles.md), como base histórica. O que vale é o `AGENTS.md` da raiz: `task gh:review-ready REPO=alvarofpp/dotfiles` sai zero, e PR aqui ganha revisor.

O submódulo `private/` é o repositório **privado** — o critério de admissão é privacidade, não o tema. Nasceu focado em IA, mas hoje abriga também config de serviços self-hosted (`.hermes/`, `docker/`, `.config/homepage/`). Conteúdo de IA / Claude Code / Hermes / opencode e qualquer config privada vivem **só nele** ([`private/README.md`](private/README.md), [`private/docs/decisions/`](private/docs/decisions/README.md), [`private/docs/DEV_ONBOARDING.md`](private/docs/DEV_ONBOARDING.md), [`private/docs/GLOSSARY.md`](private/docs/GLOSSARY.md)). Parent é repo público; não adicionar IA na raiz.

## Architecture Notes

- **`private/` is a git submodule** pointing to `alvarofpp/dotfiles-private`. Changes there require separate commits/pushes. The main repo tracks a submodule pointer.
- **`rendeira/` é submódulo privado** (`alvarofpp/rendeira`), mesmo regime do `private/`, mas **não é pacote stow** — o `stow.sh` não o linka.
- **`brazier/` é submódulo privado** (`alvarofpp/brazier`, gestão de microVMs no microsandbox), mesmo regime do `rendeira/`: **não é pacote stow**.
- **`.stow-local-ignore`** excludes non-dotfile assets (README, setup.sh, iterm/, etc.) from stow operations. Edit this when adding new top-level files that shouldn't be symlinked. The `private/` submodule has its **own** `.stow-local-ignore` that filters Claude Code runtime dirs (`backups/`, `cache/`, `file-history/`, `sessions/`, `history.jsonl`, etc.) so `stow private` only links stable config (`commands/`, `agents/`, `rules/`, `hooks/`, `skills/`, `CLAUDE.md`, `RTK.md`, `settings.json`). Desde 2026-09-08, `commands/`, `agents/`, `rules/` e `hooks/` são **symlinks de diretório** — arquivo novo aparece sem re-stow. `skills/` continua desdobrado de propósito: ele mistura o repo com `~/.agents/skills/`, e foldá-lo esconderia as skills de lá. `plugins/` é runtime e nunca foi linkado.

  **Um conflito aborta o pacote inteiro**, e o `./stow.sh` termina em `✅` do mesmo jeito — confira com `./stow.sh --dry-run | grep -i 'conflict\|aborted'`.
- **Taskfiles** (`home/Taskfile.yml` + `home/taskfiles/`) provide global tasks via `task` (aliased as `t`). Namespaces: `cc:` (Claude Code), `docker:`, `gh:` (GitHub Project "Agentes" — `home/taskfiles/GitHub.yml`), `op:`, `py:`, `ai:` (Hermes services + plugin claude_code + opencode standalone — `private/taskfiles/AI.yml`) e `svc:` (stack Docker dos serviços locais do notebook: Traefik + homepage + o `svc-ctl`, unit systemd-user que faz a homepage subir/descer projeto e Orca — `private/taskfiles/Services.yml`; manual em `private/docs/homepage.md`). Os dois últimos são incluídos via path absoluto `$HOME/dotfiles/...` pra resolver o symlink do stow.
- **O namespace `gh:` é o fluxo autônomo de review** — opera o GitHub Project "Agentes" (`alvarofpp/projects/3`); `task --list-all | grep '^\* gh:'` lista as tasks. O Status da issue **é** a máquina de estados: cada tick lê uma coluna, tria (`prep`), implementa (`dispatch`), revisa (`pr-tick`), destrava (`unblock`, `answer`, `unstick`), confere (`settle`) e fecha (`close`). O **merge é o único passo humano**, junto de `Backlog → Ready` e `Dropped` — exceto no que o `automerge` liberar. O interruptor dele é `~/.local/state/gh-board/automerge` (um repo por linha, `!` nega e ganha de qualquer autorização; `cat` nele diz quem está autorizado, arquivo ausente desliga geral), ligado desde 2026-09-12. A referência completa — os oito Status, a ordem exata do tick, o vocabulário (labels `agent:*`, marcadores, `impl:`/`review:`/`agent:`), sub-issues, os portões de segurança, os filtros das views e os modos de falha conhecidos — está em **[`private/docs/gh-board-flow.md`](private/docs/gh-board-flow.md)**; não duplique aqui.
- **systemd-user**: `home/.config/systemd/user/gh-board-defaults.{service,timer}` **está desligado desde 2026-10-16** (`systemctl --user disable --now`) — a Rendeira assume o board ([decisão](private/docs/decisions/2026-10-16-tick-gh-board-desligado-rendeira-assume.md)); os arquivos ficam pra rollback (`systemctl --user enable --now ~/.config/systemd/user/gh-board-defaults.timer`, depois de `./stow.sh`). Quando ligado, rodava a cada 5 min o tick do GitHub Project — `gate-watch`, `sync`, `reap`, `sweep`, `unblock`, `answer`, `prep`, `dispatch`, `pr-tick`, `review-requested`, `unstick`, `automerge`, `settle`, `close`, `pr-board`, `done`, `metrics`, `merge-policy` e `notify`, nessa ordem — a ordem é a semântica, não arrumação. O `merge-policy` se autolimita a uma passada por dia, e o `notify` fecha a fila. Units do submódulo `private/` (Hermes, opencode, svc-ctl, orca-serve, rendeira e rendeira-backup) ficam em `private/.config/systemd/user/`.
- **`docker-gc.{service,timer}`** roda `task docker:gc` às 05:00 — build cache, imagem pendurada e volume **anônimo**. Não toca volume nomeado: nomeado é banco de instância, e instância parada com `dev:down` não é instância morta. Volume de worktree que sumiu sai pelo `task docker:gc:instancias`, que é manual e pede confirmação.
- **RTK (Rust Token Killer)** is installed via brew and configured at `home/.config/rtk/filters.toml`. Claude Code hooks transparently rewrite commands through `rtk` for token savings.
- **Shell**: zsh with oh-my-zsh, headline theme, Catppuccin Mocha syntax highlighting, fzf-tab plugin.
- **Shell drop-ins**: `home/.zshrc` sources `$HOME/.zshrc.d/*.zsh` (drop-in dir, populated by the `private/` submodule — keeps AI-related shell helpers out of the dotfiles root) and `$HOME/.zshrc.local` if present (uncommitted secrets/overrides like `MINIMAX_API_KEY`).
- **Platform**: WSL2 (Linux on Windows). The `windows/` package targets the Windows host filesystem.
- **`windows/.wslconfig` é copiado pelo `stow.sh`, não symlinkado** — mesma armadilha do `windows-terminal-settings.json`: o Windows não segue symlink pra dentro do ext4 do WSL, e um `.wslconfig` linkado é lido como **inexistente, sem erro nenhum**. Ficou assim de 2025-10-24 a 2026-09-06: a VM rodou o tempo todo no default de 50% da RAM em vez dos 24GB do arquivo. Conferir com `grep MemTotal /proc/meminfo` (24GB ≈ `24000000 kB`); aplicar exige `wsl --shutdown`, porque o arquivo só é lido quando a VM sobe.
- **`windows-terminal-settings.json`** (root) is a **manual copy** of the live Windows Terminal config at `/mnt/c/Users/alvar/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json` — **not stowed, not symlinked**. A symlink can't work: Windows won't follow a symlink into the WSL ext4, and WT rewrites the file atomically (clobbering any link). Edit the real file for effect, then `cp` it back over the repo copy before committing. See [`private/docs/decisions/2026-07-14-windows-terminal-settings-json-e-copia-sincronizada-nao-syml.md`](private/docs/decisions/2026-07-14-windows-terminal-settings-json-e-copia-sincronizada-nao-syml.md).
