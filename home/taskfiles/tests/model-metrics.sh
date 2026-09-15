#!/usr/bin/env bash
# Checa a conta de modelo por etapa das métricas: o consumo que o
# `gh:sessions` tira do transcript e a etapa que o `gh:metrics` atribui a cada
# sessão. Os programas jq são EXTRAÍDOS do GitHub.yml, não copiados: cópia que
# envelhece testa o passado.
#
# Os erros caros: contar duas vezes a mesma resposta (o transcript repete o
# `usage` por bloco), e jogar a sessão de execução na etapa de plano — a
# comparação entre modelos sairia invertida sem erro nenhum.
set -uo pipefail

yml="$(dirname "$0")/../GitHub.yml"
extrai() {
  awk -v v="$1" -v q="'" '
    !dentro && $0 ~ ("^[[:space:]]*" v "=" q) { dentro = 1; sub("^[[:space:]]*" v "=" q, "") }
    dentro {
      if (substr($0, length($0)) == q) { print substr($0, 1, length($0) - 1); exit }
      print
    }' "$yml"
}
JQS=$(extrai JQS); JQE=$(extrai JQE)
[ -n "$JQS" ] && [ -n "$JQE" ] || { echo "não consegui extrair JQS/JQE do GitHub.yml"; exit 1; }

falhas=0
confere() { # nome, esperado, obtido
  if [ "$2" = "$3" ]; then printf 'ok\t%-44s %s\n' "$1" "$3"
  else printf 'FALHA\t%-44s esperado=%s obtido=%s\n' "$1" "$2" "$3"; falhas=$((falhas + 1)); fi
}

u() { printf '{"timestamp":"%s","message":{"id":"%s","model":"%s","usage":{"input_tokens":%s,"output_tokens":%s,"cache_read_input_tokens":%s,"cache_creation_input_tokens":0}}}' "$@"; }
transcript=$(printf '%s\n' \
  '{"timestamp":"2026-09-15T00:00:01.900Z","type":"user"}' \
  "$(u 2026-09-15T00:00:03.000Z m1 MiniMax-M3 100 10 5)" \
  "$(u 2026-09-15T00:00:03.100Z m1 MiniMax-M3 100 10 5)" \
  "$(u 2026-09-15T00:00:04.000Z m2 MiniMax-M3 50 20 0)" \
  "$(u 2026-09-15T00:00:05.000Z s1 '<synthetic>' 0 0 0)" \
  "$(u 2026-09-15T00:09:59.500Z a1 claude-opus-5 7 3 1)")
sessao=$(printf '%s' "$transcript" | jq -cs --arg nome app --arg n 7 --arg s S1 "$JQS")
confere "M3: resposta repetida conta uma vez"      "2 150 30 5" "$(jq -r '.modelos["MiniMax-M3"] | "\(.msgs) \(.entrada) \(.saida) \(.cache_leitura)"' <<< "$sessao")"
confere "subagente entra na sessão, synthetic não" "MiniMax-M3,claude-opus-5" "$(jq -r '.modelos | keys | join(",")' <<< "$sessao")"
confere "horário sem milissegundo"                 "2026-09-15T00:00:01Z 2026-09-15T00:09:59Z" "$(jq -r '"\(.inicio) \(.fim)"' <<< "$sessao")"

runs=$(mktemp); sess=$(mktemp); trap 'rm -f "$runs" "$sess"' EXIT
printf '%s\n' \
  '{"repo":"o/app","issue":7,"etapa":"plano","runner":"claude","em":"2026-09-15T00:00:30Z"}' \
  '{"repo":"o/app","issue":7,"etapa":"execucao","runner":"claude-mini","em":"2026-09-15T01:00:00Z"}' \
  '{"repo":"o/outro","issue":7,"etapa":"revisao","runner":"claude","em":"2026-09-15T01:30:00Z"}' > "$runs"
s() { printf '{"repo_nome":"%s","issue":7,"sessao":"%s","inicio":"%s","modelos":{"%s":{"msgs":1,"entrada":10,"saida":%s,"cache_leitura":0,"cache_escrita":0}}}\n' "$@"; }
{ s app p1 2026-09-15T00:00:10Z claude-opus-5 1   # antes do `em`, dentro da folga
  s app e1 2026-09-15T01:00:05Z MiniMax-M3 2
  s app e2 2026-09-15T02:00:00Z MiniMax-M3 4      # retomada, depois de tudo
  s outro r1 2026-09-15T01:30:05Z claude-opus-5 8; } > "$sess"
issue=$(jq -cn '{repo: "o/app", issue: 7}' | jq -c --arg nome app --slurpfile runs "$runs" --slurpfile sess "$sess" "$JQE")
confere "etapas na ordem, repo alheio fora"        "plano:claude execucao:claude-mini" "$(jq -r '[.etapas[] | "\(.etapa):\(.runner)"] | join(" ")' <<< "$issue")"
confere "sessão na folga cai no plano"             "1 claude-opus-5" "$(jq -r '.etapas[0] | "\(.sessoes) \(.modelos | keys | join(","))"' <<< "$issue")"
confere "execução soma as duas sessões"            "2 6" "$(jq -r '.etapas[1] | "\(.sessoes) \(.modelos["MiniMax-M3"].saida)"' <<< "$issue")"
confere "issue sem etapa sai com lista vazia"      "[]" "$(jq -cn '{repo: "o/x", issue: 1}' | jq -c --arg nome x --slurpfile runs "$runs" --slurpfile sess "$sess" "$JQE" | jq -c .etapas)"

echo "model-metrics: $([ "$falhas" = 0 ] && echo ok || echo "$falhas falha(s)")"
exit "$falhas"
