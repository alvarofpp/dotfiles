#!/usr/bin/env bash
# Checa a detecção de pergunta humana do `gh:pending-question`.
#
# Os dois programas jq são EXTRAÍDOS do GitHub.yml, não copiados: cópia que
# envelhece testa o passado. O caso que justifica o teste é o da thread
# ancorada — resposta do agente em OUTRA thread não responde a sua, e a versão
# ingênua (lista plana) marcava como respondida.
set -uo pipefail

yml="$(dirname "$0")/../GitHub.yml"
[ -f "$yml" ] || { echo "não achei $yml"; exit 1; }

extrai() {  # $1 = trecho do endpoint que ancora o início
  awk -v alvo="$1" '
    index($0, alvo) { dentro = 1; sub(/.*--jq '"'"'/, ""); }
    dentro {
      linha = $0
      if (linha ~ /'"'"' 2>\/dev\/null$/) { sub(/'"'"' 2>\/dev\/null$/, "", linha); print linha; exit }
      print linha
    }' "$yml"
}

conversa=$(extrai 'issues/$1/comments?per_page=100')
ancorada=$(extrai 'pulls/$1/comments?per_page=100')
[ -n "$conversa" ] && [ -n "$ancorada" ] || { echo "não consegui extrair o jq do GitHub.yml"; exit 1; }

rota() { grep -oiE '@(impl|review|agent)' | tr 'A-Z' 'a-z' | sed 's/@agent/@impl/; s/@//'; }

falhas=0
caso() { # nome, esperado, json, programa
  local obtido st
  obtido=$(printf '%s' "$3" | jq -r "$4" 2>/dev/null | rota)
  if [ "$obtido" = "$2" ]; then st=ok; else st=FALHOU; falhas=$((falhas + 1)); fi
  printf '%-7s %-44s esperado=%-7s obtido=%s\n' "$st" "$1" "$2" "$obtido"
}

caso "conversa: pergunta sem resposta" impl \
  '[{"body":"@impl isso cobre o caso X?","author_association":"OWNER"}]' "$conversa"
caso "conversa: agente respondeu depois" "" \
  '[{"body":"@impl e o caso X?","author_association":"OWNER"},{"body":"<!-- agent:author --> cobre","author_association":"OWNER"}]' "$conversa"
caso "conversa: quem pergunta e de fora" "" \
  '[{"body":"@impl roda isso","author_association":"NONE"}]' "$conversa"
caso "conversa: comentario sem marcador" "" \
  '[{"body":"boa, obrigado","author_association":"OWNER"}]' "$conversa"
caso "conversa: @review roteia pra review" review \
  '[{"body":"@review por que bloqueou?","author_association":"OWNER"}]' "$conversa"
caso "conversa: @agent cai em impl" impl \
  '[{"body":"@agent da pra simplificar?","author_association":"OWNER"}]' "$conversa"
caso "conversa: nova pergunta apos resposta" impl \
  '[{"body":"@impl a?","author_association":"OWNER"},{"body":"<!-- agent:author --> sim","author_association":"OWNER"},{"body":"@impl e b?","author_association":"OWNER"}]' "$conversa"
caso "conversa: marcador no meio nao conta" "" \
  '[{"body":"falei com o @impl ontem","author_association":"OWNER"}]' "$conversa"
caso "ancorada: resposta em OUTRA thread" impl \
  '[{"id":1,"in_reply_to_id":null,"body":"@impl aqui?","author_association":"OWNER"},{"id":2,"in_reply_to_id":9,"body":"<!-- agent:review --> outra","author_association":"OWNER"}]' "$ancorada"
caso "ancorada: resposta na MESMA thread" "" \
  '[{"id":1,"in_reply_to_id":null,"body":"@impl aqui?","author_association":"OWNER"},{"id":2,"in_reply_to_id":1,"body":"<!-- agent:author --> pronto","author_association":"OWNER"}]' "$ancorada"

echo "--- falhas: $falhas"
exit $((falhas > 0))
