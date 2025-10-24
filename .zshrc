WSL_USER="alvaro"
WINDOWS_DIR="/mnt/c/Documents\ and\ Settings/alvar/"

# Homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"
plugins=(fzf-tab)
source $ZSH/oh-my-zsh.sh
export LESS=FRX

# Autocomplete
autoload -U compinit; compinit -i

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Theme
  source $HOME/zsh-themes/headline.zsh-theme

  # Catppuccin
  source $HOME/zsh-themes/syntax-highlighting/catppuccin_mocha-zsh-syntax-highlighting.zsh

elif [[ "$OSTYPE" == "darwin"* ]]; then
  # JetBrains
  export PATH="/Users/${WSL_USER}/Library/Application Support/JetBrains/Toolbox/scripts:${PATH}"
fi

# History
HISTSIZE=5000
HISTFILESIZE=50000
HISTCONTROL=ignoredups:erasedups

# Python
alias python="python3.13"

# Remove Python 2.7 from Path
# Reference: https://stackoverflow.com/a/370192
export PATH=`echo ${PATH} | awk -v RS=: -v ORS=: '/2.7/ {next} {print}'`

# Taskfile
export PATH="${PATH}:/home/${WSL_USER}/.local/bin"
alias t=task --global
eval "$(task --completion zsh)"

# Add Pulumi to the PATH
export PATH="$PATH:/home/${WSL_USER}/.pulumi/bin"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Others
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/bin/terraform terraform
alias unstow='stow --delete'

# fzf
source <(fzf --zsh)
fg="#CBE0F0"
bg="#011628"
bg_highlight="#143652"
purple="#B388FF"
blue="#06BCE4"
cyan="#2CF9ED"

export FZF_DEFAULT_OPTS="--color=fg:${fg},bg:${bg},hl:${purple},fg+:${fg},bg+:${bg_highlight},hl+:${purple},info:${blue},prompt:${cyan},pointer:${cyan},marker:${cyan},spinner:${cyan},header:${cyan}"

show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# fd (better find)
# Use fd instead of fzf
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

# bat (better cat)
export BAT_THEME="Monokai Extended Origin"
alias cat="bat"

# zoxide (better cd)
eval "$(zoxide init zsh)"
alias cd="z"

# eza (better ls)
alias ls="eza"
alias ll="eza -alh"
alias tree="eza --tree"

# atuin (better history)
eval "$(atuin init zsh)"

# SSH
# Create an agent for SSH if it doesn't exist.
# ssh-add -l &> /dev/null
# if [ $? -ne 0 ]; then
#   ssh-add -t 5d ~/.ssh/id_rsa && echo "SSH agent created!"
# fi

# Docker
alias dc="docker compose"

# Vagrant
# export VAGRANT_HYPERV_ADMIN_ACCESS="1"
export VAGRANT_DEFAULT_PROVIDER="virtualbox"
export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
export PATH="$PATH:/mnt/c/Program Files/Oracle/VirtualBox"
export VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH="/mnt/c/Vagrant"
