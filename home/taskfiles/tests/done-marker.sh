#!/usr/bin/env bash
# Checa o marcador de fim de tarefa: o hook Stop
# (`ai/.claude/hooks/orca-task-done.sh`) escreve, o `gh:agents-busy` lê.
#
# O erro que este teste existe pra pegar não dá erro nenhum: se as duas
# derivações da chave divergirem, o hook escreve num arquivo que ninguém lê e o
# sintoma é "nada mudou" — o fluxo volta a esperar 30 min por tarefa sem nunca
# reclamar. Por isso o teste roda o hook DE VERDADE e extrai a leitura do
# próprio GitHub.yml, e compara os dois lados.
set -uo pipefail

raiz="$(cd "$(dirname "$0")/../../.." && pwd)"
yml="$raiz/home/taskfiles/GitHub.yml"
hook="$raiz/ai/.claude/hooks/orca-task-done.sh"
[ -f "$yml" ]  || { echo "não achei $yml"; exit 1; }
[ -x "$hook" ] || { echo "não achei (ou não é executável) $hook"; exit 1; }

# A leitura do lado da task: do `wt=` até o `esac` do case EXTERNO — o de 8
# espaços, que é a indentação do bloco `cmds:`. Parar no primeiro `esac` pegaria
# o do `case "$nome"` aninhado e entregaria um `case` sem fim.
leitura=$(awk '
  /^ *wt="\{\{\.WT\}\}"$/ { dentro = 1 }
  dentro { print; if ($0 ~ /^        esac$/) exit }' "$yml")
# `{{.WT}}` vira a variável do teste; o resto do trecho roda como está.
leitura=${leitura//\{\{.WT\}\}/\$WT_TESTE}
[ -n "$leitura" ] || { echo "não consegui extrair a leitura do gh:agents-busy"; exit 1; }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
falhas=0

# $1 nome  $2 caminho da worktree  $3 chave esperada ("-" = nenhum marcador)
caso() {
  local nome="$1" wtpath="$2" esperado="$3" escrito lido st
  rm -rf "$tmp/state"; mkdir -p "$tmp/state"

  # --- lado do hook: roda o script como o Claude Code roda
  printf '{"cwd":"%s","hook_event_name":"Stop"}' "$wtpath" \
    | XDG_STATE_HOME="$tmp/state" HOME="$HOME" "$hook" >/dev/null 2>&1
  escrito=$(ls -1 "$tmp/state/gh-board/done" 2>/dev/null | head -1)
  [ -n "$escrito" ] || escrito="-"

  # --- lado da task: o mesmo trecho que roda no gh:agents-busy
  lido=$(
    XDG_STATE_HOME="$tmp/state" \
    WT_TESTE="path:$wtpath" \
    bash -c "$leitura"'
            printf "%s" "${marcador##*/}"'
  )
  [ -n "$lido" ] || lido="-"

  if [ "$escrito" = "$esperado" ] && [ "$lido" = "$esperado" ]; then
    st=ok
  else
    st=FALHOU; falhas=$((falhas + 1))
  fi
  printf '%-7s %-40s esperado=%-18s hook=%-18s task=%s\n' \
    "$st" "$nome" "$esperado" "$escrito" "$lido"
}

caso "worktree de issue"      "$HOME/orca/workspaces/matria/issue-7"        "matria_issue-7"
caso "worktree de revisão"    "$HOME/orca/workspaces/lucida-monorepo/pr-33" "lucida-monorepo_pr-33"
caso "número de dois dígitos" "$HOME/orca/workspaces/abacaxei-app/issue-114" "abacaxei-app_issue-114"
# --- o que NÃO pode ganhar marcador
caso "árvore principal do repo" "$HOME/alvarofpp/matria"                     "-"
caso "worktree fora do fluxo"   "$HOME/orca/workspaces/matria/feat-x"        "-"
caso "raiz dos workspaces"      "$HOME/orca/workspaces"                      "-"

# Seletor que não é `path:` não pode explodir nem inventar marcador — o
# `issue:<n>` do Orca ainda aparece em chamada à mão.
lido=$(XDG_STATE_HOME="$tmp/state" WT_TESTE="issue:7" \
  bash -c "$leitura"'
          printf "%s" "${marcador:--}"' 2>&1)
if [ "$lido" = "-" ]; then
  printf '%-7s %-40s esperado=%-18s %s\n' ok "seletor issue:<n> não vira marcador" "-" "task=-"
else
  printf '%-7s %-40s esperado=%-18s task=%s\n' FALHOU "seletor issue:<n> não vira marcador" "-" "$lido"
  falhas=$((falhas + 1))
fi

# --- quem APAGA o marcador ao despachar. Dois pontos o fazem (`gh:orca` pra
# `issue-<n>`, `gh:review-requested` pra `pr-<n>`), e um erro de digitação ali
# não dá erro: o marcador velho fica, e o tick seguinte fecha um agente que mal
# começou. As linhas são extraídas e AVALIADAS, não conferidas por texto.
while IFS= read -r linha; do
  chave=$(repo="lucida-ia/lucida-monorepo" num=7 pr=33           XDG_STATE_HOME="$tmp/state" bash -c "
            ${linha/rm -f /printf '%s' }" 2>/dev/null)
  chave=${chave##*/}
  case "$chave" in
    lucida-monorepo_issue-7|lucida-monorepo_pr-33) st=ok ;;
    *) st=FALHOU; falhas=$((falhas + 1)) ;;
  esac
  printf '%-7s %-40s %s\n' "$st" "limpeza ao despachar" "$chave"
done < <(grep -oE 'rm -f "\$\{XDG_STATE_HOME[^"]*"' "$yml")

[ "$falhas" -eq 0 ] && echo "done-marker: ok" || echo "done-marker: $falhas falha(s)"
exit "$falhas"
