#!/usr/bin/env bash
# Checa como o `gh:dispatch` lê o PR da issue (dotfiles-ai#115): o número e se
# ele ainda tem `agent:changes`. É isso que decide entre abrir sessão e só
# mover o card pra In Review. O jq é EXTRAÍDO do GitHub.yml, não copiado:
# cópia que envelhece testa o passado.
#
# O erro caro é o `nao` falso: PR que ainda pede mudança lido como já
# aplicado vai pra revisão sem ninguém ter corrigido. Por isso o caso da
# label na posição 0, onde `index` devolve 0 e um teste de verdade falharia.
set -uo pipefail

yml="$(dirname "$0")/../GitHub.yml"
linha=$(grep -m1 -E '^[[:space:]]*prq=' "$yml") || { echo "não achei o prq= no gh:dispatch"; exit 1; }
eval "$linha"

falhas=0
# $1 nome  $2 json do `gh pr list`  $3 número da issue  $4 esperado
caso() {
  local obtido
  obtido=$(printf '%s' "$2" | jq -r --arg n "$3" "$prq" | head -1)
  if [ "$obtido" = "$4" ]; then
    printf 'ok\t%-38s %s\n' "$1" "${obtido:-<vazio>}"
  else
    printf 'FALHA\t%-38s esperado=%s obtido=%s\n' "$1" "${4:-<vazio>}" "${obtido:-<vazio>}"; falhas=$((falhas + 1))
  fi
}

caso "PR pedindo mudança"          '[{"number":247,"body":"Refs #154\nx","labels":[{"name":"agent"},{"name":"agent:changes"}]}]' 154 "247 sim"
caso "PR já sem agent:changes"     '[{"number":247,"body":"Refs #154","labels":[{"name":"agent"}]}]'                            154 "247 nao"
caso "agent:changes na posição 0"  '[{"number":9,"body":"refs #1","labels":[{"name":"agent:changes"}]}]'                        1   "9 sim"
caso "PR de outra issue (#1540)"   '[{"number":8,"body":"Refs #1540","labels":[]}]'                                              154 ""
caso "sem PR"                      '[]'                                                                                          154 ""

echo "dispatch-changes: $([ "$falhas" = 0 ] && echo ok || echo "$falhas falha(s)")"
exit "$falhas"
