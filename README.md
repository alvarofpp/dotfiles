# Dotfiles and setup

This repository contains the dotfiles for my system and setup script.

## Requirements

For setup:

```bash
sudo apt install -y curl
```

For dotfiles:

```bash
sudo apt install -y git stow
```

## Setup

```bash
curl -fsSL https://raw.githubusercontent.com/alvarofpp/dotfiles/refs/heads/main/setup.sh | /bin/bash -c
```

`setup.sh` will install [Homebrew][homebrew] if it hasn't already been installed.
Homebrew will be the package manager used to install all the terminal tools.

In addition to the conventional packages (`git`, `curl`, etc),
the script installs the following packages:

| Tool      | Description                                      | Link            |
|-----------|--------------------------------------------------|-----------------|
| `atuin`   | Alternative to `history`.                        | [link][atuin]   |
| `bat`     | Alternative to `cat`.                            | [link][bat]     |
| `btop`    | Alternative to `top`/`htop`.                     | [link][btop]    |
| `eza`     | Alternative to `ls`.                             | [link][eza]     |
| `fd`      | Alternative to `find`.                           | [link][fd]      |
| `fzf`     | Interactive filter program for any kind of list. | [link][fzf]     |
| `go-task` | Taskfile is a task runner.                       | [link][go-task] |
| `httpie`  | Alternative to `curl`.                           | [link][httpie]  |
| `jq`      | Command-line JSON processor.                     | [link][jq]      |
| `tldr`    | Collaborative cheatsheets for console commands.  | [link][tldr]    |
| `yq`      | Command-line YAML processor.                     | [link][yq]      |
| `zoxide`  | Alternative to `cd`.                             | [link][zoxide]  |

## Dotfiles

```bash
git clone git@github.com:alvarofpp/dotfiles.git
cd dotfiles
stow .
```

## Appearance

For my color theme I like [Catppuccin][themes-catppuccin].

- [Windows terminal][themes-catppuccin-wsl]
- [iTerm2][themes-catppuccin-iterm]

Fonts:

- [JetBrains Mono][fonts-jetbrains-mono]

[homebrew]: https://brew.sh/
[atuin]: https://github.com/atuinsh/atuin
[bat]: https://github.com/sharkdp/bat
[btop]: https://github.com/aristocratos/btop
[eza]: https://github.com/eza-community/eza
[fd]: https://github.com/sharkdp/fd
[fzf]: https://github.com/junegunn/fzf
[go-task]: https://taskfile.dev/
[httpie]: https://github.com/httpie/cli
[jq]: https://github.com/jqlang/jq
[tldr]: https://github.com/tldr-pages/tldr
[yq]: https://github.com/mikefarah/yq
[zoxide]: https://github.com/ajeetdsouza/zoxide

[themes-catppuccin]: https://github.com/catppuccin
[themes-catppuccin-wsl]: https://github.com/catppuccin/windows-terminal
[themes-catppuccin-iterm]: https://github.com/catppuccin/iterm/issues/27#issuecomment-2513558106

[fonts-jetbrains-mono]: https://www.jetbrains.com/pt-br/lp/mono/