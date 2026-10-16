#!/usr/bin/env bash
# Checa o que o `gh:reap` pula: ref com sessão viva da rendeira (`LIVE_FILE`).
# A sessão dela não tem terminal no Orca, então sem este pulo o reap tiraria o
# `agent:running` de agente vivo e o tick seguinte empilharia outro na worktree.
#
# A linha de decisão é EXTRAÍDA do GitHub.yml, não copiada: cópia que envelhece
# testa o passado. O `gh:reap` inteiro depende do Orca e do Docker (`agents-ready`),
# então roda-se só o trecho que decide.
set -uo pipefail

yml="$(dirname "$0")/../GitHub.yml"
linha=$(grep -m1 -E '^[[:space:]]*if grep -qxF "\$repo#\$num" "\{\{\.LIVE_FILE\}\}"' "$yml") \
  || { echo "não achei o pulo do LIVE_FILE no gh:reap"; exit 1; }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
falhas=0
# $1 nome  $2 repo  $3 conteúdo do arquivo ("-" = arquivo ausente)  $4 esperado (números que seguem pro agents-busy)
caso() {
  local arq="$tmp/live" obtido="" st num
  if [ "$3" = "-" ]; then rm -f "$arq"; else printf '%b' "$3" > "$arq"; fi
  local corpo=${linha//\{\{.LIVE_FILE\}\}/$arq}
  for num in 5 50 7; do
    repo="$2"
    # shellcheck disable=SC2034
    seguiu=1
    eval "$(printf '%s' "$corpo" | sed 's/then continue; fi/then seguiu=0; fi/')"
    [ "$seguiu" = 1 ] && obtido="$obtido$num,"
  done
  obtido=${obtido%,}
  if [ "$obtido" = "$4" ]; then st=ok; else st=FALHOU; falhas=$((falhas + 1)); fi
  printf '%-7s %-46s esperado=%-8s obtido=%s\n' "$st" "$1" "${4:-<vazio>}" "${obtido:-<vazio>}"
}

caso "ref viva é pulada" "o/r" "o/r#5\n" "50,7"
caso "#50 não é #5 (linha inteira)" "o/r" "o/r#50\n" "5,7"
caso "mesmo número em outro repo não é pulado" "o/r" "o/outro#5\n" "5,50,7"
caso "arquivo ausente não pula nada" "o/r" "-" "5,50,7"
caso "arquivo vazio não pula nada" "o/r" "" "5,50,7"
caso "várias refs vivas" "o/r" "o/r#5\no/r#7\n" "50"

echo "reap-live: $([ "$falhas" = 0 ] && echo ok || echo "$falhas falha(s)")"
exit "$falhas"
