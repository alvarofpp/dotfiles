#!/usr/bin/env bash
# Checa o `cc:prune-sessions` matando processo preso a worktree apagada
# (dotfiles-ai#114). Roda a task de verdade, com HOME falso: sem `.claude`
# nele, os laços de sessão e transcript não encontram nada real pra apagar.
#
# O erro caro é o oposto do que a task conserta: matar processo de worktree
# que ainda existe, ou de pasta apagada fora de `~/orca/workspaces/`. Os
# dois casos que ficam de pé estão aqui por isso.
set -uo pipefail

yml="$(dirname "$0")/../ClaudeCode.yml"
[ -f "$yml" ] || { echo "não achei $yml"; exit 1; }

casa=$(mktemp -d); fora=$(mktemp -d); pids=()
trap 'kill "${pids[@]}" 2>/dev/null; rm -rf "$casa" "$fora"' EXIT

ws="$casa/orca/workspaces/repo"
mkdir -p "$ws/issue-1" "$ws/issue-2" "$ws/.orca-worktree-trash/wt-9" "$fora/x"

# $1 pasta de trabalho do processo falso; o pid sai em $ultimo
nasce() { (cd "$1" && exec sleep 300) & ultimo=$!; pids+=("$ultimo"); }
nasce "$ws/issue-1";                    apagada=$ultimo
nasce "$ws/issue-2";                    viva=$ultimo
nasce "$ws/.orca-worktree-trash/wt-9";  lixeira=$ultimo
nasce "$fora/x";                        alheia=$ultimo
sleep 0.3
rm -rf "$ws/issue-1" "$fora/x"

vivo() { [ -d "/proc/$1" ] && ! grep -q '^State:[[:space:]]*Z' "/proc/$1/status" 2>/dev/null; }
falhas=0
# $1 nome  $2 pid  $3 esperado (vivo|morto)
confere() {
  local obtido=morto
  vivo "$2" && obtido=vivo
  if [ "$obtido" = "$3" ]; then
    printf 'ok\t%-42s esperado=%s obtido=%s\n' "$1" "$3" "$obtido"
  else
    printf 'FALHA\t%-42s esperado=%s obtido=%s\n' "$1" "$3" "$obtido"; falhas=$((falhas + 1))
  fi
}

HOME="$casa" task -t "$yml" prune-sessions DRY=1 >/dev/null 2>&1
sleep 0.3
confere "DRY lista mas não mata" "$apagada" vivo

HOME="$casa" task -t "$yml" prune-sessions >/dev/null 2>&1
for _ in $(seq 20); do vivo "$apagada" || vivo "$lixeira" || break; sleep 0.1; done
confere "cwd apagado em workspaces morre" "$apagada" morto
confere "cwd na lixeira do Orca morre" "$lixeira" morto
confere "worktree que existe fica" "$viva" vivo
confere "cwd apagado fora de workspaces fica" "$alheia" vivo

echo "prune-orphan: $([ "$falhas" = 0 ] && echo ok || echo "$falhas falha(s)")"
exit "$falhas"
