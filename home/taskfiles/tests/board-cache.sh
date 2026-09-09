#!/usr/bin/env bash
# Checa o filtro do `gh:issues` e a invalidação do snapshot do board.
#
# A task roda de verdade; o que é injetado é a costura `CACHE` — um snapshot
# de mentira, no mesmo formato JSON Lines que o `gh:board-scan` grava. Com o
# arquivo recente o `board-scan` não vai à rede, então o teste não depende da
# API (nem do rate limit dela, que é o que motivou o cache).
#
# O caso que justifica o teste: o filtro tem seis `select` encadeados e é o
# que decide se um agente é despachado. Errar pro lado permissivo despacha
# duas vezes a mesma issue.
set -uo pipefail

cache=$(mktemp)
trap 'rm -f "$cache"' EXIT

item() { # tipo, numero, estado, status, labels(csv), blockedBy(csv de estados)
  jq -cn --arg t "$1" --arg n "$2" --arg e "$3" --arg s "$4" --arg l "$5" --arg b "$6" '
    { id: ("PVTI_" + $n),
      content: ({ __typename: $t }
        + (if $t == "Issue" then
             { number: ($n|tonumber), state: $e, repository: { nameWithOwner: "o/r" },
               labels:    { nodes: ($l | if . == "" then [] else split(",") end | map({name:.})) },
               blockedBy: { nodes: ($b | if . == "" then [] else split(",") end | map({state:.})) } }
           else {} end)),
      status: (if $s == "" then null else { name: $s } end) }'
}

{
  item Issue       1 OPEN   "In Progress" ""                     ""
  item Issue       2 OPEN   "In Progress" "agent:running"        ""
  item Issue       3 OPEN   "In Progress" "agent:human"          ""
  item Issue       4 OPEN   "In Progress" ""                     "OPEN"
  item Issue       5 OPEN   "In Progress" ""                     "CLOSED"
  item Issue       6 CLOSED "In Progress" ""                     ""
  item Issue       7 OPEN   "Ready"       ""                     ""
  item Issue       8 OPEN   ""            ""                     ""
  item Issue      10 OPEN   "In Progress" "agent:skip"         ""
  item Issue      11 OPEN   "Ready"       "tipo:bug,agent:skip" ""
  item PullRequest 9 OPEN   "In Progress" ""                     ""
} > "$cache"

falhas=0
caso() { # nome, esperado, obtido
  local st
  if [ "$2" = "$3" ]; then st=ok; else st=FALHOU; falhas=$((falhas + 1)); fi
  printf '%-7s %-46s esperado=%-22s obtido=%s\n' "$st" "$1" "$2" "$3"
}

# TTL alto: snapshot recém-criado é reaproveitado, então nada vai à rede.
lista() { task gh:issues STATUS="$1" CACHE="$cache" TTL=3600 2>/dev/null | awk '{print $1}' | paste -sd, -; }

caso "issue limpa entra"                    "o/r#1,o/r#5" "$(lista 'In Progress')"
caso "outro Status não vaza"                "o/r#7"       "$(lista 'Ready')"
caso "Status inexistente sai vazio"         ""            "$(lista 'Blocked')"

# O id do item é a segunda coluna — é ele que o `gh:status` consome.
caso "leva o itemId junto" "PVTI_1" \
  "$(task gh:issues STATUS='In Progress' CACHE="$cache" TTL=3600 2>/dev/null | awk '$1=="o/r#1"{print $2}')"

# Invalidação: sem ela o `dispatch` leria o board de antes do `prep`.
task gh:board-stale CACHE="$cache" >/dev/null 2>&1
caso "board-stale apaga o snapshot" "sumiu" "$([ -e "$cache" ] && echo existe || echo sumiu)"

[ "$falhas" -eq 0 ] && echo "board-cache: ok" || echo "board-cache: $falhas falha(s)"
exit "$falhas"
