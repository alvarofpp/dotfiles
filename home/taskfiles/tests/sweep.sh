#!/usr/bin/env bash
# Checa QUAIS worktrees o `gh:sweep` varre. A task roda de verdade em `DRY=1`,
# com um `orca` falso no PATH e um snapshot do board injetado por `CACHE=`.
#
# Varrer de mais fecha terminal da sua árvore principal ou de uma issue que você
# assumiu (`agent:skip`); varrer de menos deixa Claude ocioso no prompt pra
# sempre, que é o buraco que a task existe pra fechar.
set -uo pipefail

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
ws="$HOME/orca/workspaces"

jq -n --arg ws "$ws" --arg home "$HOME" '{ok:true, result:{terminals:[
  {handle:"a", worktreePath:($ws + "/matria/issue-5")},
  {handle:"b", worktreePath:($ws + "/matria/issue-5")},
  {handle:"c", worktreePath:($ws + "/matria/issue-7")},
  {handle:"d", worktreePath:($ws + "/lucida-monorepo/pr-33")},
  {handle:"e", worktreePath:($home + "/alvarofpp/matria")},
  {handle:"f", worktreePath:($ws + "/matria/feat-x")}
]}}' > "$tmp/list.json"

cat > "$tmp/bin/orca" <<STUB
#!/usr/bin/env bash
[ "\$1 \$2" = "terminal list" ] && cat "$tmp/list.json"
STUB
# `gh` que falha: é a varredura do board caindo (rede, cota). O snapshot
# presente nunca chega a chamá-lo; o ausente, sim.
printf '#!/usr/bin/env bash\nexit 1\n' > "$tmp/bin/gh"
chmod +x "$tmp/bin/orca" "$tmp/bin/gh"

# Snapshot recém-escrito: o `gh:board-scan` o reaproveita e não vai à rede.
cat > "$tmp/items.jsonl" <<'JSONL'
{"content":{"__typename":"Issue","labels":{"nodes":[{"name":"agent:skip"}]},"number":7,"repository":{"nameWithOwner":"alvarofpp/matria"},"state":"OPEN","blockedBy":{"nodes":[]}},"id":"I7","status":{"name":"In Progress"}}
{"content":{"__typename":"Issue","labels":{"nodes":[]},"number":5,"repository":{"nameWithOwner":"alvarofpp/matria"},"state":"OPEN","blockedBy":{"nodes":[]}},"id":"I5","status":{"name":"In Review"}}
{"content":{"__typename":"PullRequest"},"id":"P33","status":{"name":"Ready"}}
JSONL

falhas=0
# $1 nome  $2 esperado (separado por vírgula)
caso() {
  local obtido st
  obtido=$(PATH="$tmp/bin:$PATH" task gh:sweep DRY=1 CACHE="$3" 2>/dev/null | paste -sd',' -)
  if [ "$obtido" = "$2" ]; then st=ok; else st=FALHOU; falhas=$((falhas + 1)); fi
  printf '%-7s %-52s esperado=%-36s obtido=%s\n' "$st" "$1" "$2" "${obtido:-<vazio>}"
}

# Uma vez por worktree mesmo com dois terminais; skip, árvore principal e
# worktree fora do fluxo ficam de fora.
caso "fluxo sim; skip, principal e feat-x não" "lucida-monorepo/pr-33,matria/issue-5" "$tmp/items.jsonl"

# Varredura do board falhou e não há snapshot: sem saber quem tem skip, não
# varre nada.
caso "board inacessível e sem snapshot, não varre" "" "$tmp/nao-existe.jsonl"

[ "$falhas" -eq 0 ] && echo "sweep: ok" || echo "sweep: $falhas falha(s)"
exit "$falhas"
