#!/usr/bin/env bash
# Checa a contagem de rodadas do `gh:pr-tick` — quantas reviews valem como
# passada de revisor.
#
# O programa jq é EXTRAÍDO do GitHub.yml, não copiado. O caso que justifica o
# teste: a correção responde cada achado com uma review `agent:author`, e
# contá-las fez o lucida-monorepo#179 bater "9 rodadas" com duas revisões de
# verdade — teto estourado e `agent:human` num PR que só esperava conferência.
set -uo pipefail

yml="$(dirname "$0")/../GitHub.yml"
[ -f "$yml" ] || { echo "não achei $yml"; exit 1; }

programa=$(awk '
  /rounds=\$\(gh pr view "\$pr" -R "\$repo" --json reviews/ { achou = 1; next }
  achou && /--jq/ { sub(/.*--jq '"'"'/, ""); sub(/'"'"'\)$/, ""); print; exit }' "$yml")
[ -n "$programa" ] || { echo "não consegui extrair o jq do GitHub.yml"; exit 1; }

rev='{"body":"<!-- agent:review -->\n**Revisão** — pedido de mudança"}'
autor='{"body":"<!-- agent:author -->\n**Implementação** — aplicado"}'
humano='{"body":"**Revisão**: falta ajustar o motivo"}'
vazia='{"body":""}'

falhas=0
caso() { # nome, esperado, reviews
  local obtido st
  obtido=$(printf '{"reviews":%s}' "$3" | jq -r "$programa" 2>/dev/null)
  if [ "$obtido" = "$2" ]; then st=ok; else st=FALHOU; falhas=$((falhas + 1)); fi
  printf '%-7s %-44s esperado=%-3s obtido=%s\n' "$st" "$1" "$2" "$obtido"
}

caso "sem review" "0" '[]'
caso "review de corpo vazio nao e rodada" "0" "[$vazia,$vazia]"
caso "resposta do autor nao e rodada" "1" "[$rev,$autor,$autor,$autor]"
caso "revisao humana conta" "2" "[$rev,$autor,$humano]"

echo "--- falhas: $falhas"
exit $((falhas > 0))
