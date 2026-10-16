#!/usr/bin/env bash
# Checa dois furos do tick: `gh:settle` só abre agente pago com evidência do DONO, e `gh:close` (Dropped) só fecha PR do
# fluxo (label `agent` ou do dono) e só apaga branch do próprio repo. Os jq são EXTRAÍDOS do GitHub.yml, não copiados.
set -uo pipefail

yml="$(dirname "$0")/../GitHub.yml"
dono=alvarofpp
sub() { sed "s/{{\.PROJECT_OWNER}}/$dono/g"; }

EVID=$(grep -m1 'select(test("<!-- agent:evidence -->"))\|agent:evidence -->"))\] | length' "$yml" | sed -E "s/.*--jq '//; s/' 2>.*//" | sub)
# close: do `--jq '.[] | select(.body` até a aspa que fecha, dentro do bloco Dropped
CLOSE=$(awk '/gh pr list -R "\$repo" --state open --limit 50 --json number,body,labels,author,isCrossRepository/ {a=1}
  a && /--jq/ {d=1; sub(/.*--jq \x27/, "")}
  d { i=index($0, "\x27 2>/dev/null"); if (i) {print substr($0,1,i-1); exit} print }' "$yml" | sed "s/'\"\$num\"'/7/" | sub)
[ -n "$EVID" ] && [ -n "$CLOSE" ] || { echo "não consegui extrair o jq do settle/close"; exit 1; }

falhas=0
confere() {
  if [ "$2" = "$3" ]; then printf 'ok\t%-50s %s\n' "$1" "${3:-<vazio>}"
  else printf 'FALHA\t%-50s esperado=%s obtido=%s\n' "$1" "${2:-<vazio>}" "${3:-<vazio>}"; falhas=$((falhas + 1)); fi
}

c() { jq -cn --arg u "$1" '{author: {login: $u}, body: "<!-- agent:evidence -->\nx"}'; }
confere "settle: evidência de terceiro não conta" "0" "$(printf '{"comments":[%s]}' "$(c intruso)" | jq -r "$EVID")"
confere "settle: evidência do dono conta" "1" "$(printf '{"comments":[%s]}' "$(c $dono)" | jq -r "$EVID")"

pr() { jq -cn --argjson n "$1" --arg u "$2" --argjson l "$3" --argjson x "$4" --arg b "${5:-Refs #7}" \
  '{number:$n, body:$b, author:{login:$u}, labels:($l|map({name:.})), isCrossRepository:$x}'; }
run() { jq -s . | jq -r "$CLOSE"; }
confere "close: PR de terceiro sem label não fecha" "" "$(pr 1 intruso '[]' false | run)"
confere "close: PR do dono fecha e apaga branch" "2 --delete-branch" "$(pr 2 $dono '[]' false | run)"
confere "close: PR com label agent fecha" "3 --delete-branch" "$(pr 3 bot '["agent"]' false | run)"
confere "close: fork não apaga a branch" "4 " "$(pr 4 $dono '["agent"]' true | run)"
confere "close: sem Refs #7 não fecha" "" "$(pr 5 $dono '[]' false 'Refs #70' | run)"

echo "--- falhas: $falhas"
exit $((falhas > 0))
