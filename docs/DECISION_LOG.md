# Decision Log

Decisões médias do dotfiles parent (público). Decisões grandes (com trade-offs explícitos) viram ADR em `adr/` — não existe ainda; criar quando justificar.

Decisões relacionadas a IA / Claude Code / Hermes / opencode vivem em [`../ai/DECISION_LOG.md`](../ai/DECISION_LOG.md).

Formato fixo: `YYYY-MM-DD — Título — Contexto — Decisão — Refs`.

---

## 2026-07-14 — `windows-terminal-settings.json` é cópia sincronizada, não symlink

**Contexto:** Tentativa de tornar o arquivo do repo a fonte de verdade via symlink em `/mnt/c/.../WindowsTerminal_.../LocalState/settings.json`. Teste empírico com arquivo descartável: `ln -s` em `/mnt/c` apontando pro ext4 do WSL vira um `<JUNCTION>` que o Windows não consegue seguir (PowerShell/API nativa dá `IOException: Não é possível o acesso ao arquivo`). Somam-se dois bloqueios: (1) app Windows não atravessa symlink pro ext4 do WSL; (2) o Windows Terminal reescreve o `settings.json` com escrita atômica (temp + rename) a cada mudança, o que substituiria o symlink por arquivo comum no primeiro save.

**Decisão:** Manter `windows-terminal-settings.json` na raiz como **cópia física** fora do stow, sincronizada à mão (`cp` bidirecional entre repo e `LocalState/`). Não symlinkar. Não criar tasks dedicadas (sync é raro; `cp` na hora basta). O arquivo do repo tende a dessincronizar porque o WT reescreve o real — ao mexer, copiar o real → repo antes de commitar.

**Refs:** commit `88248cb` (sync + `initialCols`/`initialRows`), [`windows-terminal-settings.json`](../windows-terminal-settings.json).

## 2026-05-18 — Estrutura `docs/` no parent (aderir a docs-as-second-brain)

**Contexto:** Parent dotfiles tinha `README.md`, `CLAUDE.md`, `TODO.md` mas faltava `CHANGELOG.md` e `DECISION_LOG.md`. A regra global `docs-as-second-brain` (carregada via Claude Code) recomenda os dois explicitamente.

**Decisão:** Criar `docs/DECISION_LOG.md` (este arquivo) + `CHANGELOG.md` na raiz. **Não criar** `docs/` profundamente — só o necessário pro tripé forward-looking funcionar (TODO + CHANGELOG + DECISION_LOG). Sem `docs/runbooks/`, `docs/guides/`, etc. porque o repo é pequeno demais pra justificar.

**Refs:** [`CHANGELOG.md`](../CHANGELOG.md), [`../TODO.md`](../TODO.md).

## 2026-05-08 — Ignorar `home/.config/psysh/`

**Contexto:** REPL do PHP psysh persiste history em `~/.config/psysh/psysh_history`. Esse history vaza queries SQL completas e código testado em shells interativos. Antes estava sendo rastreado pelo stow.

**Decisão:** Adicionar `home/.config/psysh/` ao `.gitignore` raiz + `git rm --cached psysh_history` (manteve o arquivo no disco local pra não perder history). Trata `home/.config/psysh/` como runtime.

**Refs:** commit `2ac41e3`, [`.gitignore`](../.gitignore).

## 2026-04-30 — Reverter `networkingMode=mirrored` no `.wslconfig`

**Contexto:** Tentativa de fazer Tailscale serve dentro do WSL2 anunciar endpoints. `networkingMode=mirrored` + `firewall=false` em `windows/.wslconfig`. Mesmo com Docker Desktop encerrado e WSL reiniciado, eth0 voltou em `172.27.x.x` (NAT default).

**Decisão:** Reverter pra config NAT default. Pivot pra rodar Tailscale serve no Windows host (alcança WSL via NAT forwarding). Diagnóstico esgotado sem visibility no Event Viewer (requer admin no PowerShell). Detalhamento e retest pendente em [`../ai/DECISION_LOG.md`](../ai/DECISION_LOG.md).

**Refs:** commits `7f64c27`, `9904da4`, `47c9847`, [`windows/.wslconfig`](../windows/.wslconfig).

## 2026-04-27 — `~/.zshrc.d/` drop-in dir, `~/.zshrc.local` pra segredos

**Contexto:** Helpers de shell relacionados a IA (`claude-mini` function, `opencode-mini` validator) cresceram. Colocar no `home/.zshrc` quebraria o isolamento parent-público vs submodule-privado.

**Decisão:** `home/.zshrc` source todos os `.zsh` em `~/.zshrc.d/` (drop-in dir, populado pelo submódulo `ai/.zshrc.d/` via stow). Source também `~/.zshrc.local` (não commitado) pra segredos como `MINIMAX_API_KEY`. Mantém shell helpers de IA fora da raiz do dotfiles, respeitando o isolamento.

**Refs:** commit `3607a84`, [`home/.zshrc`](../home/.zshrc).

## 2026-04-27 — `~/.local/bin` no INÍCIO do PATH

**Contexto:** Wrappers locais (`emdash` em `ai/.local/bin/`, scripts pessoais) precisavam ter precedência sobre binários do sistema.

**Decisão:** Prepend `~/.local/bin` em vez de append no `home/.zshrc`. Permite override transparente quando precisar (ex: wrapper de `emdash` que boota DBus antes do exec).

**Refs:** commit `0eac5a1`, [`home/.zshrc`](../home/.zshrc).

## 2026-04 — Submódulo `ai/` separado pra isolamento

**Contexto:** Conteúdo de IA (skills, agents, decisões sobre providers, integrações Hermes/Tailscale) não devia aparecer no repo público dotfiles. Mas precisa estar versionado + symlinkado via stow pra funcionar.

**Decisão:** Criar submodule `alvarofpp/dotfiles-ai` montado em `ai/`. O parent rastreia só o pointer (SHA). Stow trata `ai/` como package independente. `.stow-local-ignore` filtra runtime dirs do submodule. Memory `feedback_ai_isolation` reforça a separação.

**Refs:** commit `ea83a1c`, [`.gitmodules`](../.gitmodules), memory `feedback_ai_isolation.md`.

## 2026-04 — Pacotes `etc/` e `windows/` precisam de sudo

**Contexto:** `etc/wsl.conf` (config systemd dentro do WSL) e `windows/.wslconfig` (config WSL2 host) precisam ir pra locais privilegiados.

**Decisão:** `stow.sh` invoca `sudo $(which stow)` pros dois packages. Setup permanece manual em parte porque sudo é necessário — sem fix automático fácil. Pacote `etc/` só faz sentido em Linux/WSL; `windows/` só em WSL2 → futuro fix em [`TODO.md`](../TODO.md) é detectar plataforma antes de stowar.

**Refs:** commit `9ec0e5d` (etc), `5095198` (windows), [`stow.sh`](../stow.sh).

## 2026-03 — Homebrew como gerenciador único (mesmo em Linux/WSL2)

**Contexto:** Linux tem apt/dnf/pacman nativos. Por que usar brew?

**Decisão:** Homebrew via `linuxbrew` em `/home/linuxbrew/.linuxbrew/`. Razões:
- Versões mais novas dos tools (eza, bat, atuin, fzf) que apt repos lentos não têm.
- `setup.sh` cross-platform (mesma sintaxe `brew install` em macOS e Linux/WSL).
- `brew upgrade` atualiza todos os tools de shell de uma vez.
- Ferramentas com binário único (`go-task`, `rtk`) ficam isoladas do system package manager.

Trade-off: PATH precisa carregar `brew shellenv` cedo (`home/.zshrc` faz). Scripts não-interativos (systemd, cron) precisam carregar brew env ou usar paths absolutos. `stow` está em `/home/linuxbrew/.linuxbrew/bin/stow`, não `/usr/bin/stow` — gotcha documentado em memory `feedback_stow_via_brew`.

**Refs:** [`setup.sh`](../setup.sh), [`home/.zshrc`](../home/.zshrc).

---

## Como manter

- **Decisão pequena que precisa de memória:** entrada aqui.
- **Decisão grande com trade-offs explícitos:** ADR em `docs/adr/` (não existe ainda; criar quando justificar) e linka daqui.
- **Decisão related-AI:** vai pro [`../ai/DECISION_LOG.md`](../ai/DECISION_LOG.md), não aqui — manter isolamento parent-público.
- Ordem cronológica, mais recente no topo.
