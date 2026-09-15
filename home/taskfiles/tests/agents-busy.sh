#!/usr/bin/env bash
# Checa o que o `gh:agents-busy` fecha e o que ele retoma. A task roda DE
# VERDADE, com um `orca` falso no PATH que responde `terminal
# list/wait/read/close/send` a partir de uma tabela — nada de cópia da lógica.
#
# Os dois erros são caros e opostos: fechar cedo mata um agente trabalhando ou
# parado no limite de uso (com o prompt inteiro no contexto); fechar tarde
# prende a worktree e o lock `agent:running`. Retomar tem o seu próprio: mandar
# `continue` pra sessão cuja cota não voltou, ou pra sempre no mesmo terminal.
set -uo pipefail

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/stub" "$tmp/state/retomadas"
: > "$tmp/stub/ociosos"; : > "$tmp/stub/fechados"; : > "$tmp/stub/enviados"

cat > "$tmp/bin/orca" <<'STUB'
#!/usr/bin/env bash
d="$ORCA_STUB"; h=""; ant=""
for a in "$@"; do [ "$ant" = --terminal ] && h=$a; ant=$a; done
case "$1 $2" in
  "terminal list") [ -f "$d/list.json" ] || exit 1; cat "$d/list.json" ;;
  "terminal wait")
    if grep -qx -- "$h" "$d/ociosos"; then
      printf '{"ok":true,"result":{"wait":{"handle":"%s","condition":"tui-idle","satisfied":true,"status":"running"}}}\n' "$h"
    else
      printf '{"ok":false,"error":{"code":"timeout","message":"timeout"}}\n'; exit 1
    fi ;;
  "terminal read") cat "$d/tela-$h" 2>/dev/null ;;
  # O `orca terminal close` de verdade sai 1 mesmo quando fecha.
  "terminal close") echo "$h" >> "$d/fechados"; exit 1 ;;
  "terminal send") echo "$h" >> "$d/enviados" ;;
  *) exit 2 ;;
esac
STUB
chmod +x "$tmp/bin/orca"

# Sonda falsa: anota qual modelo foi sondado e responde conforme SONDA_OK.
cat > "$tmp/bin/sonda" <<'STUB'
#!/usr/bin/env bash
echo "$1" >> "$ORCA_STUB/sondados"
[ "${SONDA_OK:-true}" = true ]
STUB
chmod +x "$tmp/bin/sonda"

# A worktree dos casos gerais roda MiniMax: é o que o RUNS_FILE diz.
runs="$tmp/runs.jsonl"
echo '{"repo":"o/x","issue":1,"etapa":"execucao","runner":"claude-model minimax-m3","em":"2026-09-15T00:00:00Z"}' > "$runs"

agora=$(date +%s)
limite_mm="API Error: Request rejected (429) · Token Plan usage limit reached: Upgrade your Token Plan"
declare -A esperado nome retoma
json="[]"; n=0
# $1 descrição  $2 calado há N min ("-" = nunca escreveu)  $3 TUI no prompt (s|n)
# $4 tela  $5 esperado (fecha|fica)  $6 retoma (s|n|teto — teto = já retomado RESUME_MAX vezes)
caso() {
  n=$((n + 1)); local h="t$n" out=0
  [ "$2" = - ] || out=$(( (agora - $2 * 60) * 1000 ))
  json=$(jq -c --arg h "$h" --argjson o "$out" '. + [{handle:$h, lastOutputAt:$o}]' <<<"$json")
  [ "$3" = s ] && echo "$h" >> "$tmp/stub/ociosos"
  printf '%s' "$4" > "$tmp/stub/tela-$h"
  nome[$h]=$1; esperado[$h]=$5; retoma[$h]=${6:-n}
  [ "${6:-n}" = teto ] && echo 3 > "$tmp/state/retomadas/$h"
}

caso "agente trabalhando"                    0   n ""                         fica
caso "agente no prompt há 5 min"             5   s "❯"                        fecha
caso "agente no prompt há 1 min (folga)"     1   s "❯"                        fica
caso "shell de setup calado há 10 min"       10  n "\$"                       fica
caso "calado há 40 min, TUI desconhecida"    40  n ""                         fecha
caso "no prompt pelo limite, há 5 min"       5   s "Claude usage limit reached" fica
caso "parado no limite há 40 min"            40  s "Claude usage limit reached" fica
caso "parado no limite há 13h (teto)"        780 s "Claude usage limit reached" fecha
caso "recém-criado, nunca escreveu"          -   n ""                         fica
caso "429 do MiniMax, cota voltou"           40  s "$limite_mm"               fica s
caso "429 do MiniMax, já retomado 3 vezes"   40  s "$limite_mm"               fica teto
jq -n --argjson t "$json" '{ok:true, result:{terminals:$t}}' > "$tmp/stub/list.json"

falhas=0
confere() { # $1 descrição  $2 esperado  $3 obtido
  if [ "$2" = "$3" ]; then st=ok; else st=FALHOU; falhas=$((falhas + 1)); fi
  printf '%-7s %-40s esperado=%-6s obtido=%s\n' "$st" "$1" "$2" "$3"
}
roda() { # $1 WT  $2 resposta da sonda (true|false)  $3 STATE_DIR
  PATH="$tmp/bin:$PATH" ORCA_STUB="$tmp/stub" SONDA_OK="$2" \
    task gh:agents-busy WT="$1" PROBE="$tmp/bin/sonda" STATE_DIR="$3" RUNS_FILE="$runs" 2>/dev/null
}

ocupados=$(roda "path:$HOME/orca/workspaces/x/issue-1" true "$tmp/state")

fechas=0
for i in $(seq 1 "$n"); do
  h="t$i"; obtido=fica
  grep -qx -- "$h" "$tmp/stub/fechados" && obtido=fecha
  [ "$obtido" = fecha ] && fechas=$((fechas + 1))
  confere "${nome[$h]}" "${esperado[$h]}" "$obtido"
  quer=n; [ "${retoma[$h]}" = s ] && quer=s
  obtido=n; grep -qx -- "$h" "$tmp/stub/enviados" && obtido=s
  [ "$quer" = n ] && [ "$obtido" = n ] || confere "  retomado: ${nome[$h]}" "$quer" "$obtido"
done

# Só o 429 do MiniMax recebe `continue`, e o contador sobe.
confere "retomadas enviadas" 1 "$(wc -l < "$tmp/stub/enviados" | tr -d ' ')"
confere "contador do retomado" 1 "$(cat "$tmp/state/retomadas/t10" 2>/dev/null)"

# A contagem é o contrato com o `gh:reap`: quem sobrou, parado incluído.
confere "contagem de ocupados" "$((n - fechas))" "$ocupados"

# Cota ainda fora: parado segue parado, ninguém recebe `continue`.
: > "$tmp/stub/enviados"; : > "$tmp/stub/fechados"; mkdir -p "$tmp/state2"
roda "path:$HOME/orca/workspaces/x/issue-1" false "$tmp/state2" >/dev/null
confere "sonda falhou: nenhuma retomada" 0 "$(wc -l < "$tmp/stub/enviados" | tr -d ' ')"

# Um provedor por worktree: a tela de cota de cada um, o modelo que o
# RUNS_FILE diz, e se a sonda certa foi chamada. As mensagens do DeepSeek e do
# Z.ai são as da doc deles, no formato em que o Claude Code as mostra; a do
# OpenCode Go não é documentada, então o caso usa só o 429.
# $1 descrição  $2 issue  $3 runner no RUNS_FILE (- = nenhum)  $4 tela
# $5 modelo sondado (- = nenhum)  $6 retomado (s|n)
provedor() {
  local st="$tmp/p$2" sond
  mkdir -p "$st/retomadas"
  : > "$tmp/stub/enviados"; : > "$tmp/stub/fechados"; : > "$tmp/stub/sondados"
  echo p1 > "$tmp/stub/ociosos"
  printf '%s' "$4" > "$tmp/stub/tela-p1"
  jq -n --argjson o $(( (agora - 40 * 60) * 1000 )) '{ok:true, result:{terminals:[{handle:"p1", lastOutputAt:$o}]}}' > "$tmp/stub/list.json"
  [ "$3" = - ] || jq -cn --arg r "$3" --argjson n "$2" \
    '{repo:"o/prov", issue:$n, etapa:"execucao", runner:$r, em:"2026-09-15T00:00:00Z"}' >> "$runs"
  PATH="$tmp/bin:$PATH" ORCA_STUB="$tmp/stub" SONDA_OK=true \
    task gh:agents-busy WT="path:$HOME/orca/workspaces/prov/issue-$2" PROBE="$tmp/bin/sonda" \
    STATE_DIR="$st" RUNS_FILE="$runs" >/dev/null 2>&1
  sond=$(tail -1 "$tmp/stub/sondados")
  confere "$1: sonda" "$5" "${sond:--}"
  confere "$1: retomado" "$6" "$(grep -qx p1 "$tmp/stub/enviados" && echo s || echo n)"
  confere "$1: segue vivo" fica "$(grep -qx p1 "$tmp/stub/fechados" && echo fecha || echo fica)"
}
erro() { printf 'API Error: Request rejected (%s) · %s' "$1" "$2"; }

provedor "DeepSeek, 429"            11 "claude-model deepseek-v4-flash" "$(erro 429 'Rate Limit Reached')"  deepseek-v4-flash s
provedor "DeepSeek, 402 de saldo"   12 "claude-model deepseek-v4-pro"   "$(erro 402 'Insufficient Balance')" deepseek-v4-pro s
provedor "Z.ai, limite de 5h"       13 "claude-model glm-5.3"           "$(erro 429 'Usage limit reached for 5 hour. Your limit will reset at 2026-09-15 18:00:00 (1308)')" glm-5.3 s
provedor "Z.ai, sem saldo"          14 "claude-model glm-5.3-flash"     "$(erro 429 'Insufficient balance or no resource package. Please recharge. (1113)')" glm-5.3-flash s
provedor "OpenCode Go (Kimi), 429"  15 "claude-model kimi-k3"           "$(erro 429 'Too Many Requests')"    kimi-k3 s
provedor "MiniMax pelo RUNS_FILE"   16 "claude-model minimax-m3"        "$limite_mm"                         minimax-m3 s
provedor "MiniMax de antes do log"  17 -                                "$limite_mm"                         minimax-m3 s
provedor "Opus no limite: sem sonda" 18 claude                          "Claude usage limit reached"         - n

# Worktree que não existe devolve 0 — é o que solta o lock no `gh:reap`.
rm -f "$tmp/stub/list.json"
confere "worktree que não existe" 0 "$(roda "path:/nao/existe" true "$tmp/state")"

[ "$falhas" -eq 0 ] && echo "agents-busy: ok" || echo "agents-busy: $falhas falha(s)"
exit "$falhas"
