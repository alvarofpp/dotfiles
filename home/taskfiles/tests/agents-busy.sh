#!/usr/bin/env bash
# Checa o que o `gh:agents-busy` fecha. A task roda DE VERDADE, com um `orca`
# falso no PATH que responde `terminal list/wait/read/close` a partir de uma
# tabela — nada de cópia da lógica.
#
# Os dois erros são caros e opostos: fechar cedo mata um agente trabalhando ou
# parado no limite de uso (com o prompt inteiro no contexto); fechar tarde
# prende a worktree e o lock `agent:running`.
set -uo pipefail

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/stub"
: > "$tmp/stub/ociosos"; : > "$tmp/stub/fechados"

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
  *) exit 2 ;;
esac
STUB
chmod +x "$tmp/bin/orca"

agora=$(date +%s)
declare -A esperado nome
json="[]"; n=0
# $1 descrição  $2 calado há N min ("-" = nunca escreveu)  $3 TUI no prompt (s|n)
# $4 tela  $5 esperado (fecha|fica)
caso() {
  n=$((n + 1)); local h="t$n" out=0
  [ "$2" = - ] || out=$(( (agora - $2 * 60) * 1000 ))
  json=$(jq -c --arg h "$h" --argjson o "$out" '. + [{handle:$h, lastOutputAt:$o}]' <<<"$json")
  [ "$3" = s ] && echo "$h" >> "$tmp/stub/ociosos"
  printf '%s' "$4" > "$tmp/stub/tela-$h"
  nome[$h]=$1; esperado[$h]=$5
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
jq -n --argjson t "$json" '{ok:true, result:{terminals:$t}}' > "$tmp/stub/list.json"

falhas=0
ocupados=$(PATH="$tmp/bin:$PATH" ORCA_STUB="$tmp/stub" \
  task gh:agents-busy WT="path:$HOME/orca/workspaces/x/issue-1" 2>/dev/null)

fechas=0
for i in $(seq 1 "$n"); do
  h="t$i"; obtido=fica
  grep -qx -- "$h" "$tmp/stub/fechados" && obtido=fecha
  [ "$obtido" = fecha ] && fechas=$((fechas + 1))
  if [ "$obtido" = "${esperado[$h]}" ]; then st=ok; else st=FALHOU; falhas=$((falhas + 1)); fi
  printf '%-7s %-40s esperado=%-6s obtido=%s\n' "$st" "${nome[$h]}" "${esperado[$h]}" "$obtido"
done

# A contagem é o contrato com o `gh:reap`: quem sobrou, parado incluído.
if [ "$ocupados" = "$((n - fechas))" ]; then st=ok; else st=FALHOU; falhas=$((falhas + 1)); fi
printf '%-7s %-40s esperado=%-6s obtido=%s\n' "$st" "contagem de ocupados" "$((n - fechas))" "$ocupados"

# Worktree que não existe devolve 0 — é o que solta o lock no `gh:reap`.
rm -f "$tmp/stub/list.json"
ocupados=$(PATH="$tmp/bin:$PATH" ORCA_STUB="$tmp/stub" \
  task gh:agents-busy WT="path:/nao/existe" 2>/dev/null)
if [ "$ocupados" = 0 ]; then st=ok; else st=FALHOU; falhas=$((falhas + 1)); fi
printf '%-7s %-40s esperado=%-6s obtido=%s\n' "$st" "worktree que não existe" 0 "$ocupados"

[ "$falhas" -eq 0 ] && echo "agents-busy: ok" || echo "agents-busy: $falhas falha(s)"
exit "$falhas"
