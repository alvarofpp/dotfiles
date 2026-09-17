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

todos='["opus","haiku","minimax-m3","glm-5.3","glm-5.3-flash"]'
sem_zai='["opus","haiku","minimax-m3","deepseek-v4-pro","kimi-k3"]'
sem_minimax='["opus","haiku","glm-5.3","glm-5.3-flash"]'
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
  if [ "$obtido" = "$5" ]; then printf 'ok\t%-46s %s\n' "$1" "$obtido"
  else printf 'FALHA\t%-46s esperado=%s obtido=%s\n' "$1" "$5" "$obtido"; falhas=$((falhas + 1)); fi
}

CM="claude-minimax opus opus minimax-m3 opus minimax-m3"

# Cada braço só usa modelo dos fornecedores que dão nome a ele. Um modelo de fora
# vazando pra dentro de um braço é o defeito que mata a comparação inteira, e
# passa calado: a issue anda, o número sai, e mede outra coisa.
caso "só Claude e MiniMax no braço deles" "$todos" \
  '[{"braco":"claude-glm-minimax"},{"braco":"claude-glm"},{"braco":"glm-minimax"}]' false "$CM"
caso "só GLM no braço GLM+MiniMax" "$todos" \
  '[{"braco":"claude-glm-minimax"},{"braco":"claude-glm"},{"braco":"claude-minimax"}]' false \
  "glm-minimax glm-5.3 glm-5.3 glm-5.3-flash glm-5.3 glm-5.3-flash"
caso "Claude+GLM não usa MiniMax" "$todos" \
  '[{"braco":"claude-glm-minimax"},{"braco":"claude-minimax"},{"braco":"glm-minimax"}]' false \
  "claude-glm glm-5.3 glm-5.3 glm-5.3-flash opus glm-5.3-flash"

# O braço alterna: é o que faz os quatro juntarem amostra no mesmo ritmo. Aqui só
# o BRAÇO está sendo verificado — o histórico não tem etapa nenhuma, então dentro
# dele tudo empata e quem escolhe é o hash.
caso "braço menos usado ganha" "$todos" \
  '[{"braco":"claude-glm"},{"braco":"claude-glm"},{"braco":"claude-minimax"},{"braco":"glm-minimax"},{"braco":"glm-minimax"}]' \
  false "claude-glm-minimax glm-5.3 glm-5.3 glm-5.3-flash opus glm-5.3-flash"

# Braço incompleto sai do rodízio INTEIRO, não só da etapa que perdeu o modelo:
# meio braço é uma quinta configuração que ninguém pediu.
caso "sem Z.ai sobra só Claude+MiniMax" "$sem_zai" \
  '[{"braco":"claude-minimax"},{"braco":"claude-minimax"}]' false "$CM"
caso "sem MiniMax sobra só Claude+GLM" "$sem_minimax" '[{"braco":"claude-glm"}]' false \
  "claude-glm glm-5.3 glm-5.3 glm-5.3-flash opus glm-5.3-flash"

# Claude+MiniMax é controle: mesma designação em qualquer issue, sem sorteio. Se
# um dia ele variar, todos os braços viram sorteio e não há mais linha de base.
NUM=99 caso "controle não depende do nº da issue" "$sem_zai" '[]' false "$CM"
NUM=1234 caso "controle não depende do histórico" "$sem_zai" \
  '[{"braco":"claude-minimax","plano":"opus","critica":"opus"}]' false "$CM"

# Revisor da mesma família de quem produziu é PERMITIDO desde 2026-09-17, e no
# controle é o caso normal: Opus critica plano do Opus, M3 confere o que o M3 fez.
# Era proibido até 2026-09-16, e a proibição é o que este caso impede de voltar.
caso "mesma família nas duas pontas" "$sem_zai" '[]' false "$CM"

# Dentro do braço vale o rodízio, e a contagem é POR BRAÇO: GLM já designado em
# tudo naquele braço, então sai o Opus onde o pool tem os dois. O braço é o que
# distingue esta linha do controle.
caso "rodízio dentro do braço" "$todos" \
  '[{"braco":"claude-glm"},{"braco":"claude-glm"},{"braco":"claude-minimax"},{"braco":"claude-minimax"},{"braco":"glm-minimax"},{"braco":"glm-minimax"},{"braco":"claude-glm-minimax","plano":"glm-5.3","critica":"glm-5.3","execucao":"glm-5.3-flash","julgamento":"glm-5.3","conferencia":"glm-5.3-flash"}]' \
  false "claude-glm-minimax opus opus minimax-m3 opus minimax-m3"

# Issue que já tem plano (filha, ou planejada antes disto) não reescreve o plano
# nem a crítica — mas segue com braço e com as etapas que faltam.
caso "issue já planejada" "$sem_zai" '[]' true \
  "claude-minimax null null minimax-m3 opus minimax-m3"

# A contagem é por braço, não global: histórico de OUTRO braço não pode torcer o
# rodízio deste. Sem o escopo, as 17 execuções em M3 do experimento antigo
# empurrariam todo braço novo pro GLM-Flash por nove issues seguidas.
caso "histórico de outro braço não conta" "$todos" \
  '[{"braco":"claude-minimax"},{"braco":"claude-glm"},{"braco":"glm-minimax"},
    {"braco":"claude-glm","execucao":"glm-5.3-flash"},{"braco":"claude-glm","execucao":"glm-5.3-flash"},
    {"braco":"glm-minimax","execucao":"glm-5.3-flash"},{"braco":"glm-minimax","execucao":"glm-5.3-flash"}]' \
  false "claude-glm-minimax glm-5.3 glm-5.3 glm-5.3-flash opus glm-5.3-flash"

echo "model-assignment: $([ "$falhas" = 0 ] && echo ok || echo "$falhas falha(s)")"
exit "$falhas"
