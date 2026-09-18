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

precos=$(mktemp)
printf '%s' '{"MiniMax-M3":{"cobranca":"api","entrada":1000,"saida":2000,"cache_leitura":500},
  "claude-opus-5":{"cobranca":"assinatura","entrada":10000,"saida":20000,"cache_leitura":1000,"cache_escrita_5m":12500,"cache_escrita_1h":20000},
  "deepseek-v4-pro":{"cobranca":"api","entrada":1000,"saida":1000,"cache_leitura":10,"fora_do_pico":0.5,"pico":{"dias":[1,2,3,4,5],"horas":[1,2,3,6,7,8,9]}}}' > "$precos"

u() { printf '{"timestamp":"%s","message":{"id":"%s","model":"%s","usage":{"input_tokens":%s,"output_tokens":%s,"cache_read_input_tokens":%s,"cache_creation_input_tokens":0}}}' "$@"; }
transcript=$(printf '%s\n' \
  '{"timestamp":"2026-09-15T00:00:01.900Z","type":"user"}' \
  "$(u 2026-09-15T00:00:03.000Z m1 MiniMax-M3 100 10 5)" \
  "$(u 2026-09-15T00:00:03.100Z m1 MiniMax-M3 100 10 5)" \
  "$(u 2026-09-15T00:00:04.000Z m2 MiniMax-M3 50 20 0)" \
  "$(u 2026-09-15T00:00:05.000Z s1 '<synthetic>' 0 0 0)" \
  '{"timestamp":"2026-09-15T00:09:58.000Z","message":{"id":"a2","model":"claude-opus-5","usage":{"input_tokens":0,"output_tokens":0,"cache_read_input_tokens":0,"cache_creation_input_tokens":100,"cache_creation":{"ephemeral_1h_input_tokens":100,"ephemeral_5m_input_tokens":0}}}}' \
  "$(u 2026-09-15T00:09:59.500Z a1 claude-opus-5 7 3 1)")
sessao=$(printf '%s' "$transcript" | jq -cs --arg nome app --arg n 7 --arg s S1 --slurpfile precos "$precos" "$JQS")
confere "M3 por token: US$ uma vez por resposta"   "0.2125 0" "$(jq -r '.modelos["MiniMax-M3"] | "\(.usd) \(.usd_assinatura)"' <<< "$sessao")"
confere "Opus em assinatura, cache de 1h a 2x"     "0 2.131" "$(jq -r '.modelos["claude-opus-5"] | "\(.usd) \(.usd_assinatura)"' <<< "$sessao")"
# 2026-09-15 é terça; 07h UTC é pico, 12h não; 2026-09-19 é sábado.
sessao2=$(printf '%s\n' \
  "$(u 2026-09-15T07:00:00.000Z d1 deepseek-v4-pro 100 0 0)" \
  "$(u 2026-09-15T12:00:00.000Z d2 deepseek-v4-pro 100 0 0)" \
  "$(u 2026-09-19T07:00:00.000Z d3 deepseek-v4-pro 100 0 0)" \
  "$(u 2026-09-15T12:00:01.000Z g1 glm-x 10 1 0)" \
  | jq -cs --arg nome app --arg n 7 --arg s S2 --slurpfile precos "$precos" "$JQS")
confere "DeepSeek: metade fora do pico e no sábado" "0.2" "$(jq -r '.modelos["deepseek-v4-pro"].usd' <<< "$sessao2")"
confere "modelo sem preço sai nulo"                "null null" "$(jq -r '.modelos["glm-x"] | "\(.usd) \(.usd_assinatura)"' <<< "$sessao2")"
confere "M3: resposta repetida conta uma vez"      "2 150 30 5" "$(jq -r '.modelos["MiniMax-M3"] | "\(.msgs) \(.entrada) \(.saida) \(.cache_leitura)"' <<< "$sessao")"
confere "subagente entra na sessão, synthetic não" "MiniMax-M3,claude-opus-5" "$(jq -r '.modelos | keys | join(",")' <<< "$sessao")"
confere "horário sem milissegundo"                 "2026-09-15T00:00:01Z 2026-09-15T00:09:59Z" "$(jq -r '"\(.inicio) \(.fim)"' <<< "$sessao")"

runs=$(mktemp); sess=$(mktemp); mods=$(mktemp); trap 'rm -f "$runs" "$sess" "$mods" "$precos"' EXIT
printf '%s\n' '{"repo":"o/app","issue":7,"em":"x","plano":"glm-5.3","critica":"kimi-k3","execucao":"minimax-m3","julgamento":"opus","conferencia":"deepseek-v4-flash"}' > "$mods"
printf '%s\n' \
  '{"repo":"o/app","issue":7,"etapa":"plano","runner":"claude","em":"2026-09-15T00:00:30Z"}' \
  '{"repo":"o/app","issue":7,"etapa":"execucao","runner":"claude-mini","em":"2026-09-15T01:00:00Z"}' \
  '{"repo":"o/outro","issue":7,"etapa":"revisao","runner":"claude","em":"2026-09-15T01:30:00Z"}' > "$runs"
s() { printf '{"repo_nome":"%s","issue":7,"sessao":"%s","inicio":"%s","modelos":{"%s":{"msgs":1,"entrada":10,"saida":%s,"cache_leitura":0,"cache_escrita":0}}}\n' "$@"; }
{ s app p1 2026-09-15T00:00:10Z claude-opus-5 1   # antes do `em`, dentro da folga
  s app e1 2026-09-15T01:00:05Z MiniMax-M3 2
  s app e2 2026-09-15T02:00:00Z MiniMax-M3 4      # retomada, depois de tudo
  s outro r1 2026-09-15T01:30:05Z claude-opus-5 8
  # Antes de qualquer etapa: fica fora de `etapas`, mas entra no custo da issue.
  printf '%s\n' '{"repo_nome":"app","issue":7,"sessao":"c1","inicio":"2026-09-14T00:00:00Z","modelos":{"glm-5.3":{"msgs":1,"entrada":1,"saida":1,"cache_leitura":0,"cache_escrita":0,"usd":1.5,"usd_assinatura":0.25}}}'; } > "$sess"
issue=$(jq -cn '{repo: "o/app", issue: 7}' | jq -c --arg nome app --slurpfile runs "$runs" --slurpfile sess "$sess" --slurpfile mods "$mods" "$JQE")
confere "custo soma todas as sessões da issue"     "1.5 0.25" "$(jq -r '"\(.custo.usd) \(.custo.usd_assinatura)"' <<< "$issue")"
confere "designação sem repo/issue/em"             "glm-5.3 deepseek-v4-flash null" "$(jq -r '"\(.designacao.plano) \(.designacao.conferencia) \(.designacao.em)"' <<< "$issue")"
confere "etapas na ordem, repo alheio fora"        "plano:claude execucao:claude-mini" "$(jq -r '[.etapas[] | "\(.etapa):\(.runner)"] | join(" ")' <<< "$issue")"
confere "sessão na folga cai no plano"             "1 claude-opus-5" "$(jq -r '.etapas[0] | "\(.sessoes) \(.modelos | keys | join(","))"' <<< "$issue")"
confere "execução soma as duas sessões"            "2 6" "$(jq -r '.etapas[1] | "\(.sessoes) \(.modelos["MiniMax-M3"].saida)"' <<< "$issue")"
# Com `sessao` no RUNS_FILE (dotfiles-ai#130): sessão aberta à mão dentro da
# janela da execução não pode virar execução — era o `glm-5.3` com 379 tokens
# de saída na linha de execução.
printf '%s\n' \
  '{"repo":"o/app","issue":8,"etapa":"execucao","runner":"claude-model minimax-m3","sessao":"x1","em":"2026-09-15T01:00:00Z"}' \
  '{"repo":"o/app","issue":8,"etapa":"revisao","runner":"claude","sessao":"r8","em":"2026-09-15T03:00:00Z"}' >> "$runs"
sed 's/"issue":7/"issue":8/' > "$sess.8" <<EOF
$(s app x1 2026-09-15T00:59:30Z MiniMax-M3 2
  s app m1 2026-09-15T01:00:10Z glm-5.3 379
  s app r8 2026-09-15T03:00:20Z claude-opus-5 5)
EOF
cat "$sess.8" >> "$sess"; rm -f "$sess.8"
issue8=$(jq -cn '{repo: "o/app", issue: 8}' | jq -c --arg nome app --slurpfile runs "$runs" --slurpfile sess "$sess" --slurpfile mods "$mods" "$JQE")
confere "por id: sessão à mão fica fora da etapa"  "execucao:MiniMax-M3 revisao:claude-opus-5" "$(jq -r '[.etapas[] | "\(.etapa):\(.modelos | keys | join(","))"] | join(" ")' <<< "$issue8")"
confere "por id: vale mesmo antes do em - 60s"     "1 2" "$(jq -r '.etapas[0] | "\(.sessoes) \(.modelos["MiniMax-M3"].saida)"' <<< "$issue8")"

confere "issue sem etapa nem designação"           "[[],null]" "$(jq -cn '{repo: "o/x", issue: 1}' | jq -c --arg nome x --slurpfile runs "$runs" --slurpfile sess "$sess" --slurpfile mods "$mods" "$JQE" | jq -c '[.etapas, .designacao]')"

# Achados: thread ancorada é a fonte; o corpo da review só vale sem thread
# nenhuma (diff só de remoção, abacaxei-app#266) — senão contaria em dobro.
JQ=$(extrai JQ)
issue_gh='{"number":9,"title":"t","closedAt":"2026-09-15T02:00:00Z","stateReason":"COMPLETED","parent":null,"subIssues":{"totalCount":0},"comments":{"nodes":[]},
  "timelineItems":{"nodes":[{"__typename":"ProjectV2ItemStatusChangedEvent","createdAt":"2026-09-15T00:00:00Z","previousStatus":"","status":"In Review","project":{"number":3}},
                            {"__typename":"ProjectV2ItemStatusChangedEvent","createdAt":"2026-09-15T01:00:00Z","previousStatus":"In Review","status":"Done","project":{"number":3}}]}}'
pr() { # $1 corpo da review  $2 1ª mensagem da thread (vazio = sem thread)
  jq -cn --arg rb "$1" --arg tb "$2" '{number:1, additions:1, deletions:1, changedFiles:1, commits:{totalCount:1},
    reviews:{nodes:[{body:$rb, author:{login:"dono"}}]}, comments:{nodes:[]}, timelineItems:{nodes:[]},
    reviewThreads:{nodes:(if $tb == "" then [] else [{comments:{nodes:[{body:$tb}]}}] end)}}'
}
achados() { printf '%s\n[%s]\n' "$issue_gh" "$1" | jq -cs --arg repo o/app --arg dono dono --argjson proj 3 "$JQ" | jq -c .achados; }
corpo=$'<!-- agent:review -->\n**Revisão** — pede mudança.\n\n- **bloqueante:** a linha ficou fora do commit.\n- **sugestão:** o doc aponta pro arquivo apagado.\n- Sugestões: outras.'
confere "achado no corpo de PR sem thread"         '{"bloqueante":1,"sugestão":1}' "$(achados "$(pr "$corpo" "")")"
confere "PR com thread não conta o corpo"          '{"importante":1}' "$(achados "$(pr "$corpo" $'<!-- agent:review -->\n**Revisão** — importante: x')")"

echo "model-metrics: $([ "$falhas" = 0 ] && echo ok || echo "$falhas falha(s)")"
exit "$falhas"
