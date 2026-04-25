# TODO

## Next steps

### Pós-auditoria de skills (2026-04-25)

- **Setup do venv do plugin SEO** — manual, fora do git:
  ```bash
  cd ~/.claude/skills/seo && python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
  ```
  Sem o venv, scripts de seo-audit/seo-backlinks/seo-google etc. não rodam.

- **Auditar as 15 skills copiadas pro projeto Matria** (`~/alvarofpp/matria/.claude/skills/`). Foram copiadas as-is no commit `f0bccaa` para preservar guidance projeto-específica. Próxima passada deve:
  - Manter só o que é genuinamente Matria-específico (tokens, paths, voz, personas)
  - Remover conteúdo já coberto pela versão global generalizada (evitar drift duplicado)
  - Casos LIGHT (8 skills) provavelmente podem ser deletados — a global limpa basta

- **Splits incompletos da Batch 6** (opcional) — duas skills ficaram acima do target ~250 linhas:
  - `laravel-l10n/SKILL.md` — 353 linhas (split parcial; PHP examples + middleware/notification ainda inline)
  - `code-review/SKILL.md` — 256 linhas (6 acima do target; restante é processo agnóstico de linguagem)

## Pending tasks

- **Banana extension não instalada** — o plugin claude-seo tem `extensions/banana/` (geração de imagem via Gemini/MCP) que não foi copiado. Se quiser usar `seo-image-gen` em modo geração real, rodar install.sh oficial do plugin com `CLAUDE_SEO_TAG=v1.9.0` ou copiar manualmente.

- **Skill `pdf` — case-sensitivity** (warning Fase 1 não resolvido): SKILL.md cita `REFERENCE.md` e `FORMS.md` mas os arquivos existem em lowercase (`reference.md`, `forms.md`). Em Linux case-sensitive isso pode quebrar refs. Verificar se runtime normaliza casing ou se é bug latente.

- **Relatórios da auditoria em `/tmp/`** — volátil. Se quiser preservar, mover para `~/dotfiles/ai/docs/skills-audit/`:
  - `/tmp/skills-audit-fase1-20260425-1036.md` (inventário 113 skills)
  - `/tmp/skills-audit-fase2-20260425-1139.md` (rubric 28 skills)
  - `/tmp/skills-audit-plano-20260425-1139.md` (plano 6 batches)

## Decisões e convenções

Movidas para [`ai/docs/skills-conventions.md`](ai/docs/skills-conventions.md). Cobre frontmatter válido, regra de `name` casando com slug, escopo global vs projeto, description de gatilho, progressive disclosure, e setup do plugin SEO.
