# Dotfiles

This repository contains the dotfiles for my system.

## Setup

```bash
curl -fsSL https://raw.githubusercontent.com/alvarofpp/dotfiles/refs/heads/master/setup.sh | /bin/bash -c
```

## Requirements

```bash
sudo apt install git stow -y
```

## How to use

```bash
git clone git@github.com:alvarofpp/dotfiles.git
cd dotfiles
stow .
```
