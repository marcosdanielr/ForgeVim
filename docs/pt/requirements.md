# Requisitos e critérios de aceite

Escopo: distribuição Neovim real, centrada em debug, busca, assistência de código
e agentes concorrentes sob revisão humana. Status descreve entrega, não intenção.

## Requisitos funcionais

| ID | Requisito e aceite | Status / verificação |
| --- | --- | --- |
| FR-01 | Abrir app isolado sem substituir configuração. Operadores e registros nativos funcionam. | Implementado; make smoke |
| FR-02 | Paleta pesquisável, temas e plugins sem exigir edição Lua. Escolhas persistem. | Implementado; smoke de estado/plugins |
| FR-03 | Busca por arquivo/projeto, prévia de substituição e rename semântico via LSP. | Implementado; integração e Pyright real |
| FR-04 | Autocomplete LSP, caminhos, snippets e buffer; Copilot opt-in. | Implementado; autenticação Copilot não verificada |
| FR-05 | Preservar inventário Conform do VIMarcos e instalação opt-in. | Implementado; StyLua real |
| FR-06 | Breakpoints, passos, variáveis, pilha e perfis DAP Python/Go/Node/PHP/nativo. | Perfis implementados; debugpy real; outros runtimes não verificados |
| FR-07 | Agentes concorrentes em worktrees próprios, estado e logs após fechar editor. | Implementado; testes concorrentes |
| FR-08 | Mostrar patch e exigir aceite explícito vinculado ao snapshot. Nunca commitar automaticamente. | Implementado; regressões e smoke Lua |
| FR-09 | Rejeitar/cancelar preservando recuperação. | Implementado; testes de ciclo de vida |
| FR-10 | Landing/docs responsivas, temas claro/escuro/sistema, inglês/português, GitHub e doação. | Implementado; build, tipos e QA de navegador |
| FR-11 | AGENTS.md, CLAUDE.md e skills reutilizáveis, em inglês. | Implementado; validador de skills |
| FR-12 | Fronteira versionada independente de transporte para futuro mobile. | CLI JSON implementada; app/gateway planejados |
| FR-17 | Ações configuráveis para definição, referências, hover, assinatura, tipos e diagnósticos via LSP. | Implementado; registro e Pyright real |
| FR-18 | Adicionar, substituir, inspecionar e restaurar atalhos por menu com persistência, conflitos e proteção de comandos nativos. | Implementado; smoke de atalhos |
| FR-13 | Conversa contínua, prompts interativos de permissão, dependências e aceite por hunk. | Planejado; fora do aceite inicial |
| FR-14 | Notificações opcionais/persistentes, sem polling no startup. | Implementado; smoke de notificações |
| FR-15 | Selecionar Codex, Claude Code ou Gemini e abrir login oficial. | Adapters implementados; inferência real não testada |
| FR-16 | Árvore, stage/hunk/commit e merge de três vias com decisão explícita. | Integração Neogit/Diffview/nvim-tree |

Atalhos de ações nomeadas podem ser adicionados, substituídos e restaurados pelo
menu. Definição, referências, hover, assinatura, tipos e erros entram nesse fluxo.

## Requisitos não funcionais

| ID | Critério mensurável | Evidência |
| --- | --- | --- |
| NFR-01 | Nenhum processo Python de agentes no startup ou em teclas. Plugins por evento/comando; nenhum daemon permanente. Medições informam ambiente. | Módulos e relatório de validação |
| NFR-02 | Chamadas ao núcleo usam callbacks vim.system e não bloqueiam digitação durante modelo. | Smoke assíncrono |
| NFR-03 | Bloquear patch alterado, destino sujo, base diferente ou estado reservado. | Regressões do núcleo |
| NFR-04 | Argumentos em arrays, sem interpolação shell. Somente dono encerra grupo do provider; nenhum PID recuperado é morto. | Providers/Git/worker e cancelamento |
| NFR-05 | Módulos coesos para UI, política, aplicação, persistência, Git, providers e linguagens. | Arquitetura, regras com IDs e AGENTS.md |
| NFR-06 | Astro strictest, TypeScript sem any explícito, imports ordenados, Prettier/Tailwind e cn. | check, lint e format:check |
| NFR-07 | Lockfiles de plugins/npm e CI. | Arquivos versionados |
| NFR-08 | HTML semântico, skip link, teclado, foco, feedback de cópia, telas estreitas e movimento reduzido. | QA e revisão dos componentes |
| NFR-09 | Site/repo privados, sem credenciais embutidas, trackers/fontes remotas ou início automático de modelos. | Código e configurações |
| NFR-10 | Suporte inicial macOS/Linux, Neovim 0.11+, Python 3.9+. Windows/mobile não são anunciados. | CI e testes locais macOS |
| NFR-11 | Preservar branches/worktrees/logs em rejeição, cancelamento, falha e interrupção; erros acionáveis. | Testes e contrato CLI |

## Mudanças

Toda capacidade nova atualiza requisito, regra, módulo responsável e prova de
aceite no mesmo trabalho. Identifique integrações não verificadas. CLI versionada
não significa app mobile entregue. UI de agente inicial não significa chat contínuo.
