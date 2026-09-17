#!/usr/bin/env bash
# Checa a designação de modelos do `gh:models`: o sorteio do braço, o rodízio
# dentro dele e os fallbacks. O jq é EXTRAÍDO do GitHub.yml, não copiado: cópia
# que envelhece testa o passado.
#
# Os erros caros, todos calados com a issue andando normalmente: um braço
# incompleto ser sorteado assim mesmo (metade das etapas cairia em fallback e a
# comparação mediria outra coisa); o braço parar de alternar e um dos lados
# nunca juntar amostra; e o `duo` deixar de ser determinístico, que é o que faz
# dele controle.
set -uo pipefail

yml="$(dirname "$0")/../GitHub.yml"
JQM=$(awk -v q="'" '
  !dentro && $0 ~ ("^[[:space:]]*JQM=" q) { dentro = 1; sub("^[[:space:]]*JQM=" q, "") }
  dentro {
    if (substr($0, length($0)) == q) { print substr($0, 1, length($0) - 1); exit }
    print
  }' "$yml")
[ -n "$JQM" ] || { echo "não consegui extrair o JQM do GitHub.yml"; exit 1; }

todos='["opus","haiku","minimax-m3","deepseek-v4-pro","deepseek-v4-flash","glm-5.3","glm-5.3-flash","kimi-k3"]'
sem_zai='["opus","haiku","minimax-m3","deepseek-v4-pro","deepseek-v4-flash","kimi-k3"]'
falhas=0
# O desempate é hash de (etapa, issue, modelo), então o número da issue entra na
# conta: `NUM` fixo aqui pra o caso ser reproduzível. Sem ele o JQM extraído nem
# compila — foi assim que este arquivo ficou vermelho em c4a4456.
# $1 nome  $2 modelos de pé  $3 histórico  $4 já planejada
# $5 esperado: braço plano crítica execução julgamento conferência
caso() {
  local obtido
  obtido=$(jq -nc --argjson disp "$2" --argjson hist "$3" --argjson planejado "$4" \
      --argjson num "${NUM:-7}" "$JQM" \
    | jq -r '"\(.braco) \(.plano) \(.critica) \(.execucao) \(.julgamento) \(.conferencia)"')
  if [ "$obtido" = "$5" ]; then printf 'ok\t%-44s %s\n' "$1" "$obtido"
  else printf 'FALHA\t%-44s esperado=%s obtido=%s\n' "$1" "$5" "$obtido"; falhas=$((falhas + 1)); fi
}

DUO="duo opus opus minimax-m3 opus minimax-m3"

# O braço alterna: é o que faz os dois lados juntarem amostra no mesmo ritmo.
caso "depois de um duo vem o trio" "$todos" '[{"braco":"duo"}]' false \
  "trio glm-5.3 glm-5.3 glm-5.3-flash opus glm-5.3-flash"
caso "depois de um trio vem o duo" "$todos" '[{"braco":"trio"}]' false "$DUO"

# Braço incompleto sai do rodízio INTEIRO, não só da etapa que perdeu o modelo:
# meio braço é uma terceira configuração que ninguém pediu.
caso "sem Z.ai o trio some do rodízio" "$sem_zai" '[{"braco":"trio"}]' false "$DUO"
caso "sem Z.ai, histórico vazio" "$sem_zai" '[]' false "$DUO"

# O `duo` é controle: mesma designação em qualquer issue, sem sorteio. Se um dia
# ele variar, os dois lados viram sorteio e não há mais linha de base.
NUM=99 caso "duo não depende do número da issue" "$sem_zai" '[]' false "$DUO"
NUM=1234 caso "duo não depende do histórico" "$sem_zai" \
  '[{"braco":"duo","plano":"opus","critica":"opus"}]' false "$DUO"

# Revisor da mesma família de quem produziu é PERMITIDO desde 2026-09-17, e no
# duo é o caso normal: Opus critica plano do Opus, M3 confere o que o M3 fez.
# Era proibido até 2026-09-16, e a proibição é o que este caso impede de voltar.
caso "duo: mesma família nas duas pontas" "$sem_zai" '[]' false "$DUO"

# Dentro do braço vale o rodízio: GLM já designado em tudo, então sai o outro
# lado de cada pool. O braço é o que distingue esta linha do `$DUO`.
caso "rodízio dentro do trio" "$todos" \
  '[{"braco":"duo"},{"braco":"duo"},{"braco":"trio","plano":"glm-5.3","critica":"glm-5.3","execucao":"glm-5.3-flash","julgamento":"glm-5.3","conferencia":"glm-5.3-flash"}]' \
  false "trio opus opus minimax-m3 opus minimax-m3"

# Issue que já tem plano (filha, ou planejada antes disto) não reescreve o plano
# nem a crítica — mas segue com braço e com as etapas que faltam.
caso "issue já planejada" "$todos" '[{"braco":"duo"}]' true \
  "trio null null glm-5.3-flash opus glm-5.3-flash"

echo "model-assignment: $([ "$falhas" = 0 ] && echo ok || echo "$falhas falha(s)")"
exit "$falhas"
