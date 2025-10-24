#!/bin/bash

DOTFILES_DIR="$HOME/dotfiles"

stow -d "$DOTFILES_DIR" -t "$HOME" home
sudo "$(which stow)" -d "$DOTFILES_DIR" -t /etc etc --adopt
