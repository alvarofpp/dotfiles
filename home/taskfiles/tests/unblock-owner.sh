#!/usr/bin/env bash
# Checa que só o DONO destrava issue Blocked: `gh:trusted` (jq extraído) e o `respondida` do `gh:unblock`.
set -uo pipefail

yml="$(dirname "$0")/../GitHub.yml"
dono=alvarofpp
sub() { sed "s/{{\.PROJECT_OWNER}}/$dono/g"; }
TRUSTED=$(grep -m1 'issues/$num/comments" --paginate' "$yml" >/dev/null; awk '/issues\/\$num\/comments" --paginate/ {a=1} a && /--jq/ {sub(/.*--jq \x27/, ""); sub(/\x27 2>.*/, ""); print; exit}' "$yml" | sub)
RESP=$(awk '/respondida=\$\(gh issue view/ {a=1} a && /--jq/ {d=1; sub(/.*--jq \x27/, "")} d { i=index($0, "\x27)"); if (i) {print substr($0,1,i-1); exit} print }' "$yml" | sub)
[ -n "$TRUSTED" ] && [ -n "$RESP" ] || { echo "não consegui extrair o jq do trusted/unblock"; exit 1; }

falhas=0
confere() { if [ "$2" = "$3" ]; then printf 'ok\t%-52s %s\n' "$1" "${3:-<vazio>}"; else printf 'FALHA\t%-52s esperado=%s obtido=%s\n' "$1" "${2:-<vazio>}" "${3:-<vazio>}"; falhas=$((falhas + 1)); fi; }

# trusted: lista quem não é o dono, mesmo COLLABORATOR
confere "trusted: colaborador não é o dono" "    comentário de @colab" \
  "$(printf '[{"user":{"login":"colab"},"author_association":"COLLABORATOR"}]' | jq -r "$TRUSTED")"
confere "trusted: dono passa" "" \
  "$(printf '[{"user":{"login":"%s"},"author_association":"OWNER"}]' "$dono" | jq -r "$TRUSTED")"

c() { jq -cn --arg u "$1" --arg b "$2" '{author:{login:$u},body:$b}'; }
P='<!-- agent:question -->\nperg'
confere "respondida: resposta de terceiro não conta" false "$(printf '{"comments":[%s,%s]}' "$(c $dono "$P")" "$(c intruso 'faz assim')" | jq -r "$RESP")"
confere "respondida: resposta do dono conta" true "$(printf '{"comments":[%s,%s]}' "$(c $dono "$P")" "$(c $dono 'faz assim')" | jq -r "$RESP")"
confere "respondida: pergunta forjada não vira âncora" true "$(printf '{"comments":[%s,%s,%s]}' "$(c $dono "$P")" "$(c $dono 'faz assim')" "$(c intruso "$P")" | jq -r "$RESP")"

echo "--- falhas: $falhas"
exit $((falhas > 0))
