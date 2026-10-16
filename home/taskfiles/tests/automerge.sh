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
# A linha negada vem ANTES do glob de propósito: a negação tem que ganhar em
# qualquer ordem, senão tirar um repo do automerge viraria questão de posição.
allow="$tmp/allow"; printf '!alvarofpp/negado\nalvarofpp/*\nterceiro/autorizado\n' > "$allow"

# PR que passa em tudo. Cada caso altera UM campo com jq e espera reprovar.
base=$(cat <<'JSON'
{"state":"OPEN","isDraft":false,"mergeable":"MERGEABLE",
 "additions":40,"deletions":12,"changedFiles":2,"headRefOid":"h1",
 "labels":{"nodes":[{"name":"agent"},{"name":"agent:approved"}]},
 "reviews":{"totalCount":1,"nodes":[{"author":{"login":"alvarofpp"},"body":"revisado, sem achado bloqueante","submittedAt":"2026-09-10T10:00:00Z","commit":{"oid":"h1"}}]},
 "reviewThreads":{"totalCount":1,"nodes":[{"isResolved":true,"comments":{"nodes":[
   {"author":{"login":"alvarofpp"},"body":"<!-- agent:review -->\n**Revisão** — importante: o problema"},
   {"author":{"login":"alvarofpp"},"body":"<!-- agent:author -->\n**Implementação** — corrigido em x.dart:12"}]}}]},
 "files":{"nodes":[{"path":"app/lib/src/widgets/snackbars.dart"},{"path":"docs/decisions/2026-09-10-x.md"}]},
 "commits":{"nodes":[{"commit":{"oid":"h1","committedDate":"2026-09-10T09:00:00Z","parents":{"totalCount":1},
                               "statusCheckRollup":{"state":"SUCCESS"}}}]}}
JSON
)

falhas=0
# $1 nome  $2 esperado (auto|human)  $3 filtro jq aplicado ao base  $4 repo
caso() {
  local nome="$1" esperado="$2" filtro="$3" repo="${4:-alvarofpp/matria}" lista="${5:-$allow}"
  local pj="$tmp/pr.json" saida obtido st
  printf '%s' "$base" | jq "$filtro" > "$pj" || { echo "jq falhou em $nome"; return; }
  saida=$(task gh:automerge-check REPO="$repo" PR=1 ALLOW="$lista" JSON="$pj" 2>/dev/null | head -1)
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
caso "repo negado, mesmo dentro do glob"     human '.'  alvarofpp/negado

# O GitHub não diferencia maiúsculas em nome de repo e o `case` do shell sim:
# a negação (e a autorização) tem que comparar em minúsculas.
printf 'alvarofpp/*\n!alvarofpp/Foo\n' > "$tmp/allow-caixa"
caso "negação com maiúscula nega o minúsculo"   human '.'  alvarofpp/foo     "$tmp/allow-caixa"
caso "negação vale pro repo escrito em caixa alta" human '.' alvarofpp/FOO   "$tmp/allow-caixa"
caso "o glob não negado segue liberado"         auto  '.'  alvarofpp/matria  "$tmp/allow-caixa"
printf '!ALVAROFPP/*\nalvarofpp/*\n' > "$tmp/allow-glob-caixa"
caso "glob negado em caixa alta nega"           human '.'  alvarofpp/matria  "$tmp/allow-glob-caixa"
printf 'Terceiro/App\n!terceiro/app\n' > "$tmp/allow-terceiro"
caso "terceiro autorizado e negado em caixas diferentes" human '.' Terceiro/APP "$tmp/allow-terceiro"
printf 'Terceiro/App\n' > "$tmp/allow-terceiro2"
caso "terceiro autorizado com maiúscula passa"  auto  '.'  terceiro/app      "$tmp/allow-terceiro2"

# --- estado do PR
caso "PR fechado"                            human '.state = "MERGED"'
caso "draft"                                 human '.isDraft = true'
caso "conflitando"                           human '.mergeable = "CONFLICTING"'
caso "mergeable desconhecido"                human '.mergeable = "UNKNOWN"'

# --- thread resolvida × thread atendida. `isResolved` mede quem clicou; o que
# segura merge é a resposta do autor. Em ai-agency#54 o revisor fechou 9 achados
# `importante` sem uma linha do autor e o PR mesclou sozinho.
caso "importante resolvido SEM resposta do autor" human \
  '.reviewThreads.nodes[0].comments.nodes = [.reviewThreads.nodes[0].comments.nodes[0]]'
caso "nit resolvido sem resposta do autor"        auto  \
  '.reviewThreads.nodes[0].comments.nodes = [{"author":{"login":"alvarofpp"},"body":"<!-- agent:review -->\n**Revisão** — nit: vírgula"}]'
caso "thread sem comentário nenhum"               auto  \
  '.reviewThreads.nodes[0].comments.nodes = []'

# --- o que a revisão disse
caso "label agent:human"                     human '.labels.nodes += [{"name":"agent:human"}]'
caso "label agent:changes"                   human '.labels.nodes += [{"name":"agent:changes"}]'
caso "sem revisão com corpo"                 human '.reviews.nodes = [{"author":{"login":"alvarofpp"},"body":"","submittedAt":"2026-09-10T10:00:00Z"}]'
caso "três rodadas de revisão passam"        auto  '.reviews.nodes += [{"author":{"login":"alvarofpp"},"body":"faltou x","submittedAt":"2026-09-10T11:00:00Z","commit":{"oid":"h1"}},{"author":{"login":"alvarofpp"},"body":"faltou y","submittedAt":"2026-09-10T11:30:00Z","commit":{"oid":"h1"}}]'
caso "quatro rodadas de revisão"             human '.reviews.nodes += [{"author":{"login":"alvarofpp"},"body":"faltou x","submittedAt":"2026-09-10T11:00:00Z"},{"author":{"login":"alvarofpp"},"body":"faltou y","submittedAt":"2026-09-10T11:30:00Z"},{"author":{"login":"alvarofpp"},"body":"faltou z","submittedAt":"2026-09-10T11:45:00Z"}]'
caso "thread aberta"                         human '.reviewThreads.nodes += [{"isResolved":false}]'

# --- código que ninguém revisou. Merge commit NÃO conta: é a main que o
#     próprio gh:merge-approved traz, e contá-la reprovaria todo PR em dia.
#     O que vale é o OID que a review viu, não a data do commit (que se forja).
#     LIMITE: o conteúdo do merge depois da revisão não é conferido aqui (a
#     porta em Python confere a árvore); "merge com extra" só barra lá.
caso "commit depois da revisão"              human '.commits.nodes += [{"commit":{"oid":"c2","committedDate":"2026-09-10T12:00:00Z","parents":{"totalCount":1},"statusCheckRollup":{"state":"SUCCESS"}}}] | .headRefOid = "c2"'
caso "commit retroativo depois da revisão"   human '.commits.nodes += [{"commit":{"oid":"c2","committedDate":"2026-09-01T00:00:00Z","parents":{"totalCount":1},"statusCheckRollup":{"state":"SUCCESS"}}}] | .headRefOid = "c2"'
caso "merge da main depois não reprova"      auto  '.commits.nodes += [{"commit":{"oid":"c2","committedDate":"2026-09-10T12:00:00Z","parents":{"totalCount":2},"statusCheckRollup":{"state":"SUCCESS"}}}] | .headRefOid = "c2"'
caso "merge retroativo seguido de commit"    human '.commits.nodes += [{"commit":{"oid":"c2","committedDate":"2026-09-01T00:00:00Z","parents":{"totalCount":2},"statusCheckRollup":{"state":"SUCCESS"}}},{"commit":{"oid":"c3","committedDate":"2026-09-01T00:00:00Z","parents":{"totalCount":1},"statusCheckRollup":{"state":"SUCCESS"}}}] | .headRefOid = "c3"'
caso "revisão sem o commit que viu"          human '.reviews.nodes[0].commit = null'
caso "commit revisado fora da janela lida"   human '.reviews.nodes[0].commit.oid = "sumiu" | .headRefOid = "c2"'
caso "reviews lidas pela metade"             human '.reviews.totalCount = 80'
caso "threads lidas pela metade"             human '.reviewThreads.totalCount = 150'

# --- PR corrigido e conferido. O veredito do `/review-pr --check` sai como
#     comentário marcado ou só como resposta de thread; os dois cobrem o commit
#     da correção. Resposta de thread do AUTOR (mesma conta) não cobre.
fix='.commits.nodes += [{"commit":{"oid":"c2","committedDate":"2026-09-10T11:00:00Z","parents":{"totalCount":1},"statusCheckRollup":{"state":"SUCCESS"}}}] | .headRefOid = "c2"'
caso "conferido em comentário marcado"       auto  "$fix"' | .comments = {"nodes":[{"author":{"login":"alvarofpp"},"body":"<!-- agent:review -->\n**Revisão** — pode aprovar","createdAt":"2026-09-10T12:00:00Z"}]}'
caso "comentário sem marcador não confere"   human "$fix"' | .comments = {"nodes":[{"author":{"login":"alvarofpp"},"body":"valeu","createdAt":"2026-09-10T12:00:00Z"}]}'
caso "conferido só em thread"                auto  "$fix"' | .reviews.nodes += [{"author":{"login":"alvarofpp"},"body":"","submittedAt":"2026-09-10T12:00:00Z","commit":{"oid":"c2"},"comments":{"nodes":[{"author":{"login":"alvarofpp"},"body":"<!-- agent:review -->\n**Revisão** — resolvido"}]}}]'
caso "thread do autor não confere"           human "$fix"' | .reviews.nodes += [{"author":{"login":"alvarofpp"},"body":"","submittedAt":"2026-09-10T12:00:00Z","commit":{"oid":"c2"},"comments":{"nodes":[{"author":{"login":"alvarofpp"},"body":"<!-- agent:author -->\n**Implementação** — aplicado"}]}}]'

# --- sinal forjado por terceiro (repo público): só o DONO conta. Terceiro não
#     cria revisão, não confere commit posterior e não responde achado.
T='{"login":"intruso"}'
caso "revisão com corpo de terceiro não conta"  human '.reviews.nodes[0].author = '"$T"
caso "resposta do autor forjada não atende"     human '.reviewThreads.nodes[0].comments.nodes[1].author = '"$T"
caso "comentário agent:review forjado não confere" human "$fix"' | .comments = {"nodes":[{"author":'"$T"',"body":"<!-- agent:review -->\n**Revisão** — pode aprovar","createdAt":"2026-09-10T12:00:00Z"}]}'
caso "conferência em thread forjada não confere" human "$fix"' | .reviews.nodes += [{"author":'"$T"',"body":"","submittedAt":"2026-09-10T12:00:00Z","comments":{"nodes":[{"author":'"$T"',"body":"<!-- agent:review -->\n**Revisão** — resolvido"}]}}]'
caso "comentário forjado não esconde commit posterior" human '.commits.nodes += [{"commit":{"oid":"c2","committedDate":"2026-09-10T12:00:00Z","parents":{"totalCount":1},"statusCheckRollup":{"state":"SUCCESS"}}}] | .headRefOid = "c2" | .comments = {"nodes":[{"author":'"$T"',"body":"<!-- agent:review -->\nx","createdAt":"2026-09-10T13:00:00Z"}]}'

# --- CI. Job que disparou tem que estar verde; nenhum job (CI inexistente,
#     pausado, desativado) não impede.
caso "CI vermelho"                           human '.commits.nodes[-1].commit.statusCheckRollup.state = "FAILURE"'
caso "CI pendente"                           human '.commits.nodes[-1].commit.statusCheckRollup.state = "PENDING"'
caso "repo sem CI nenhum"                    auto  '.commits.nodes[-1].commit.statusCheckRollup = null'

# --- tamanho
caso "diff grande não barra"                 auto  '.additions = 3000 | .deletions = 500'

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

# --- o git do merge roda com hook e fsmonitor neutralizados. O checkout é um
# repositório que outra pessoa (ou um agente) mexe: um `pre-commit`/`pre-push`
# ou um `core.fsmonitor` no `.git` dele executaria código nesta máquina só por
# um PR aprovado. A função `g` é EXTRAÍDA do GitHub.yml, não copiada.
gdef=$(grep -m1 -E '^[[:space:]]+g\(\) \{ git -c core\.hooksPath' "$yml")
if [ -z "$gdef" ]; then
  echo "FALHOU  função g do merge-approved não encontrada"; falhas=$((falhas + 1))
else
  eval "${gdef#"${gdef%%[![:space:]]*}"}"
  r="$tmp/repo"; mkdir -p "$r"; git -C "$r" init -q
  git -C "$r" config user.email t@t; git -C "$r" config user.name t
  hook="$r/.git/hooks/pre-commit"
  printf '#!/bin/sh\ntouch "%s/hook-rodou"\n' "$tmp" > "$hook"; chmod +x "$hook"
  printf '#!/bin/sh\ntouch "%s/fsmonitor-rodou"\n' "$tmp" > "$tmp/fsm.sh"; chmod +x "$tmp/fsm.sh"
  git -C "$r" config core.fsmonitor "$tmp/fsm.sh"
  g -C "$r" commit -q --allow-empty -m x >/dev/null 2>&1; g -C "$r" status >/dev/null 2>&1
  if [ ! -e "$tmp/hook-rodou" ] && [ ! -e "$tmp/fsmonitor-rodou" ]; then st=ok; else st=FALHOU; falhas=$((falhas + 1)); fi
  printf '%-7s %-46s\n' "$st" "git do merge não roda hook nem fsmonitor"
  # sanidade: sem a neutralização os dois rodam (senão o caso acima não prova nada)
  git -C "$r" commit -q --allow-empty -m y >/dev/null 2>&1; git -C "$r" status >/dev/null 2>&1
  if [ -e "$tmp/hook-rodou" ] && [ -e "$tmp/fsmonitor-rodou" ]; then st=ok; else st=FALHOU; falhas=$((falhas + 1)); fi
  printf '%-7s %-46s\n' "$st" "sanidade: o mesmo repo executa sem a neutralização"
fi
# E nenhum git cru sobra no merge-approved: tudo passa por `g`.
cru=$(awk '/^  merge-approved:/{m=1} m && /^    cmds:/{d=1} /^  automerge-check:/{d=0; m=0} d' "$yml" | grep -nE '(^|[^[:alnum:]_-])git (-C|fetch|rev-parse|merge-|commit-tree|push)' | grep -vE '^[0-9]+:[[:space:]]*#' | grep -v 'g() {')
if [ -z "$cru" ]; then st=ok; else st=FALHOU; falhas=$((falhas + 1)); fi
printf '%-7s %-46s %s\n' "$st" "merge-approved sem git cru" "$cru"

[ "$falhas" -eq 0 ] && echo "automerge: ok" || echo "automerge: $falhas falha(s)"
exit "$falhas"
