#!/usr/bin/env bash
# Checa as travas do `gh:merge-approved` que não dependem do GitHub: nome de branch (`brok`, extraído do GitHub.yml),
# PR de fork pulado e o merge preso ao sha julgado (`--match-head-commit`). Trechos extraídos, não copiados.
set -uo pipefail

yml="$(dirname "$0")/../GitHub.yml"
falhas=0
confere() { if [ "$2" = "$3" ]; then printf 'ok\t%-50s %s\n' "$1" "$3"; else printf 'FALHA\t%-50s esperado=%s obtido=%s\n' "$1" "$2" "$3"; falhas=$((falhas + 1)); fi; }

eval "$(grep -m1 -E '^[[:space:]]*brok\(\) ' "$yml")"
declare -F brok >/dev/null || { echo "não achei brok() no GitHub.yml"; exit 1; }

ok() { brok "$1" && echo sim || echo nao; }
confere "branch comum" sim "$(ok 'agent/issue-12_fix.x')"
confere "branch com barra" sim "$(ok 'feat/a-b')"
confere "começa com -" nao "$(ok '--upload-pack=x')"
confere "contém .." nao "$(ok 'a/../b')"
confere "espaço" nao "$(ok 'a b')"
confere "ponto e vírgula" nao "$(ok 'a;rm')"
confere "cifrão" nao "$(ok 'a$(x)')"
confere "dois pontos (refspec)" nao "$(ok 'a:b')"
confere "vazio" nao "$(ok '')"

# fork: o filtro do loop recusa tudo que não for exatamente `false` (campo ausente = fork)
filtro=$(grep -m1 "isCrossRepository == false" "$yml" | sed -E "s/.*jq -r '([^']*)'.*/\1/")
[ -n "$filtro" ] || { echo "não achei o filtro de fork"; exit 1; }
for v in '{"isCrossRepository":true}:fork' '{"isCrossRepository":false}:false' '{}:true'; do
  r=$(printf '%s' "${v%:*}" | jq -r "$filtro")
  [ "$r" = false ] && r=ok || r=recusa
  [ "${v%:*}" = '{"isCrossRepository":false}' ] && e=ok || e=recusa
  confere "fork ${v%:*}" "$e" "$r"
done

# merge preso ao sha, e comparação com o headRefOid
grep -q -- '--match-head-commit "\$headsha"' "$yml"; confere "gh pr merge leva --match-head-commit" 0 $?
grep -q '\[ "\$headsha" = "\$oid" \]' "$yml"; confere "branch que andou depois do julgamento é pulada" 0 $?

echo "--- falhas: $falhas"
exit $((falhas > 0))
