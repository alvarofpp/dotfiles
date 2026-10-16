#!/usr/bin/env bash
# Checa a gravação do `gh:sessions` no `sessions.jsonl` (dotfiles-private#145): o `printf >>` solto deixava registro
# cortado, e o seguinte grudava nele. Roda a task de verdade, com HOME falso e um transcript sintético.
#
# Os erros caros: linha partida no arquivo (o `gh:metrics` e o `/ctl/modelos` perdem a sessão), e sessão gravada
# duas vezes quando dois `cc:prune-sessions` correm juntos.
set -uo pipefail

yml="$(dirname "$0")/../GitHub.yml"
[ -f "$yml" ] || { echo "não achei $yml"; exit 1; }

casa=$(mktemp -d); trap 'rm -rf "$casa"' EXIT
mkdir -p "$casa/dotfiles/private/taskfiles" "$casa/.local/state/gh-board"
echo '{"MiniMax-M3":{"cobranca":"api","entrada":1000,"saida":2000}}' > "$casa/dotfiles/private/taskfiles/model-prices.json"
arq="$casa/.local/state/gh-board/sessions.jsonl"

# um projeto do Claude com N sessões de uma worktree `issue-7` já apagada
d="$casa/.claude/projects/p1"; mkdir -p "$d"
for i in 1 2 3 4 5 6; do
  printf '{"cwd":"%s/orca/workspaces/app/issue-7","timestamp":"2026-09-15T00:00:0%d.000Z","message":{"id":"m%d","model":"MiniMax-M3","usage":{"input_tokens":10,"output_tokens":1}}}\n' \
    "$casa" "$i" "$i" > "$d/s$i.jsonl"
done

falhas=0
confere() { # nome, esperado, obtido
  if [ "$2" = "$3" ]; then printf 'ok\t%-46s %s\n' "$1" "$3"
  else printf 'FALHA\t%-46s esperado=%s obtido=%s\n' "$1" "$2" "$3"; falhas=$((falhas + 1)); fi
}
invalidas() { local n=0 l; while IFS= read -r l; do printf '%s' "$l" | jq -e . >/dev/null 2>&1 || n=$((n + 1)); done < "$arq"; echo "$n"; }

# arquivo que a gravação anterior deixou terminado no meio de um registro, sem `\n`
printf '{"repo_nome":"app","issue":7,"sessao":"antiga","inicio":"2026-09-1' > "$arq"

# seis arquivamentos ao mesmo tempo, como dois `cc:prune-sessions` sobrepostos
for _ in 1 2 3 4 5 6; do HOME="$casa" task -t "$yml" sessions DIR="$d" >/dev/null 2>&1 & done
wait

confere "uma linha por sessão, sem duplicar"     "6" "$(grep -c '"sessao":"s[1-6]"' "$arq")"
confere "só a linha cortada que já existia"      "1" "$(invalidas)"
confere "registro novo não gruda na cortada"     "6" "$(grep '"sessao":"s[1-6]"' "$arq" | jq -c 'select(.issue == 7)' | wc -l)"

echo "sessions-append: $([ "$falhas" = 0 ] && echo ok || echo "$falhas falha(s)")"
exit "$falhas"
