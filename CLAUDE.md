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
stow --delete home     # Unlink a single package (alias: unstow)
./setup.sh             # Full system bootstrap (brew, packages, fonts, plugins)
```

## Architecture Notes

- **`ai/` is a git submodule** pointing to `alvarofpp/dotfiles-ai`. Changes there require separate commits/pushes. The main repo tracks a submodule pointer.
- **`.stow-local-ignore`** excludes non-dotfile assets (README, setup.sh, iterm/, etc.) from stow operations. Edit this when adding new top-level files that shouldn't be symlinked. The `ai/` submodule has its **own** `.stow-local-ignore` that filters Claude Code runtime dirs (`backups/`, `cache/`, `file-history/`, `sessions/`, `history.jsonl`, etc.) so `stow ai` only links stable config (`commands/`, `agents/`, `skills/`, `rules/`, `hooks/`, `plugins/`, `CLAUDE.md`, `RTK.md`, `settings.json`).
- **Taskfiles** (`home/Taskfile.yml` + `home/taskfiles/`) provide global tasks via `task` (aliased as `t`). Namespaces: `cc:` (Claude Code), `docker:`, `op:`, `py:`.
- **RTK (Rust Token Killer)** is installed via brew and configured at `home/.config/rtk/filters.toml`. Claude Code hooks transparently rewrite commands through `rtk` for token savings.
- **Shell**: zsh with oh-my-zsh, headline theme, Catppuccin Mocha syntax highlighting, fzf-tab plugin.
- **Shell drop-ins**: `home/.zshrc` sources `$HOME/.zshrc.d/*.zsh` (drop-in dir, populated by the `ai/` submodule — keeps AI-related shell helpers out of the dotfiles root) and `$HOME/.zshrc.local` if present (uncommitted secrets/overrides like `MINIMAX_API_KEY`).
- **Platform**: WSL2 (Linux on Windows). The `windows/` package targets the Windows host filesystem.
