#!/usr/bin/env bash
# Checa o jq que o `gh:dispatch-prep` usa pra achar filha órfã de uma mãe
# container (dotfiles-ai#134): aberta e fora do board, ou em Backlog/sem Status.
# Filha assim nunca é despachada e a mãe espera por ela pra sempre. O jq é
# EXTRAÍDO do GitHub.yml, não copiado: cópia que envelhece testa o passado.
#
# O erro caro é o contrário: curar filha que já andou (In Review, Blocked) a
# devolveria pra In Progress e abriria sessão em cima de trabalho pronto.
set -uo pipefail

yml="$(dirname "$0")/../GitHub.yml"
linha=$(grep -m1 -E '^[[:space:]]*fq=' "$yml") || { echo "não achei o fq= no gh:dispatch-prep"; exit 1; }
eval "$linha"

tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
falhas=0
# $1 nome  $2 estado  $3 linhas do snapshot (JSON Lines)  $4 esperado  $5 labels (csv)
caso() {
  local obtido
  printf '%s\n' "$3" > "$tmp"
  obtido=$(jq -cn --arg s "$2" --arg l "${5:-}" \
      '{state:$s, labels:($l | if . == "" then [] else split(",") end | map({name:.}))}' \
    | jq -r --slurpfile b "$tmp" --arg r o/app --arg n 7 "$fq")
  if [ "$obtido" = "$4" ]; then
    printf 'ok\t%-34s %s\n' "$1" "${obtido:-<vazio>}"
  else
    printf 'FALHA\t%-34s esperado=%s obtido=%s\n' "$1" "${4:-<vazio>}" "${obtido:-<vazio>}"; falhas=$((falhas + 1))
  fi
}

# item do snapshot: id, repo, número, status (json)
item() { printf '{"id":"%s","content":{"number":%s,"repository":{"nameWithOwner":"%s"}},"status":%s}' "$1" "$3" "$2" "$4"; }
outro=$(item X o/app 8 '{"name":"Backlog"}')

caso "fora do board"               OPEN   "$outro"                                          "- - In Progress"
caso "mesmo número, outro repo"    OPEN   "$(item Y o/api 7 '{"name":"Backlog"}')"          "- - In Progress"
caso "em Backlog"                  OPEN   "$outro
$(item I1 o/app 7 '{"name":"Backlog"}')"                                                     "I1 Backlog In Progress"
caso "no board sem Status"         OPEN   "$(item I2 o/app 7 null)"                         "I2 - In Progress"
caso "já em In Progress"           OPEN   "$(item I3 o/app 7 '{"name":"In Progress"}')"     ""
caso "In Review não volta"         OPEN   "$(item I4 o/app 7 '{"name":"In Review"}')"       ""
caso "Blocked não volta"           OPEN   "$(item I5 o/app 7 '{"name":"Blocked"}')"         ""
caso "esperando você vai pra Blocked" OPEN "$outro"                                         "- - Blocked" "agent,agent:human"
caso "fechada fora do board"       CLOSED "$outro"                                          ""

echo "orphan-child: $([ "$falhas" = 0 ] && echo ok || echo "$falhas falha(s)")"
exit "$falhas"
