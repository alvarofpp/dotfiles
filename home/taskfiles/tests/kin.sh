#!/usr/bin/env bash
# Checa o programa jq do `gh:kin` — a leitura de parentesco (mãe, sub-issues,
# bloqueio) que o dispatch e o close consomem.
#
# O programa é EXTRAÍDO do GitHub.yml, não copiado: cópia que envelhece testa o
# passado. O caso que justifica o teste é o do `blockedBy`: ele conta só o que
# está OPEN, e uma irmã já fechada não pode segurar a filha — errar aí trava
# uma sub-issue pra sempre, em silêncio.
set -uo pipefail

yml="$(dirname "$0")/../GitHub.yml"
[ -f "$yml" ] || { echo "não achei $yml"; exit 1; }

# Recorta do `--jq '` até a linha que fecha com `' \`.
prog=$(awk '
  /--jq .\.data\.repository\.issue$/ { dentro = 1; sub(/.*--jq '"'"'/, ""); }
  dentro {
    linha = $0
    if (linha ~ /'"'"' \\$/) { sub(/'"'"' \\$/, "", linha); print linha; exit }
    print linha
  }' "$yml")
[ -n "$prog" ] || { echo "não consegui extrair o jq do gh:kin"; exit 1; }

falhas=0
caso() { # nome, esperado, json
  local obtido st
  obtido=$(jq -r "$prog" <<<"$3" 2>&1)
  if [ "$obtido" = "$2" ]; then st=ok; else st=FALHOU; falhas=$((falhas + 1)); fi
  printf '%-7s %-46s esperado=%-16s obtido=%s\n' "$st" "$1" "$2" "$obtido"
}

env() { # parent, total, completed, estados de blockedBy (csv), filhas (csv)
  jq -cn --arg p "$1" --argjson t "$2" --argjson c "$3" --arg b "$4" --arg s "$5" '
    {data:{repository:{issue:{
      parent: (if $p == "-" then null else {number: ($p|tonumber)} end),
      subIssuesSummary: {total:$t, completed:$c},
      blockedBy: {nodes: ($b | if . == "" then [] else split(",") end | map({state:.}))},
      subIssues: {nodes: ($s | if . == "" then [] else split(",") end | map({number:(.|tonumber)}))}
    }}}}'
}

caso "issue solta"                  "- 0 0 0 -"        "$(env - 0 0 ''            '')"
caso "mãe com duas filhas"          "- 2 0 0 11,12"    "$(env - 2 0 ''            '11,12')"
caso "mãe com uma filha concluída"  "- 2 1 0 11,12"    "$(env - 2 1 ''            '11,12')"
caso "filha conhece a mãe"          "7 0 0 0 -"        "$(env 7 0 0 ''            '')"
caso "bloqueada por irmã aberta"    "7 0 0 1 -"        "$(env 7 0 0 'OPEN'        '')"
caso "irmã FECHADA não bloqueia"    "7 0 0 0 -"        "$(env 7 0 0 'CLOSED'      '')"
caso "só as abertas contam"         "7 0 0 2 -"        "$(env 7 0 0 'OPEN,CLOSED,OPEN' '')"

[ "$falhas" -eq 0 ] && echo "kin: ok" || echo "kin: $falhas falha(s)"
exit "$falhas"
