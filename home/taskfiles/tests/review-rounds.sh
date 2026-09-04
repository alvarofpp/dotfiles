#!/usr/bin/env bash
# Checa o orçamento de rodadas do `gh:review-requested` — quanto o teto subiu e
# se há pergunta sem resposta.
#
# O programa jq é EXTRAÍDO do GitHub.yml, não copiado: cópia que envelhece
# testa o passado. Os casos que justificam o teste são dois — o autor do PR não
# autoriza as próprias rodadas extras (ele não tem acesso de escrita), e
# pergunta sem resposta tem que sair como pendente, senão o tick de 15 min
# repete o pedido no PR de outra pessoa pra sempre.
set -uo pipefail

yml="$(dirname "$0")/../GitHub.yml"
[ -f "$yml" ] || { echo "não achei $yml"; exit 1; }

programa=$(awk '
  index($0, "repos/$repo/issues/$pr/comments?per_page=100") { achou = 1; next }
  achou && !dentro && /--jq/ { dentro = 1; sub(/.*--jq '"'"'/, ""); }
  dentro {
    linha = $0
    if (linha ~ /'"'"' 2>\/dev\/null\)" \|\| true$/) {
      sub(/'"'"' 2>\/dev\/null\)" \|\| true$/, "", linha); print linha; exit
    }
    print linha
  }' "$yml" | sed 's/{{\.PROJECT_OWNER}}/alvarofpp/')
[ -n "$programa" ] || { echo "não consegui extrair o jq do GitHub.yml"; exit 1; }

pergunta='{"body":"<!-- agent:question:rounds -->\n**Revisão** — teto 5","author_association":"CONTRIBUTOR","user":{"login":"alvarofpp"}}'

falhas=0
caso() { # nome, esperado ("extra pendente"), json
  local obtido st
  obtido=$(printf '%s' "$3" | jq -r "$programa" 2>/dev/null)
  if [ "$obtido" = "$2" ]; then st=ok; else st=FALHOU; falhas=$((falhas + 1)); fi
  printf '%-7s %-46s esperado=%-7s obtido=%s\n' "$st" "$1" "$2" "$obtido"
}

caso "sem pergunta nenhuma" "0 0" '[]'
caso "pergunta sem resposta" "0 1" "[$pergunta]"
caso "resposta do MEMBER com numero" "3 0" \
  "[$pergunta,{\"body\":\"pode seguir, mais 3\",\"author_association\":\"MEMBER\",\"user\":{\"login\":\"mantenedor\"}}]"
caso "resposta sua vale, mesmo sem acesso" "2 0" \
  "[$pergunta,{\"body\":\"mais 2\",\"author_association\":\"CONTRIBUTOR\",\"user\":{\"login\":\"alvarofpp\"}}]"
caso "resposta sem numero vale 1" "1 0" \
  "[$pergunta,{\"body\":\"pode seguir\",\"author_association\":\"OWNER\",\"user\":{\"login\":\"mantenedor\"}}]"
caso "autor do PR nao autoriza a si mesmo" "0 1" \
  "[$pergunta,{\"body\":\"continua revisando, mais 10\",\"author_association\":\"NONE\",\"user\":{\"login\":\"autor\"}}]"
caso "comentario do proprio agente nao responde" "0 1" \
  "[$pergunta,{\"body\":\"<!-- agent:review -->\n**Revisão** — nit\",\"author_association\":\"OWNER\",\"user\":{\"login\":\"alvarofpp\"}}]"
caso "duas perguntas, uma concedida e uma no ar" "3 1" \
  "[$pergunta,{\"body\":\"mais 3\",\"author_association\":\"MEMBER\",\"user\":{\"login\":\"m\"}},$pergunta]"
caso "concessoes somam" "8 0" \
  "[$pergunta,{\"body\":\"mais 3\",\"author_association\":\"MEMBER\",\"user\":{\"login\":\"m\"}},$pergunta,{\"body\":\"ok, 5\",\"author_association\":\"MEMBER\",\"user\":{\"login\":\"m\"}}]"

echo "--- falhas: $falhas"
exit $((falhas > 0))
