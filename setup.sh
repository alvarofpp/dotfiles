#!/bin/bash

function installPackage() {
  local L_INSTALL_CMD=$1
  local L_PACKAGE=$2
  local L_LIST_PACKAGES=$3
  if ! echo "${L_LIST_PACKAGES}" | grep -w -q "${L_PACKAGE}"; then
    echo "Installing ${L_PACKAGE}..."
    (eval "${L_INSTALL_CMD}" "${L_PACKAGE}" && echo "🎉 ${L_PACKAGE} was successfully installed") || echo "❌ ${L_PACKAGE}"
  else
    echo "✅ ${L_PACKAGE} is already installed"
  fi
}

# Install brew if not installed
command -v brew >/dev/null 2>&1 || {
  echo >&2 "Installing Homebrew now"; \
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)";
}
INSTALL_CMD="brew install"
LIST_PACKAGES=$(brew list)

# Install zsh
installPackage "${INSTALL_CMD}" "zsh" "${LIST_PACKAGES}"

# Check if oh-my-zsh is installed. If not, install it
if ! command -v zsh >/dev/null 2>&1 || [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo >&2 "Installing oh-my-zsh now"; \
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  chsh -s $(which zsh)
else
  echo "✅ oh-my-zsh is already installed"
fi

# Installing packages
PACKAGES=(
  "curl"
  "git"
  "stow"
  "wget"
  "atuin"
  "bat"
  "btop"
  "eza"
  "fd"
  "fzf"
  "gh"
  "go-task"
  "httpie"
  "jq"
  "tlrc"
  "yq"
  "zoxide"
  "1password-cli"
  "rtk"
)
for PACKAGE in "${PACKAGES[@]}"; do
  installPackage "${INSTALL_CMD}" "${PACKAGE}" "${LIST_PACKAGES}"
done

echo "📝 Configuring git..."
git config --global user.name "Álvaro Paiva"
git config --global user.email alvarofepipa@gmail.com

echo "📝 Downloading JetBrains Mono font..."
installPackage "brew install --cask" "font-jetbrains-mono" "${LIST_PACKAGES}"
fc-cache -f -v

echo "📝 Downloading syntax highlighting..."
installPackage "${INSTALL_CMD}" "zsh-syntax-highlighting" "${LIST_PACKAGES}"

echo "📝 Installing oh-my-zsh plugins..."
if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab" ]; then
  echo "⬇️ Cloning fzf-tab..."
  git clone https://github.com/Aloxaf/fzf-tab "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab"
else
  echo "✅ fzf-tab is already present"
fi

echo "🖥️ Installing desktop applications..."
if [[ "$OSTYPE" == "darwin"* ]]; then
  DESKTOP_APPS=(
    "orbstack"
    "notion"
  )
  for DESKTOP_APP in "${DESKTOP_APPS[@]}"; do
    installPackage "${INSTALL_CMD}" "${DESKTOP_APP}" "${LIST_PACKAGES}"
  done

  DESKTOP_APPS_WITH_CASK=(
    "iterm2"
    "notion-calendar"
    "jetbrains-toolbox"
    "zen-browser"
    "rectangle"
  )
  for DESKTOP_APP_WITH_CASK in "${DESKTOP_APPS_WITH_CASK[@]}"; do
    installPackage "brew install --cask" "${DESKTOP_APP_WITH_CASK}" "${LIST_PACKAGES}"
  done
fi

# IT tools
IT_PACKAGES=(
  "python"
  "node"
  "deno"
  "docker"
  "pulumi"
)
for IT_PACKAGE in "${IT_PACKAGES[@]}"; do
  installPackage "${INSTALL_CMD}" "${IT_PACKAGE}" "${LIST_PACKAGES}"
  if [ "${IT_PACKAGE}" = "node" ]; then
    echo "Installing TypeScript globally..."
    npm install -g typescript

    echo "Installing Claude Code globally..."
    npm install -g @anthropic-ai/claude-code
  fi
done

# AI coding agents
echo "🤖 Installing AI coding agents..."

# opencode (anomalyco tap — usado pra rotear MiniMax via Anthropic-compat).
# Não usa installPackage porque `brew list` mostra "opencode" curto, não o tap.
if ! brew list opencode >/dev/null 2>&1; then
  echo "Installing opencode (anomalyco/tap)..."
  brew install anomalyco/tap/opencode && echo "🎉 opencode was successfully installed" || echo "❌ opencode"
else
  echo "✅ opencode is already installed"
fi

# Linux-only system packages (apt)
# - gnome-keyring: backend de libsecret pra Emdash/opencode guardarem tokens em
#   sessões WSL2 sem desktop. Sem isso, "org.freedesktop.secrets was not provided".
if [[ "$OSTYPE" == "linux-gnu"* ]] && command -v apt-get >/dev/null 2>&1; then
  APT_PACKAGES=(
    "gnome-keyring"
  )
  echo "🐧 Installing apt packages..."
  for APT_PACKAGE in "${APT_PACKAGES[@]}"; do
    if /usr/bin/dpkg -s "${APT_PACKAGE}" >/dev/null 2>&1; then
      echo "✅ ${APT_PACKAGE} is already installed"
    else
      echo "Installing ${APT_PACKAGE}..."
      sudo apt-get install -y "${APT_PACKAGE}" && echo "🎉 ${APT_PACKAGE} was successfully installed" || echo "❌ ${APT_PACKAGE}"
    fi
  done
fi

# Install UV
curl -LsSf https://astral.sh/uv/install.sh | sh

# Submodule
git submodule update --init --recursive

echo "🎆 Done"
