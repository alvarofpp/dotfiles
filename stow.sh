#!/bin/bash
# stow.sh — symlinka os pacotes do dotfiles para seus targets.
#
# Detecta WSL2 antes de stowar `etc/` e `windows/` (que só fazem sentido lá).
# Suporta --dry-run pra revisar mudanças sem aplicar.
#
# Usage:
#   ./stow.sh             # aplica tudo
#   ./stow.sh --dry-run   # mostra o que seria feito, sem aplicar
#   ./stow.sh -n          # alias de --dry-run

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
STOW="$(command -v stow || true)"

if [ -z "$STOW" ]; then
  echo "❌ stow não encontrado no PATH." >&2
  echo "   Instale via 'brew install stow' (ou rode ./setup.sh primeiro)." >&2
  exit 1
fi

# Parse flags
DRY=0
for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY=1 ;;
    --help|-h)
      sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "❌ Flag desconhecida: $arg" >&2
      echo "   Veja: ./stow.sh --help" >&2
      exit 1
      ;;
  esac
done

STOW_FLAGS=()
if [ "$DRY" -eq 1 ]; then
  STOW_FLAGS+=(-nv)
  echo "🔍 Modo dry-run — nada será aplicado."
  echo ""
fi

is_wsl2() {
  # WSL_DISTRO_NAME setado em WSL; kernel string contém "microsoft".
  [ -n "${WSL_DISTRO_NAME:-}" ] || /usr/bin/grep -qi microsoft /proc/version 2>/dev/null
}

run_stow_user() {
  local pkg="$1" target="$2"
  echo "📦 stow $pkg → $target"
  "$STOW" "${STOW_FLAGS[@]}" -d "$DOTFILES_DIR" -t "$target" "$pkg"
}

run_stow_sudo() {
  local pkg="$1" target="$2"
  echo "📦 sudo stow $pkg → $target"
  sudo "$STOW" "${STOW_FLAGS[@]}" -d "$DOTFILES_DIR" -t "$target" "$pkg"
}

# Sempre: home (shell tooling) + ai (submodule)
run_stow_user home "$HOME"
run_stow_user ai "$HOME"

# Só WSL2: etc + windows
if is_wsl2; then
  run_stow_sudo etc /etc
  if [ -d /mnt/c/Users/alvar ]; then
    run_stow_sudo windows /mnt/c/Users/alvar
  else
    echo "⚠️  /mnt/c/Users/alvar não existe — pulando pacote windows."
  fi
else
  echo "ℹ️  Não é WSL2 — pulando pacotes etc/ e windows/."
fi

if [ "$DRY" -eq 1 ]; then
  echo ""
  echo "🔍 Dry-run concluído. Rode sem --dry-run pra aplicar."
else
  echo ""
  echo "✅ Stow concluído."
fi
