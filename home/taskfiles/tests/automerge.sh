#!/usr/bin/env bash
# Checa o filtro do `gh:automerge-check` — quem decide se um PR aprovado mescla
# sozinho ou espera o Álvaro. A task roda DE VERDADE, com o PR injetado pela
# costura `JSON=` e o interruptor pela `ALLOW=`; nada de cópia da lógica.
#
# O erro caro aqui é um só e tem uma direção: liberar o que não devia. Por isso
# cada regra que força humano tem um caso, e o caso "passa" é UM — o resto do
# arquivo existe pra provar que ele não passa por acidente.
set -uo pipefail

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
allow="$tmp/allow"; printf 'alvarofpp/*\nterceiro/autorizado\n' > "$allow"

# PR que passa em tudo. Cada caso altera UM campo com jq e espera reprovar.
base=$(cat <<'JSON'
{"state":"OPEN","isDraft":false,"mergeable":"MERGEABLE",
 "additions":40,"deletions":12,"changedFiles":2,
 "labels":{"nodes":[{"name":"agent"},{"name":"agent:approved"}]},
 "reviews":{"nodes":[{"body":"revisado, sem achado bloqueante","submittedAt":"2026-09-10T10:00:00Z"}]},
 "reviewThreads":{"nodes":[{"isResolved":true}]},
 "files":{"nodes":[{"path":"app/lib/src/widgets/snackbars.dart"},{"path":"docs/decisions/2026-09-10-x.md"}]},
 "commits":{"nodes":[{"commit":{"committedDate":"2026-09-10T09:00:00Z","parents":{"totalCount":1},
                               "statusCheckRollup":{"state":"SUCCESS"}}}]}}
JSON
)

falhas=0
# $1 nome  $2 esperado (auto|human)  $3 filtro jq aplicado ao base  $4 repo
caso() {
  local nome="$1" esperado="$2" filtro="$3" repo="${4:-alvarofpp/matria}"
  local pj="$tmp/pr.json" saida obtido st
  printf '%s' "$base" | jq "$filtro" > "$pj" || { echo "jq falhou em $nome"; return; }
  saida=$(task gh:automerge-check REPO="$repo" PR=1 ALLOW="$allow" JSON="$pj" 2>/dev/null | head -1)
  case "$saida" in
    auto:*)  obtido=auto ;;
    human:*) obtido=human ;;
    *)       obtido="?($saida)" ;;
  esac
  if [ "$obtido" = "$esperado" ]; then st=ok; else st=FALHOU; falhas=$((falhas + 1)); fi
  printf '%-7s %-46s esperado=%-6s %s\n' "$st" "$nome" "$esperado" "${saida:-<vazio>}"
}

# --- o único caso que libera
caso "PR pequeno, revisado, CI verde"        auto  '.'

# --- o interruptor
caso "repo fora da lista"                    human '.'  alvarofpp2/outro
caso "terceiro NÃO alcançado por glob"       human '.'  mvinnicius22/abacaxei-app
caso "terceiro autorizado por nome literal"  auto  '.'  terceiro/autorizado

# --- estado do PR
caso "PR fechado"                            human '.state = "MERGED"'
caso "draft"                                 human '.isDraft = true'
caso "conflitando"                           human '.mergeable = "CONFLICTING"'
caso "mergeable desconhecido"                human '.mergeable = "UNKNOWN"'

# --- o que a revisão disse
caso "label agent:human"                     human '.labels.nodes += [{"name":"agent:human"}]'
caso "label agent:changes"                   human '.labels.nodes += [{"name":"agent:changes"}]'
caso "sem revisão com corpo"                 human '.reviews.nodes = [{"body":"","submittedAt":"2026-09-10T10:00:00Z"}]'
caso "duas rodadas de revisão"               human '.reviews.nodes += [{"body":"faltou x","submittedAt":"2026-09-10T11:00:00Z"}]'
caso "thread aberta"                         human '.reviewThreads.nodes += [{"isResolved":false}]'

# --- código que ninguém revisou. Merge commit NÃO conta: é a main que o
#     próprio gh:merge-approved traz, e contá-la reprovaria todo PR em dia.
caso "commit depois da revisão"              human '.commits.nodes += [{"commit":{"committedDate":"2026-09-10T12:00:00Z","parents":{"totalCount":1},"statusCheckRollup":{"state":"SUCCESS"}}}]'
caso "merge da main depois não reprova"      auto  '.commits.nodes += [{"commit":{"committedDate":"2026-09-10T12:00:00Z","parents":{"totalCount":2},"statusCheckRollup":{"state":"SUCCESS"}}}]'

# --- CI. Ausência de sinal não é autorização.
caso "CI vermelho"                           human '.commits.nodes[-1].commit.statusCheckRollup.state = "FAILURE"'
caso "CI pendente"                           human '.commits.nodes[-1].commit.statusCheckRollup.state = "PENDING"'
caso "repo sem CI nenhum"                    human '.commits.nodes[-1].commit.statusCheckRollup = null'

# --- tamanho
caso "diff no teto passa"                    auto  '.additions = 150 | .deletions = 50'
caso "uma linha acima do teto"               human '.additions = 150 | .deletions = 51'

# --- lista de arquivos truncada não se julga
caso "mais arquivos do que o lido"           human '.changedFiles = 140'

# --- caminhos de risco
# `changedFiles` acompanha: sem isso o caso reprovaria pela checagem de lista
# truncada, que vem antes, e a regra de risco nunca seria exercida.
risco() { caso "risco: $1" human ".changedFiles += 1 | .files.nodes += [{\"path\":\"$1\"}]"; }
risco "web/database/migrations/2026_01_01_x.php"
risco "db/schema.sql"
risco ".github/workflows/ci.yml"
risco "docker/app.Dockerfile"
risco "docker-compose.yml"
risco "docker-stack.yml"
risco "web/composer.json"
risco "web/composer.lock"
risco "app/pubspec.yaml"
risco "package-lock.json"
risco "uv.lock"
risco "go.mod"
risco ".env.example"
risco "Taskfile.yml"
risco ".claude/hooks/check-coverage.sh"
risco "web/routes/api.php"
risco "web/config/app.php"
risco "web/app/Policies/ListaPolicy.php"

# --- caminhos que NÃO são risco (senão o filtro nunca libera nada)
seguro() { caso "seguro: $1" auto ".changedFiles += 1 | .files.nodes += [{\"path\":\"$1\"}]"; }
seguro "app/lib/src/l10n/intl_pt.arb"
seguro "docs/references/I18N.md"
seguro "web/tests/Feature/Api/PostTest.php"
seguro "apps/admin/resources/js/lang/pt-BR/common.ts"

# --- o `gh:merge-approved` chama o filtro DEPOIS de um `cd` no checkout do
# projeto, e o `task` resolve o Taskfile do CWD. Sem voltar pro home ele acha o
# Taskfile do projeto, não encontra a task, e imprime a lista de tasks DELE como
# se fosse o veredito — foi o que aconteceu na primeira execução real. Falha
# fechado, então nada mescla errado; o filtro só deixa de existir, calado.
yml="$(dirname "$0")/../GitHub.yml"
chamada=$(grep -n 'task gh:automerge-check REPO={{.REPO}}' "$yml" | head -1)
case "$chamada" in
  *'cd ~ && task gh:automerge-check'*) st=ok ;;
  *) st=FALHOU; falhas=$((falhas + 1)) ;;
esac
printf '%-7s %-46s %s\n' "$st" "filtro chamado a partir do home" "${chamada#*:}"

[ "$falhas" -eq 0 ] && echo "automerge: ok" || echo "automerge: $falhas falha(s)"
exit "$falhas"
