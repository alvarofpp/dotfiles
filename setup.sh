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
  echo >&2 "Installing Homebrew Now"; \
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)";
}
INSTALL_CMD="brew install"
LIST_PACKAGES=$(brew list)

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
  "go-task"
  "httpie"
  "jq"
  "tlrc"
  "yq"
  "zoxide"
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

if [[ "$OSTYPE" == "darwin"* ]]; then
  brew install --cask iterm2
fi

echo "🎆 Done"
