#!/bin/bash

function installPackage() {
  local L_INSTALL_CMD=$1
  local L_PACKAGE=$2
  local L_LIST_PACKAGES=$3
  if ! echo "${L_LIST_PACKAGES}" | grep -w -q "${L_PACKAGE}"; then
    echo "Installing ${L_PACKAGE}..."
    (eval "${L_INSTALL_CMD}" "${L_PACKAGE}" && echo "✅ ${L_PACKAGE} was successfully installed") || echo "❌ ${L_PACKAGE}"
  else
    echo "✅ ${L_PACKAGE} is already installed"
  fi
}

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  APT_LIST_PACKAGES=$(ls /usr/bin)

  # Install snap if not installed
  installPackage "sudo apt install -y" "snap" "${APT_LIST_PACKAGES}"

  # [snap] Installing packages
  LIST_PACKAGES=$(snap list)
  PACKAGES=(
    "curl"
    "httpie"
    "jq"
    "task"
    "yq"
  )
  for PACKAGE in "${PACKAGES[@]}"; do
    installPackage "sudo snap install" "${PACKAGE}" "${LIST_PACKAGES}"
  done

  # [apt] Installing packages
  APT_PACKAGES=(
    "exa"
    "git"
    "stow"
    "wget"
    "zoxide"
  )
  for PACKAGE in "${APT_PACKAGES[@]}"; do
    installPackage "sudo apt install -y" "${PACKAGE}" "${APT_LIST_PACKAGES}"
  done

  # [manually] Installing packages
  LOCAL_LIST_PACKAGES=$(ls /usr/local/bin)

  if ! echo "${APT_LIST_PACKAGES}" | grep -w -q "batcat"; then
    sudo apt install -y bat
    sudo ln -s "$(which batcat)" /usr/local/bin/bat
    echo "✅ bat was successfully installed"
  else
    echo "✅ bat is already installed"
  fi

  if ! echo "${LOCAL_LIST_PACKAGES}" | grep -w -q "btop"; then
    wget -qO btop.tbz https://github.com/aristocratos/btop/releases/latest/download/btop-x86_64-linux-musl.tbz
    sudo tar xf btop.tbz --strip-components=2 -C /usr/local ./btop/bin/btop
    rm btop.tbz
    echo "✅ btop was successfully installed"
  else
    echo "✅ btop is already installed"
  fi

  if ! echo "${APT_LIST_PACKAGES}" | grep -w -q "fdfind"; then
    sudo apt install -y fd-find
    sudo ln -s "$(which fdfind)" /usr/local/bin/fd
    echo "✅ fd was successfully installed"
  else
    echo "✅ fd is already installed"
  fi

  if ! echo "${LOCAL_LIST_PACKAGES}" | grep -q "fzf"; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/junegunn/fzf/refs/heads/master/install)" \
      --bin \
      --key-bindings \
      --completion \
      --no-update-rc \
      --no-bash \
      --no-zsh \
      --no-fish \
      && sudo mv ./bin/fzf /usr/local/bin/fzf || true \
      && rm -rf ./bin
    echo "✅ fzf was successfully installed"
  else
    echo "✅ fzf is already installed"
  fi

elif [[ "$OSTYPE" == "darwin"* ]]; then
  # Install brew if not installed
  command -v brew >/dev/null 2>&1 || {
    echo >&2 "Installing Homebrew Now"; \
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)";
  }
  INSTALL_CMD="brew install"
  LIST_PACKAGES=$(brew list)

  # Installing packages
  PACKAGES=(
    "bat"
    "btop"
    "curl"
    "exa"
    "fd"
    "fzf"
    "git"
    "go-task"
    "httpie"
    "jq"
    "stow"
    "yq"
    "zoxide"
  )
  for PACKAGE in "${PACKAGES[@]}"; do
    installPackage "${INSTALL_CMD}" "${PACKAGE}" "${LIST_PACKAGES}"
  done
else
  # Unknown.
  echo "OS not supported"
  exit 1
fi

echo "📝 Configuring git..."
git config --global user.name "Álvaro Paiva"
git config --global user.email alvarofepipa@gmail.com

echo "🎆 Done"
