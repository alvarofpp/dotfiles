#!/usr/bin/env bash
# Checa o fallback do `gh:close` pra worktree que o Orca já esqueceu — o bloco
# que derruba a instância na mão. O bloco é EXTRAÍDO do GitHub.yml, não
# copiado: cópia que envelhece testa o passado.
#
# O erro caro aqui tem nome: apagar a instância PRINCIPAL do repo. O volume
# dela (`<repo>_pgdata`) é o banco de dev onde você trabalha, e `docker volume
# rm` não pergunta. Por isso os casos cobrem o alvo (só `<repo>-issue-<n>_*`),
# o filtro ancorado, e o silêncio quando não há nada órfão.
#
# Roda com `set -e` de propósito: o shell do Task tem errexit, e `[ -n "$x" ] &&
# cmd` com $x vazio já matou bloco inteiro neste arquivo antes.
set -uo pipefail

yml="$(dirname "$0")/../GitHub.yml"
[ -f "$yml" ] || { echo "não achei $yml"; exit 1; }

# Vai do `proj=` até o `fi` que fecha o bloco — a linha seguinte à do
# aviso de arquivo root:root, que é a última de dentro.
bloco=$(awk '
  /proj=\$\(printf .%s-issue-%s./ { dentro = 1 }
  dentro { print; if (fim) exit }
  /ainda no disco/ { if (dentro) fim = 1 }' "$yml")
[ -n "$bloco" ] || { echo "não consegui extrair o fallback do gh:close"; exit 1; }

falhas=0
log=$(mktemp); trap 'rm -f "$log"' EXIT

# $1 nome  $2 repo  $3 num  $4 containers  $5 volumes  $6 padrão esperado no log
caso() {
  local nome="$2" st
  : > "$log"
  (
    set -e
    repo="alvarofpp/$2"; num="$3"; HOME=/tmp/nao-existe
    CTS="$4" VOLS="$5" LOG="$log"
    docker() {
      printf '%s\n' "docker $*" >> "$LOG"
      case "$1 $2" in
        "ps -aq")      printf '%s' "$CTS" ;;
        # Segunda leitura = a conferência do que sobrou. Devolve vazio, que
        # é o caso "removeu mesmo".
        "volume ls")   [ "${VISTO:-}" = sim ] || printf '%s' "$VOLS"; VISTO=sim ;;
      esac
      return 0
    }
    eval "$bloco"
  ) >/dev/null 2>&1
  local rc=$?
  local obtido
  if [ $rc -ne 0 ]; then obtido="rc=$rc"
  elif grep -qE "$6" "$log"; then obtido=ok
  else obtido="log não bate"; fi
  if [ "$obtido" = ok ]; then st=ok; else st=FALHOU; falhas=$((falhas + 1)); fi
  printf '%-7s %-44s %s\n' "$st" "$1" "$obtido"
  [ "$st" = ok ] || sed 's/^/          /' "$log"
}

# --- alvo: o nome do projeto sai do caminho, e é sempre `<repo>-issue-<n>`
caso "container removido pelo label do projeto" matria 7 "abc123" "" \
  'docker rm -f abc123'
caso "label é o do projeto da instância"        matria 7 "abc123" "" \
  'label=com\.docker\.compose\.project=matria-issue-7'
caso "rede da instância removida"               matria 7 "abc123" "" \
  'docker network rm matria-issue-7_default'

# --- o filtro de volume é ANCORADO: `matria_pgdata` não casa com `^matria-issue-7_`
caso "filtro de volume ancorado no projeto"     matria 7 "" "matria-issue-7_pgdata" \
  'volume ls -q --filter name=\^matria-issue-7_'
caso "volume da instância removido"             matria 7 "" "matria-issue-7_pgdata" \
  'docker volume rm matria-issue-7_pgdata'

# --- repo com maiúscula vira minúscula (COMPOSE_PROJECT_NAME é lowercase)
caso "nome do projeto em minúsculas"            Matria 7 "abc" "" \
  'project=matria-issue-7'

# --- repo cujo nome TEM hífen: o principal é `abacaxei-app`, o órfão é outro
caso "repo com hífen não vira o principal"      abacaxei-app 14 "abc" "" \
  'project=abacaxei-app-issue-14'

# --- nada órfão: nada é removido, e o bloco não fala
caso "sem container e sem volume, não remove"   matria 7 "" "" \
  '^$|^docker (ps|volume ls)'

# o teste acima aceita leitura; este garante que NENHUMA remoção saiu
: > "$log"
(
  set -e
  repo="alvarofpp/matria"; num=7; HOME=/tmp/nao-existe
  CTS="" VOLS="" LOG="$log"
  docker() { printf '%s\n' "docker $*" >> "$LOG"; return 0; }
  eval "$bloco"
) >/dev/null 2>&1
if grep -qE 'rm' "$log"; then
  printf '%-7s %-44s %s\n' FALHOU "instância vazia não sofre remoção" "$(tr '\n' ';' < "$log")"
  falhas=$((falhas + 1))
else
  printf '%-7s %-44s %s\n' ok "instância vazia não sofre remoção" ok
fi

[ "$falhas" -eq 0 ] && echo "orphan-instance: ok" || echo "orphan-instance: $falhas falha(s)"
exit "$falhas"
