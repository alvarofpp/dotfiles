# Changelog

Mudanças relevantes do repositório dotfiles (parent, público). Mudanças do submódulo `ai/` (privado) vivem em [`ai/CHANGELOG.md`](ai/CHANGELOG.md); pointer bumps do submódulo aqui são consequência, não entrada dedicada.

Segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) — releases ainda não taggeadas, datas servem de delimitador.

## [Unreleased]

### Adicionado

- `docs/` (parent), `CHANGELOG.md`, `docs/DECISION_LOG.md` — adere à regra global `docs-as-second-brain`.
- `home/.config/psysh/` ignorado (REPL history vaza queries SQL e código testado).

### Mudado

- `TODO.md` raiz purgado de conteúdo de IA — migrado pro `ai/TODO.md`. Parent agora foca em stow/setup/shell tooling.

---

## 2026-05 — Tooling + drop-ins

### Adicionado

- **opencode + gnome-keyring no `setup.sh`** — `brew install anomalyco/tap/opencode` e `apt install gnome-keyring` (Linux-only). gnome-keyring é backend de libsecret pra Emdash/opencode guardarem tokens em sessões WSL2 sem desktop.
- **uv** instalado via `curl -LsSf https://astral.sh/uv/install.sh | sh` no `setup.sh`.
- **Drop-in dir `~/.zshrc.d/`** — `home/.zshrc` source todos os `.zsh` desse dir; submódulo `ai/` popula via `ai/.zshrc.d/`.
- **`~/.zshrc.local`** sourcing — segredos e overrides locais (não commitado).

### Mudado

- `~/.local/bin` agora vai no **início** do PATH (não no fim) pra wrappers locais terem precedência.

## 2026-04 — WSL2 + setup hardening

### Adicionado

- `windows/.wslconfig` — config WSL2 (pacote stow novo).
- `etc/wsl.conf` — config systemd dentro do WSL (pacote stow novo).
- Ignore de `home/.config/dconf/`, `home/.config/Emdash/`, `home/.config/libreoffice/`, `home/.config/JetBrains/` — todos runtime data.
- Ignore de `hermes-setup.zip` e `hermes-setup/` — workspace privado, fora do repo.

### Removido

- `home/.config/JetBrains/*` previamente rastreado — runtime data.

### Mudado

- Movimentação geral: arquivos da raiz pra `home/` (estrutura stow consistente).

## 2026-04 — RTK + Claude Code wiring

### Adicionado

- **RTK** (Rust Token Killer) instalado via brew. Config em `home/.config/rtk/filters.toml`. Hook do Claude Code reescreve comandos para usar `rtk` (60-90% token savings em dev ops).
- **Claude Code** instalado globalmente via `npm install -g @anthropic-ai/claude-code` no `setup.sh`.
- **Submódulo `ai/`** adicionado (`alvarofpp/dotfiles-ai`) — carrega config do Claude Code + Hermes + opencode + shell drop-ins.
- **Taskfiles namespacedos** (`home/Taskfile.yml` + `home/taskfiles/`) — namespaces `cc:`, `docker:`, `op:`, `py:`, `ai:` (este último incluído via path absoluto `$HOME/dotfiles/ai/taskfiles/AI.yml` por causa do symlink do stow).
- `.editorconfig` na raiz.

## 2026-03 — Setup inicial + base

### Adicionado

- **`setup.sh`** — instala brew + zsh + oh-my-zsh + Catppuccin/JetBrains Mono + tools (atuin, bat, btop, eza, fd, fzf, go-task, httpie, jq, tlrc, yq, zoxide, 1password-cli, gh) + IT packages (python, node, deno, docker, pulumi) + cask apps em macOS.
- **`stow.sh`** — symlink dos packages `home/`, `ai/`, `etc/` (sudo), `windows/` (sudo).
- **`.stow-local-ignore`** raiz e por package — filtra non-dotfiles (README, LICENSE, setup.sh, runtime data).
- **`home/`** package — `.zshrc`, `.config/`, `.taskfiles/`, `zsh-themes/`.
- **CLAUDE.md** raiz com guidance do repo pra Claude Code.

---

## Como manter

- Toda mudança que mexe em `setup.sh`, `stow.sh`, packages `home/`/`etc/`/`windows/`, `Taskfile.yml`, ou `.gitignore` raiz vira entrada aqui.
- Bumps do submódulo `ai/` (`chore(ai): bump submodule ...`) não viram entradas — só apontam pro `ai/CHANGELOG.md`.
- Decisões com trade-off vão pro [`docs/DECISION_LOG.md`](docs/DECISION_LOG.md), não aqui.
- Pendências forward-looking vão pro [`TODO.md`](TODO.md), não aqui.
