#!/usr/bin/env bash
# Checa a designação de modelos do `gh:models`: rodízio balanceado e as regras
# por família. O jq é EXTRAÍDO do GitHub.yml, não copiado: cópia que envelhece
# testa o passado.
#
# Os erros caros: o crítico sair da família de quem planejou (a crítica vira
# eco do plano), e um revisor sair da família de quem implementou — os dois
# passam calados, com a issue andando normalmente.
set -uo pipefail

yml="$(dirname "$0")/../GitHub.yml"
JQM=$(awk -v q="'" '
  !dentro && $0 ~ ("^[[:space:]]*JQM=" q) { dentro = 1; sub("^[[:space:]]*JQM=" q, "") }
  dentro {
    if (substr($0, length($0)) == q) { print substr($0, 1, length($0) - 1); exit }
    print
  }' "$yml")
[ -n "$JQM" ] || { echo "não consegui extrair o JQM do GitHub.yml"; exit 1; }

todos='["opus","haiku","minimax-m3","deepseek-v4-pro","deepseek-v4-flash","glm-5.3","glm-5.3-flash","kimi-k3"]'
falhas=0
# O desempate é hash de (etapa, issue, modelo), então o número da issue entra na
# conta: `NUM` fixo aqui pra o caso ser reproduzível. Sem ele o JQM extraído nem
# compila — foi assim que este arquivo ficou vermelho em c4a4456.
# $1 nome  $2 modelos com chave  $3 histórico  $4 já planejada  $5 esperado: plano crítica execução julgamento conferência
caso() {
  local obtido
  obtido=$(jq -nc --argjson disp "$2" --argjson hist "$3" --argjson planejado "$4" \
      --argjson num "${NUM:-7}" "$JQM" \
    | jq -r '"\(.plano) \(.critica) \(.execucao) \(.julgamento) \(.conferencia)"')
  if [ "$obtido" = "$5" ]; then printf 'ok\t%-40s %s\n' "$1" "$obtido"
  else printf 'FALHA\t%-40s esperado=%s obtido=%s\n' "$1" "$5" "$obtido"; falhas=$((falhas + 1)); fi
}

# Sem histórico é empate em tudo, então este caso mede o desempate por hash —
# o que ele protege é a regra de família sobreviver a ele, não a escolha em si.
caso "tudo com chave, sem histórico" "$todos" '[]' false \
  "deepseek-v4-pro glm-5.3 glm-5.3-flash opus deepseek-v4-flash"
caso "rodízio: o menos designado" "$todos" \
  '[{"plano":"opus","critica":"deepseek-v4-pro","execucao":"minimax-m3","julgamento":"opus","conferencia":"deepseek-v4-flash"}]' false \
  "deepseek-v4-pro glm-5.3 glm-5.3-flash deepseek-v4-pro minimax-m3"
caso "crítica fora da família do plano" "$todos" \
  '[{"plano":"opus","critica":"opus"},{"plano":"deepseek-v4-pro","critica":"deepseek-v4-pro"}]' false \
  "glm-5.3 kimi-k3 glm-5.3-flash opus deepseek-v4-flash"
# glm-5.3 é o menos usado no julgamento, mas é da família de quem implementa.
caso "revisão fora da família da execução" '["opus","haiku","glm-5.3","glm-5.3-flash","kimi-k3"]' \
  '[{"julgamento":"opus"},{"julgamento":"opus"},{"julgamento":"kimi-k3"},{"julgamento":"kimi-k3"}]' false \
  "glm-5.3 opus glm-5.3-flash opus haiku"
caso "só Opus e M3 com chave: fallbacks" '["opus","haiku","minimax-m3"]' '[]' false \
  "opus minimax-m3 minimax-m3 opus haiku"
caso "issue já planejada" "$todos" '[]' true \
  "null null glm-5.3-flash opus deepseek-v4-flash"

echo "model-assignment: $([ "$falhas" = 0 ] && echo ok || echo "$falhas falha(s)")"
exit "$falhas"
