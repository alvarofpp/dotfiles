#!/usr/bin/env bash
# Checa a decisão por issue do `gh:pr-tick-prep` com um `gh` falso no PATH: o
# prep AGE (pergunta rodadas, move card), então rodar contra o GitHub de verdade
# muda issue de cliente — foi o que aconteceu na lucida-monorepo#125 ao
# escrever este teste. O falso responde o já-filtrado (`--jq` é do gh) e
# anota as escritas em `$GH_STUB/escritas`.
set -uo pipefail

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
cat > "$tmp/bin/gh" <<'EOF'
#!/usr/bin/env bash
a="$*"; s="$GH_STUB"
case "$a" in
  "pr list"*"--label agent"*) cat "$s/prs" ;;
  "pr list"*) ;;
  "pr view"*"--json labels"*"agent:approved"*) echo false ;;
  "pr view"*"--json labels"*"agent:changes"*) cat "$s/changes" ;;
  "pr view"*"--json reviews"*) cat "$s/rodadas" ;;
  "issue view"*"--json comments"*) echo 0 ;;
  "pr edit"*|"issue edit"*|"issue comment"*) echo "$a" >> "$s/escritas" ;;
  "api user"*) echo eu ;;
  *) echo "$a" >> "$s/escritas" ;;
esac
EOF
chmod +x "$tmp/bin/gh"

falhas=0
confere() { # $1 descrição  $2 esperado  $3 obtido
  if [ "$2" = "$3" ]; then printf 'ok\t%-45s %s\n' "$1" "$3"
  else printf 'FALHA\t%-45s esperado=%s obtido=%s\n' "$1" "$2" "$3"; falhas=$((falhas + 1)); fi
}

caso() { # $1 PRs  $2 changes  $3 rodadas → imprime o JSON do prep
  printf '%s' "$1" > "$tmp/prs"; echo "$2" > "$tmp/changes"; echo "$3" > "$tmp/rodadas"
  : > "$tmp/escritas"
  PATH="$tmp/bin:$PATH" GH_STUB="$tmp" task gh:pr-tick-prep REF=o/y#9 BOARD_CACHE="$tmp/cache" 2>/dev/null
}

out=$(caso 7 false 0)
confere "1ª rodada: PR" 7 "$(printf '%s' "$out" | jq -r .pr)"
confere "1ª rodada: rodada" 1 "$(printf '%s' "$out" | jq -r .rodada)"
confere "1ª rodada: revisão do zero" s "$(printf '%s' "$out" | jq -r .prompt | grep -q '^Rode /review-pr 7 --julgamento' && echo s || echo n)"
confere "1ª rodada: runner" "claude --model opus" "$(printf '%s' "$out" | jq -r .runner)"

out=$(caso 7 false 2)
confere "3ª rodada: --check" s "$(printf '%s' "$out" | jq -r .prompt | grep -q '^Rode /review-pr --check 7' && echo s || echo n)"

confere "agent:changes: nada a revisar" "" "$(caso 7 true 1)"
confere "sem PR: nada a revisar" "" "$(caso '' false 0)"

out=$(caso 7 false 5)
confere "no teto: nada a revisar" "" "$out"
confere "no teto: pergunta na issue" 1 "$(grep -c '^issue comment 9' "$tmp/escritas")"

[ "$falhas" = 0 ] && echo "pr-tick-prep: ok" || { echo "pr-tick-prep: $falhas falha(s)"; exit 1; }
