import type { DocPage } from '@/lib/docs-types';

export const docsPt: readonly DocPage[] = [
  {
    slug: '',
    navigationTitle: 'Primeiros passos',
    title: 'Comece pelo essencial.',
    description:
      'Instale o Forge sem substituir sua configuração atual. Abra o editor, escolha suas ferramentas e comece a trabalhar.',
    sections: [
      {
        title: 'Antes de começar',
        bullets: [
          'macOS ou Linux com Neovim 0.11 ou superior.',
          'Git, ripgrep e Python 3.9 ou superior disponíveis no PATH.',
          'Node.js 22 ou superior para Copilot e ferramentas JavaScript.',
          'Go, Rust, PHP ou Flutter instalados quando o seu projeto precisar.',
        ],
        note: 'O repositório é privado nesta fase. Faça login no GitHub com uma conta autorizada antes de clonar.',
      },
      {
        title: 'Instalação isolada',
        code: 'git clone https://github.com/marcosdanielr/forge.nvim.git\ncd forge.nvim\n./bin/forge',
        paragraphs: [
          'O launcher define NVIM_APPNAME=forge.nvim. Plugins, estado e configuração ficam separados do seu ~/.config/nvim. A primeira execução instala o gerenciador e os plugins; as próximas usam os arquivos locais.',
        ],
      },
      {
        title: 'Os primeiros três comandos',
        table: {
          headers: ['Comando', 'Resultado'],
          rows: [
            [':Forge', 'Paleta pesquisável de comandos.'],
            [':ForgeLanguages', 'Escolha e instale ferramentas por linguagem.'],
            [':ForgeHealth', 'Verifique dependências do editor e do núcleo de agentes.'],
          ],
        },
        note: 'Depois de instalar ferramentas de linguagem, reinicie o Forge. Não instalamos todos os runtimes automaticamente.',
      },
      {
        title: 'Abra seu projeto',
        code: 'cd /caminho/do/projeto\n/caminho/forge.nvim/bin/forge .',
        paragraphs: [
          'O editor continua sendo Neovim: use :edit, :split, :terminal, macros, registros e os movimentos que você já conhece. A tecla líder é Espaço.',
        ],
      },
    ],
  },
  {
    slug: 'keymaps',
    navigationTitle: 'Atalhos',
    title: 'Memória muscular preservada.',
    description:
      'Atalhos familiares do VS Code, com alternativas confiáveis no terminal. Movimentos e comandos do Neovim continuam disponíveis.',
    sections: [
      {
        title: 'Navegação e edição',
        table: {
          headers: ['Atalho', 'Alternativa', 'Ação'],
          rows: [
            ['Ctrl P', 'Espaço f f', 'Buscar arquivos no projeto.'],
            ['Ctrl Shift F', 'Espaço f g', 'Buscar texto no projeto.'],
            ['Ctrl F', 'Espaço f b', 'Buscar no buffer.'],
            ['Ctrl Shift H', 'Espaço f r', 'Substituir texto no projeto.'],
            ['—', 'Espaço f R', 'Substituir texto no arquivo.'],
            ['F2', 'Espaço c r', 'Renomear símbolo usando LSP.'],
            ['Ctrl S', ':write', 'Salvar buffer.'],
            ['Alt Shift F', 'Espaço c f', 'Formatar código.'],
            ['Ctrl Shift P', 'Espaço Espaço', 'Abrir paleta de comandos.'],
            ['Ctrl Space', '—', 'Abrir sugestões de autocomplete.'],
          ],
        },
      },
      {
        title: 'Entenda o código pelo teclado',
        table: {
          headers: ['Atalho', 'Ação'],
          rows: [
            ['gd / F12', 'Ir à definição, inclusive em outro arquivo.'],
            ['grr / Shift F12', 'Encontrar referências.'],
            ['K / Espaço c h', 'Mostrar documentação de classe, variável ou função.'],
            ['Espaço c s', 'Mostrar assinatura da função.'],
            ['gi / gy', 'Ir à implementação / definição do tipo.'],
            ['gl / Espaço c e', 'Ler diagnósticos da linha.'],
            [']d / [d', 'Próximo / anterior diagnóstico.'],
            ['Espaço f s', 'Pesquisar símbolos do documento.'],
          ],
        },
      },
      {
        title: 'Debug e agentes',
        table: {
          headers: ['Atalho', 'Alternativa', 'Ação'],
          rows: [
            ['F5', 'Espaço d c', 'Iniciar ou continuar debug.'],
            ['F9', 'Espaço d b', 'Alternar breakpoint.'],
            ['F10', 'Espaço d o', 'Avançar sem entrar.'],
            ['F11', 'Espaço d i', 'Entrar na chamada.'],
            ['Shift F11', 'Espaço d O', 'Sair da chamada.'],
            ['Shift F5', 'Espaço d q', 'Encerrar debug.'],
            ['—', 'Espaço a n', 'Iniciar agente Codex.'],
            ['—', 'Espaço a a', 'Listar e revisar agentes.'],
          ],
        },
      },
      {
        title: 'Personalize sem editar Lua',
        code: ':ForgeKeymaps',
        paragraphs: [
          'Escolha uma ação pelo nome, veja os atalhos atuais e selecione adicionar, substituir ou restaurar padrões. Digite combinações como <leader>xf ou <F6>. As mudanças são aplicadas na hora e salvas.',
          'O menu configura ações em modo normal. Conflitos com outros mapeamentos são sinalizados. Movimentos de uma tecla e comandos Ctrl W são protegidos.',
        ],
      },
      {
        title: 'Limites do terminal',
        paragraphs: [
          'Alguns terminais não distinguem Ctrl Shift F de Ctrl F, ou capturam Ctrl S. Terminais com protocolo de teclado estendido oferecem melhor suporte. Use os atalhos com líder quando necessário.',
          'Para renomear símbolos, prefira F2 com um LSP ativo. Substituição textual usa grug-far e exige revisar a prévia antes de executar a operação. Não há multicursor próprio nesta versão.',
        ],
        note: 'Os atalhos com Ctrl e função são mapeados em modo normal. Ctrl S também funciona nos modos de inserção e visual. Ctrl W continua controlando janelas.',
      },
    ],
  },
  {
    slug: 'languages',
    navigationTitle: 'Linguagens e debug',
    title: 'Escolha uma linguagem. Mantenha o resto leve.',
    description:
      'Ative somente SDK, servidor, formatador e debugger necessários ao projeto. Menu guiado torna configuração simples.',
    source: 'languages',
    sections: [],
  },
  {
    slug: 'agents',
    navigationTitle: 'Agentes e revisão',
    title: 'Delegue. Revise. Decida.',
    description:
      'Agentes concorrentes em worktrees separados. O aceite fica vinculado ao conteúdo exato que você revisou.',
    sections: [
      {
        title: 'Conecte e prepare a tarefa',
        code: ':ForgeAgentConnect\n# Selecione Codex, Claude Code ou Gemini e conclua o login.\n# Salve e faça commit ou stash das alterações.\n:ForgeAgentStart',
        paragraphs: [
          'O Forge usa sua instalação e autenticação do Codex, Claude Code ou Gemini CLI. Nenhuma chave é embutida no projeto. O comando cria uma branch e um worktree a partir do HEAD atual. Você pode iniciar várias tarefas independentes.',
        ],
        note: 'Esta versão executa tarefas não interativas. Acompanhamento, logs e cancelamento estão disponíveis; conversa contínua e aprovação interativa de ferramentas ficam para a próxima etapa.',
      },
      {
        title: 'Revise o resultado',
        code: ':ForgeAgents',
        bullets: [
          'Selecione uma tarefa concluída e abra “Review changes”.',
          'Leia o patch no buffer de diff. Ele inclui arquivos novos e alterações binárias.',
          'Pressione a e confirme para aplicar o patch inteiro. As mudanças ficam sem commit.',
          'Pressione r para rejeitar. O worktree e os logs são preservados.',
          'Pressione q para fechar a revisão sem decidir.',
        ],
        paragraphs: [
          'O hash SHA-256 identifica o snapshot revisado. O aceite falha se o agente alterou o resultado, se o checkout ficou sujo ou se o HEAD mudou após a revisão. Dois agentes sobre a mesma base podem executar em paralelo; depois de aplicar e commitar um deles, revise os resultados restantes contra o destino atual. Patches independentes podem aplicar sem mudanças; patches conflitantes continuam bloqueados.',
        ],
      },
      {
        title: 'Limites claros',
        paragraphs: [
          'Worktrees isolam alterações, não permissões de segurança. O Codex recebe sandbox workspace-write e não usa flags de bypass. Providers locais personalizados devem ser tratados como código confiável.',
          'O cancelamento é feito pelo worker que iniciou o processo. O estado fica em .forge, excluído localmente do Git. Prompts e logs podem conter dados do projeto; não compartilhe essa pasta inadvertidamente.',
          'O worker continua rodando se você fechar o Neovim. Reabra o projeto para consultar tarefas. Após queda do worker, um heartbeat expirado marca a tarefa como interrompida sem matar processos por um PID antigo.',
        ],
      },
      {
        title: 'Notificações sob seu controle',
        code: ':ForgeNotifications',
        paragraphs: [
          'Ative ou desative notificações de conclusão, falha, cancelamento e interrupção. A preferência fica salva. O monitoramento começa ao iniciar uma tarefa ou abrir a lista de agentes, e termina quando as tarefas acompanhadas encerram.',
          'Notificações aparecem no Neovim, sem conteúdo do prompt. Com o editor fechado, os agentes continuam, mas notificações de sistema e push mobile ainda não estão implementadas.',
        ],
      },
      {
        title: 'CLI independente do editor',
        code: './bin/forge-agents --root /seu/projeto list\n./bin/forge-agents --root /seu/projeto events --after 0',
        paragraphs: [
          'A saída é JSON com versão explícita. O contrato permite um futuro gateway mobile, mas autenticação remota, transporte HTTP e o app ainda não estão implementados.',
        ],
      },
    ],
  },
  {
    slug: 'configuration',
    navigationTitle: 'Configuração',
    title: 'Seu editor, sem cerimônia.',
    description: 'Escolhas simples para o dia a dia. Lua disponível quando você precisar ir além.',
    sections: [
      {
        title: 'Temas e plugins',
        code: ':ForgeThemes\n:ForgePlugins',
        paragraphs: [
          'O tema escolhido é aplicado e salvo. Habamax mantém a aparência inicial próxima do Neovim; Tokyo Night, Catppuccin e Rose Pine também estão disponíveis.',
          'O menu de plugins permite alternar extras ou adicionar owner/repository. Reinicie o Forge para instalar ou descarregar plugins. :Lazy mostra versões e progresso. Plugins adicionados são código executável: escolha repositórios confiáveis.',
        ],
      },
      {
        title: 'Autocomplete e Copilot',
        paragraphs: [
          'blink.cmp oferece autocomplete de LSP, caminhos, snippets e palavras do buffer. Copilot é opcional e aparece no menu de plugins.',
          'Depois de habilitar Copilot e reiniciar, execute :Copilot auth. Use Alt L para aceitar uma sugestão inline. Enter aceita sugestões do menu LSP. A tecla Tab continua disponível para snippets e indentação.',
        ],
        note: 'Copilot e agentes são integrações separadas. Habilitar autocomplete não inicia tarefas Codex.',
      },
      {
        title: 'Configuração pessoal',
        code: '-- ~/.config/forge.nvim/lua/user.lua\nreturn {\n  theme = "habamax",\n  format_on_save = true,\n  copilot = false,\n}',
        paragraphs: [
          'O diretório respeita XDG_CONFIG_HOME quando definido. Preferências escolhidas nos menus ficam em stdpath("state")/forge/preferences.json. A escolha salva de tema e plugins tem prioridade sobre os defaults pessoais.',
        ],
      },
      {
        title: 'Atualizações reproduzíveis',
        paragraphs: [
          'O projeto inclui lazy-lock.json. Na primeira execução, o Forge copia esse lock para o estado local; atualizações feitas por :Lazy não alteram o checkout da distribuição.',
          'Mantenedores usam FORGE_UPDATE_LOCK=1 ao sincronizar dependências, revisam o lock e executam os testes antes de commitar.',
        ],
      },
    ],
  },
  {
    slug: 'architecture',
    navigationTitle: 'Arquitetura',
    title: 'Pequeno onde importa.',
    description:
      'Módulos com responsabilidade clara. Sem renderer próprio, daemon permanente ou linguagem adicional sem evidência.',
    sections: [
      {
        title: 'Fronteiras do monorepo',
        table: {
          headers: ['Diretório', 'Responsabilidade'],
          rows: [
            ['apps/nvim', 'Editor Lua, comandos, features e perfis de linguagem.'],
            ['packages/agent-core', 'Ciclo de vida dos agentes, Git, SQLite e processos.'],
            ['packages/protocol', 'Contrato JSON versionado para clientes.'],
            ['apps/web', 'Apresentação e documentação em Astro.'],
            ['.agents/skills', 'Workflows para contribuir no editor, núcleo e site.'],
          ],
        },
      },
      {
        title: 'Por que Python nos agentes?',
        paragraphs: [
          'Lua executa o editor. Git, ripgrep, LSPs e DAPs executam o trabalho pesado em processos próprios. Python coordena esse I/O sob demanda usando a biblioteca padrão.',
          'Chamadas do editor são assíncronas. Um worker existe apenas durante uma tarefa. Rust pode substituir uma fronteira específica no futuro se medições mostrarem necessidade. Não há promessa de performance sem benchmark.',
        ],
      },
      {
        title: 'Trabalhe no projeto',
        code: 'make test\nmake smoke\nnpm ci\nnpm run check\nnpm run lint\nnpm run format:check\nnpm run build',
        paragraphs: [
          'Leia AGENTS.md e CLAUDE.md antes de contribuir. Commits seguem Conventional Commits, em inglês e com escopo pequeno. TypeScript usa configuração strictest e proíbe any explícito. Importações e classes Tailwind têm ordenação automática.',
          'Testes locais de agentes usam providers falsos e não consomem modelos pagos. Testes de plumbing não provam autenticação do Copilot nem funcionamento de todos os adaptadores em projetos reais.',
        ],
      },
    ],
  },
  {
    slug: 'business-rules',
    navigationTitle: 'Regras de negócio',
    source: 'business-rules',
    title: 'Regras explícitas. Comportamento previsível.',
    description:
      'Contrato técnico com identificadores, responsáveis e evidências. Especificação com identificadores estáveis, responsáveis e evidências, traduzida da fonte principal em inglês.',
    sections: [],
  },
  {
    slug: 'requirements',
    navigationTitle: 'Requisitos',
    source: 'requirements',
    title: 'O que entregamos. Como provar.',
    description:
      'Requisitos funcionais e não funcionais, critérios de aceite e limitações. Critérios verificáveis e limitações, mantidos junto do código.',
    sections: [],
  },
  {
    slug: 'git',
    navigationTitle: 'Git e arquivos',
    title: 'Revise. Resolva. Faça commit.',
    description:
      'Neogit, Diffview e nvim-tree: interfaces conhecidas, dentro do Neovim. Sem automatizar suas decisões de Git.',
    sections: [
      {
        title: 'Árvore de arquivos',
        code: ':ForgeTree',
        paragraphs: [
          'Ctrl B ou Espaço f e alterna a árvore do projeto. Enter abre um arquivo; a cria, r renomeia, d solicita exclusão com confirmação. Use g? para ver atalhos. A árvore não abre permanentemente no startup.',
        ],
      },
      {
        title: 'Stage e commit com Neogit',
        code: ':ForgeGit',
        paragraphs: [
          'Use Tab para expandir arquivos, s para stage e u para unstage. A tecla c abre o popup de commit; c novamente abre o editor da mensagem. Revise o conteúdo staged, escreva um Conventional Commit curto em inglês, salve e feche conforme as instruções do Neogit.',
          'Forge não faz commit ou push automaticamente. Hooks, assinatura e identidade seguem sua configuração Git.',
        ],
      },
      {
        title: 'Conflitos em três vias',
        code: ':ForgeConflicts',
        paragraphs: [
          'Abra o merge somente quando houver arquivos em conflito. ]x e [x navegam conflitos. Espaço c o aceita ours/current; Espaço c t aceita theirs/incoming; Espaço c b aceita a base no conflito selecionado.',
          'Edite o resultado diretamente quando precisar combinar os lados. Salve, revise e faça stage apenas dos arquivos resolvidos. :ForgeDiff abre a revisão de alterações a qualquer momento.',
        ],
        note: 'Escolher um lado é sempre sua decisão. Nenhum conflito é resolvido automaticamente.',
      },
    ],
  },
];
