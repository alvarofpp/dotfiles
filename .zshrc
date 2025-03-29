# oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"
plugins=(git)
source $ZSH/oh-my-zsh.sh
source $ZSH/templates/headline.zsh-theme

# Avoid duplicates
HISTCONTROL=ignoredups:erasedups

# Python
alias python="python3.10"

# Taskfile
export PATH="${PATH}:/home/alvarofpp/.local/bin"

# Autocompletion (Taskfile)
autoload -U compinit
compinit -i

# Add Pulumi to the PATH
export PATH=$PATH:/home/alvarofpp/.pulumi/bin

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Others
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/bin/terraform terraform

# fzf
source <(fzf --zsh)
fg="#CBE0F0"
bg="#011628"
bg_highlight="#143652"
purple="#B388FF"
blue="#06BCE4"
cyan="#2CF9ED"

export FZF_DEFAULT_OPTS="--color=fg:${fg},bg:${bg},hl:${purple},fg+:${fg},bg+:${bg_highlight},hl+:${purple},info:${blue},prompt:${cyan},pointer:${cyan},marker:${cyan},spinner:${cyan},header:${cyan}"

show_file_or_dir_preview="if [ -d {} ]; then exa --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'exa --tree --color=always {} | head -200'"

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
export BAT_THEME=tokyonight_night
alias cat="bat"

# zoxide (better cd)
eval "$(zoxide init zsh)"
alias cd="z"

# exa (better ls)
alias ls="exa"
alias ll="exa -alh"
alias tree="exa --tree"
