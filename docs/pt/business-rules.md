# Regras de negócio

Contrato de domínio traduzido da especificação em inglês. Cada regra tem um
identificador estável. Altere documentação, módulo responsável e prova de aceite
juntos; UI e transporte não redefinem decisões do domínio.

## Ciclo de vida dos agentes

| ID | Regra | Responsável e prova |
| --- | --- | --- |
| BR-AG-01 | Toda tarefa tem uma instrução não vazia e provider confiável selecionado explicitamente. | policy.require_prompt; providers.command; validação CLI |
| BR-AG-02 | Iniciar exige checkout limpo. Cada tarefa parte do HEAD commitado, em branch e worktree próprios. | AgentService.start; testes de origem suja e concorrência |
| BR-AG-03 | Somente ready, failed e reviewing permitem revisão. Falhas podem conter resultado parcial. Tarefas ativas ou interrompidas não são consideradas concluídas. | policy.require_finished; regressões de tarefa ativa/worker perdido |
| BR-AG-04 | Aceite exige o SHA-256 do snapshot atualmente revisado. Aplica o patch inteiro uma única vez. | policy.require_review; testes de hash incorreto e aceite duplicado |
| BR-AG-05 | Worktree e bytes congelados precisam manter o hash. Destino limpo, HEAD igual ao capturado na revisão e git apply --check sem conflito são obrigatórios. | AgentService.accept; testes de destino alterado, base alterada e patch adulterado |
| BR-AG-06 | Aplicar inclui arquivos novos, binários, exclusões e commits do agente relativos à base. Nunca faz commit ou push. | git.snapshot; git.apply; testes de binário/novo/exclusão |
| BR-AG-07 | Rejeição é decisão sobre tarefa concluída. Preserva branch, worktree e logs; não desfaz alterações da origem. | policy.require_rejectable; teste de preservação |
| BR-AG-08 | Cancelamento usa marcador local. Somente o worker dono sinaliza seu grupo de processos. Nunca mata PID recuperado sem verificar identidade. | worker.terminate; teste de cancelamento |
| BR-AG-09 | Heartbeat com mais de 30 segundos marca tarefa ativa como interrupted. Isso não prova término do processo e não libera revisão. | AgentService.tasks; regressão de worker perdido |
| BR-AG-10 | Estado reservado .forge e .git não pode entrar no patch aplicado. | git.snapshot; teste de estado reservado |
| BR-AG-11 | Buffers não salvos bloqueiam início e aceite porque Git não enxerga seu conteúdo. | features.agents; teste de integração do editor |
| BR-AG-12 | Notificações são opcionais e persistentes. Acompanham tarefas iniciadas/inspecionadas pelo usuário; avisam uma vez por conclusão, falha, cancelamento ou interrupção, sem incluir o prompt. Desativar ou concluir tudo encerra polling. | features.agents.notifications; smoke de notificações |
| BR-AG-13 | Providers suportados: Codex, Claude Code e Gemini. Login pertence à CLI oficial; Forge não armazena tokens nem habilita bypass geral de permissões. | providers; features.agents.providers; testes de contrato |

Fluxo: queued para running; depois ready/failed, reviewing e accepted/rejected.
Cancelamento passa por cancelling e cancelled. Heartbeat expirado produz
interrupted. Um worker ainda vivo pode atualizar seu heartbeat e informar seu
resultado final posteriormente. Não revise trabalho interrompido como concluído.

Aceitar suja o checkout. Após commitar um resultado, revise tarefas irmãs contra o destino atual.
Patches independentes podem aplicar sem mudanças; patches incompatíveis continuam bloqueados. Rebase automático e aceite por hunk não existem nesta versão. Fechar o
editor encerra notificações, mas não os workers.

Worktrees isolam alterações, não permissões. Codex usa workspace-write; Claude
acceptEdits e Gemini auto_edit preservam outras verificações. Comando local
personalizado é código confiável. Abrir editor/site nunca inicia agente sozinho.

## Editor

| ID | Regra | Responsável |
| --- | --- | --- |
| BR-ED-01 | Preserve modos, movimentos, registros, janelas e buffers. Ctrl W continua nativo. | core.options; core.keymaps |
| BR-ED-02 | Atalhos sensíveis ao terminal têm alternativas com líder. | core.actions |
| BR-ED-03 | Instalação de ferramentas é opt-in. Ative apenas servidores disponíveis no PATH. | languages.tools; languages.lsp |
| BR-ED-04 | Python executa isort e depois Black. Alternativas web/PHP param no primeiro formatador disponível. | languages.formatting |
| BR-ED-05 | Tema aplica e persiste. Preferências do menu prevalecem sobre defaults. Plugins exigem reinício para instalação/descarregamento. | core.state; features.themes; features.plugins |
| BR-ED-06 | Copilot inicia desabilitado. Sua autenticação é separada dos agentes. | plugins.completion |
| BR-ED-07 | launch.json exige comando explícito em projeto confiável. | languages.debug |
| BR-ED-08 | Chamadas ao núcleo são assíncronas; Python não atende teclas. | features.agents.client |
| BR-ED-09 | Atalhos usam IDs estáveis, aplicam e persistem sem Lua. Detecte conflitos e preserve movimentos de uma tecla e Ctrl W. | features.shortcuts; core.keymaps |
| BR-ED-10 | Nerd Fonts são opcionais. Sua ausência não bloqueia edição ou navegação. | core.config; plugins |

Definição, referências, implementação, tipo, hover, assinatura e diagnósticos usam
ações nomeadas e configuráveis. Precisam de LSP que suporte a capacidade pedida.

## Site

| ID | Regra | Responsável |
| --- | --- | --- |
| BR-WEB-01 | Tema segue sistema por padrão. Escolha manual persiste; falha de storage não quebra página. | scripts/theme.ts; prepaint |
| BR-WEB-02 | Demonstrações são identificadas e não executam tarefas reais nem anunciam roadmap como entregue. | componentes home; conteúdo docs |
| BR-WEB-03 | GitHub e Buy Me a Coffee têm uma fonte tipada única de configuração. | lib/site.ts |
| BR-WEB-04 | Layout suporta telas estreitas, teclado, foco visível e preferência de movimento reduzido. | CSS e scripts |
| BR-WEB-05 | Site/repositório continuam privados até decisão explícita do proprietário. | publicação e configuração GitHub |

Site/documentação têm inglês estático como padrão e português em /pt. Preferência
manual de idioma prevalece; sem escolha, navegador em português seleciona /pt.
Código, skills e instruções de contribuição permanecem em inglês.

## Git

| ID | Regra |
| --- | --- |
| BR-GIT-01 | Stage, commit, push e escolha de lado do conflito exigem ação do usuário. Preserve hooks, assinatura e identidade. |
| BR-GIT-02 | Resultado do merge permanece editável. Escolher ours, theirs ou base afeta somente o conflito selecionado. |
| BR-GIT-03 | Resultado aceito de agente fica sem commit até revisão e stage do usuário. |
| BR-GIT-04 | Árvore é opcional e abre sob demanda. Ações destrutivas usam confirmação do plugin. |
