#!/usr/bin/env bash
# Checa a máquina de estados do `gh:gate-watch` — quando avisa, quando cala e
# quando avisa de volta.
#
# A task roda de verdade; o que é injetado são as costuras `GATE` (o comando
# que decide), `STATE` (onde mora o contador) e `DRY` (imprime em vez de
# mandar no Telegram). O caso que justifica o teste é o do latch: sem ele o
# tick de 15 min repetiria o alerta a noite inteira.
set -uo pipefail

estado=$(mktemp); rm -f "$estado"
trap 'rm -f "$estado"' EXIT

tick() { # $1 = "true" (portão aberto) ou "false" (fechado)
  task gh:gate-watch GATE="$1" STATE="$estado" DRY=1 AFTER_TICKS=3 2>/dev/null
}

falhas=0
caso() { # nome, esperado ("<falhas> <avisado>" no estado), avisou? (sim/nao), saída do tick
  local st
  if [ "$(cat "$estado" 2>/dev/null)" = "$2" ] && [ "$4" = "$3" ]; then st=ok
  else st=FALHOU; falhas=$((falhas + 1)); fi
  printf '%-7s %-40s estado=%-6s aviso=%s\n' "$st" "$1" "$(cat "$estado" 2>/dev/null)" "$4"
}

avisou() { grep -q "avisado:" <<<"$1" && echo sim || echo nao; }

out=$(tick false); caso "1o tick fechado: conta e cala"   "1 0" nao "$(avisou "$out")"
out=$(tick false); caso "2o tick fechado: conta e cala"   "2 0" nao "$(avisou "$out")"
out=$(tick false); caso "3o tick fechado: avisa"          "3 1" sim "$(avisou "$out")"
out=$(tick false); caso "4o tick fechado: nao repete"     "4 1" nao "$(avisou "$out")"
out=$(tick true);  caso "portao reabre: avisa de volta"   "0 0" sim "$(avisou "$out")"
out=$(tick true);  caso "segue aberto: cala"              "0 0" nao "$(avisou "$out")"
out=$(tick false); caso "fecha de novo: reconta do zero"  "1 0" nao "$(avisou "$out")"

# A mensagem tem que sair escapada, senão o Telegram devolve 400 e o aviso some.
rm -f "$estado"; printf '2 0\n' > "$estado"
texto=$(task gh:gate-watch GATE="sh -c 'echo \"svc: <fora> & parado\"; exit 1'" \
          STATE="$estado" DRY=1 AFTER_TICKS=3 2>/dev/null)
if grep -q 'svc: &lt;fora&gt; &amp; parado' <<<"$texto"; then
  printf '%-7s %s\n' ok "motivo com & < > sai escapado"
else
  printf '%-7s %s\n' FALHOU "motivo com & < > sai escapado"; falhas=$((falhas + 1))
fi

echo "--- falhas: $falhas"
exit $((falhas > 0))
