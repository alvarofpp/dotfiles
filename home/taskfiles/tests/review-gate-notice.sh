#!/usr/bin/env bash
# Checa quem recebe o aviso de "este repo está fora do fluxo de revisão" — a
# task roda DE VERDADE, com a lista de PRs injetada pela costura `JSON=` e o
# `DRY=1` no lugar do comentário; nada de cópia do filtro.
#
# O erro caro aqui tem duas direções, e as duas são ruído em PR de OUTRA
# pessoa: avisar quem não esperava revisão sua, e calar com quem esperava.
set -uo pipefail

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

# Um PR de cada tipo que a varredura do `gh:review-requested` encontra.
cat > "$tmp/prs.json" <<'JSON'
[
 {"number":117,"isDraft":false,"labels":[],
  "reviewRequests":[{"login":"alvarofpp"}]},
 {"number":118,"isDraft":true,"labels":[],
  "reviewRequests":[{"login":"alvarofpp"}]},
 {"number":119,"isDraft":false,"labels":[{"name":"agent"}],
  "reviewRequests":[{"login":"alvarofpp"}]},
 {"number":120,"isDraft":false,"labels":[],
  "reviewRequests":[{"login":"outrapessoa"}]},
 {"number":121,"isDraft":false,"labels":[],"reviewRequests":[]}
]
JSON

falhas=0
# $1 nome  $2 PRs esperados (separados por vírgula)  $3 arquivo de lista
caso() {
  local nome="$1" esperado="$2" lista="$3" obtido st
  obtido=$(task gh:review-gate-notice REPO=lucida-ia/lucida-monorepo \
             JSON="$lista" DRY=1 MOTIVO="  ! lucida-ia/lucida-monorepo: catálogo do AGENTS.md desatualizado — rode /agents-doc lá" \
             2>/dev/null | paste -sd',' -)
  if [ "$obtido" = "$esperado" ]; then st=ok; else st=FALHOU; falhas=$((falhas + 1)); fi
  printf '%-7s %-46s esperado=%-12s obtido=%s\n' "$st" "$nome" "$esperado" "${obtido:-<vazio>}"
}

caso "so o PR que pediu revisao sua" "117" "$tmp/prs.json"

# Lista vazia não é erro: repo fora do fluxo sem PR esperando por você não tem
# a quem avisar, e o tick de 15 min passa por aqui em todo repo reprovado.
printf '[]\n' > "$tmp/vazio.json"
caso "repo sem PR esperando" "" "$tmp/vazio.json"

# Dois PRs seus na fila: os dois são avisados, não só o primeiro.
jq '[.[] | select(.number == 117)] + [{"number":122,"isDraft":false,"labels":[],"reviewRequests":[{"login":"alvarofpp"}]}]' \
  "$tmp/prs.json" > "$tmp/dois.json"
caso "avisa todos, nao so o primeiro" "117,122" "$tmp/dois.json"

# A razão do portão entra no comentário — é ela que diz QUAL dos dois defeitos
# do AGENTS.md segurou o repo, e foi a falta dela que custou a investigação.
corpo=$(task gh:review-gate-notice REPO=lucida-ia/lucida-monorepo JSON="$tmp/prs.json" \
          MOTIVO="  ! lucida-ia/lucida-monorepo: catálogo do AGENTS.md desatualizado — rode /agents-doc lá" \
          DRY=1 2>&1 >/dev/null)
echo "$corpo" | grep -q "catálogo do AGENTS.md desatualizado" \
  && printf '%-7s %s\n' ok "a razao do portao entra no comentario" \
  || { printf '%-7s %s\n' FALHOU "a razao do portao entra no comentario"; falhas=$((falhas + 1)); }

echo "--- falhas: $falhas"
exit $((falhas > 0))
