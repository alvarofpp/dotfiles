#!/usr/bin/env bash
# Checa o STALL_RE do `gh:agents-busy` — o que separa sessão PARADA de sessão
# MORTA. A regex é extraída do GitHub.yml, não copiada.
#
# Os dois erros possíveis são caros e opostos: frouxa demais, o tick nunca
# fecha terminal ocioso e as sessões empilham; apertada demais, ele fecha uma
# sessão viva que só está esperando cota — que é o caso de 2026-09-04, quatro
# sessões do abacaxei-app paradas com o prompt inteiro no contexto.
set -uo pipefail

yml="$(dirname "$0")/../GitHub.yml"
re=$(grep -o "STALL_RE: '{{.STALL_RE | default \"[^\"]*\"" "$yml" | sed 's/.*default "//; s/"$//')
[ -n "$re" ] || { echo "não consegui extrair o STALL_RE"; exit 1; }

falhas=0
caso() { # nome, esperado (parada|viva), tela
  local obtido st
  if printf '%s' "$3" | grep -qiE "$re"; then obtido=parada; else obtido=viva; fi
  if [ "$obtido" = "$2" ]; then st=ok; else st=FALHOU; falhas=$((falhas + 1)); fi
  printf '%-7s %-48s esperado=%-7s obtido=%s\n' "$st" "$1" "$2" "$obtido"
}

# --- telas que significam "parada, não morta"
caso "limite mensal de gasto"   parada "You've hit your monthly spend limit"
caso "limite de uso"            parada "Claude usage limit reached. Your limit will reset at 3pm."
caso "limite de taxa"           parada "API rate limit exceeded, retrying"
caso "aviso de aproximação"     parada "You are approaching your usage limit"
caso "sugestão de upgrade"      parada "Run /upgrade to increase your limit"

# --- telas de sessão que de fato acabou ou travou
caso "prompt ocioso"            viva "> "
caso "resumo de fim de tarefa"  viva "Done. 3 files changed, tests green."
caso "erro de build"            viva "error: cannot find module 'foo'"
caso "tela vazia"               viva ""
caso "diff no meio"             viva "+  const limite = 10; // teto de itens"

[ "$falhas" -eq 0 ] && echo "stall: ok" || echo "stall: $falhas falha(s)"
exit "$falhas"
