# TODO

Pendências forward-looking do dotfiles parent. Mudanças concluídas vivem em [`CHANGELOG.md`](CHANGELOG.md); decisões com contexto vão pro [`docs/DECISION_LOG.md`](docs/DECISION_LOG.md).

> Conteúdo relacionado à IA / Claude Code / Hermes / opencode mora no submódulo `ai/` — ver [`ai/TODO.md`](ai/TODO.md).

## Next steps

### Setup robustness

- **`setup.sh` — validar plataforma** — hoje o script detecta `OSTYPE` pra apps darwin-only, mas não checa se WSL2 está ativo antes de tentar `etc/wsl.conf` e `windows/.wslconfig`. Em macOS, `stow.sh` falha silenciosamente nos dois últimos packages.
- **`stow.sh` — flag `--dry-run`** — útil pra revisar o que vai mudar antes de aplicar (especialmente no `etc/` e `windows/` que precisam de sudo).

### Higiene

- **Migrar `home/.config/Emdash/`, `home/.config/JetBrains/`, `home/.config/libreoffice/`, `home/.config/dconf/` pra um diretório `excluded/` ou eliminar do repo** — hoje só estão no `.gitignore` pra não rastrear conteúdo runtime, mas o diretório vazio segue stowado, criando ruído.

## Pending tasks

- _(nada agora)_

## Histórico arquivado

Mudanças concluídas vivem em [`CHANGELOG.md`](CHANGELOG.md). Decisões com trade-offs em [`docs/DECISION_LOG.md`](docs/DECISION_LOG.md).
