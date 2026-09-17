#!/usr/bin/env bash
# Checa o `gh:model-probe` — o sinal de "o provedor deste modelo está de pé"
# que o `gh:dispatch` consulta antes de abrir sessão e o `gh:agents-busy` antes
# de retomar sessão parada.
#
# O que quebra se ele errar: `falha` virando `ok` devolve o loop de despacho
# (sessão morre no 402, tick repõe o lock 10 min depois, pra sempre); `ok`
# virando `falha` para o board inteiro com provedor saudável.
set -uo pipefail

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
falhas=0

confere() { # nome, esperado, obtido
  local st
  if [ "$2" = "$3" ]; then st=ok; else st=FALHOU; falhas=$((falhas + 1)); fi
  printf '%-7s %-40s esperado=%-6s obtido=%s\n' "$st" "$1" "$2" "$3"
}

# Sonda falsa: conta as chamadas e responde conforme o arquivo `resposta`.
cat > "$tmp/sonda" <<'STUB'
#!/usr/bin/env bash
echo "$1" >> "$SONDA_DIR/chamadas"
r=$(cat "$SONDA_DIR/resposta")
case "$r" in ok) exit 0 ;; assinatura) exit 3 ;; *) exit 1 ;; esac
STUB
chmod +x "$tmp/sonda"
export SONDA_DIR="$tmp"
: > "$tmp/chamadas"

roda() { task gh:model-probe MODEL="$1" STATE_DIR="$tmp/state" PROBE="$tmp/sonda" 2>/dev/null; }

echo ok > "$tmp/resposta"
confere "provedor de pé" ok "$(roda modelo-a)"

echo falha > "$tmp/resposta"
confere "provedor caído" falha "$(roda modelo-b)"

# Cache: a resposta velha vale, mesmo com a sonda dizendo outra coisa agora.
echo ok > "$tmp/resposta"
confere "cache segura a resposta" falha "$(roda modelo-b)"
confere "cache não sonda de novo" 2 "$(wc -l < "$tmp/chamadas" | tr -d ' ')"

# TTL zerado força sonda nova.
confere "TTL=0 revalida" ok "$(task gh:model-probe MODEL=modelo-b TTL=0 STATE_DIR="$tmp/state" PROBE="$tmp/sonda" 2>/dev/null)"

# rc=3 é o `roda na assinatura, sem sonda`: sem provedor externo não há cota
# fora do ar. Tratar como falha barrava todo despacho em Opus e Haiku.
echo assinatura > "$tmp/resposta"
confere "assinatura (rc=3) conta como ok" ok "$(roda modelo-c)"

# `claude` é assinatura pelo nome: nem chega a sondar.
echo falha > "$tmp/resposta"
confere "claude não é sondado" ok "$(roda claude)"
confere "claude não gastou sonda" 4 "$(wc -l < "$tmp/chamadas" | tr -d ' ')"

[ "$falhas" -eq 0 ] && echo "model-probe: ok" || echo "model-probe: $falhas falha(s)"
exit "$falhas"
