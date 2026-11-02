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
        title: 'Um workspace pronto para usar',
        paragraphs: [
          'Ao abrir o Forge, você encontra Tokyo Night, arquivos à esquerda, status do Git e ações com teclas visíveis. Pressione a letra indicada ou navegue com j/k e Enter.',
          'Para editar um arquivo aberto, pressione i. Esc volta ao modo normal; Ctrl S salva. Ctrl H/J/K/L alterna os painéis. Leader Leader abre a paleta de comandos.',
        ],
      },
      {
        title: 'Instale uma vez, abra qualquer projeto',
        paragraphs: [
          'bash install.sh valida Neovim 0.11+, Git, ripgrep e Python 3.9+, instala os plugins selecionados e cria o comando forge. Sua configuração atual do Neovim e seus ajustes pessoais são preservados. Node.js, SDKs de linguagem e login de IA continuam opcionais.',
          'Use bash install.sh --local para executar direto do checkout no SSD externo. A instalação gerenciada usa um runtime enxuto e não instala dependências da página web. forge --doctor verifica requisitos; forge --update atualiza a instalação gerenciada limpa; forge --uninstall remove o launcher e preserva seus dados.',
          'Enquanto o repositório for privado, é necessário autenticar o acesso ao GitHub. Links curl anônimos do raw GitHub não funcionam. O instalador mostra como ajustar o PATH sem editar seu perfil do shell.',
        ],
      },
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
        code: 'gh repo clone marcosdanielr/forge.nvim\ncd forge.nvim\nbash install.sh\nforge .',
        paragraphs: [
          'O instalador prepara os plugins selecionados e cria ~/.local/bin/forge. Adicione ~/.local/bin ao PATH quando necessário. O launcher define NVIM_APPNAME=forge.nvim. Plugins, estado e configuração ficam separados do seu ~/.config/nvim. A primeira execução instala o gerenciador e os plugins; as próximas usam os arquivos locais.',
        ],
      },
      {
        title: 'Seus primeiros passos',
        table: {
          headers: ['Comando', 'Resultado'],
          rows: [
            ['f na tela inicial', 'Encontre e abra um arquivo do projeto.'],
            ['g na tela inicial', 'Revise, selecione e faça commit das alterações.'],
            ['a na tela inicial', 'Acompanhe agentes e revise os resultados.'],
            ['Leader Leader', 'Busque todos os comandos disponíveis.'],
            [':ForgeLanguages', 'Escolha e instale ferramentas por linguagem.'],
            [':ForgeHealth', 'Verifique dependências do editor e do núcleo de agentes.'],
          ],
        },
        note: 'Depois de instalar ferramentas de linguagem, reinicie o Forge. Não instalamos todos os runtimes automaticamente.',
      },
      {
        title: 'Abra seu projeto',
        code: 'cd /caminho/do/projeto\n/caminho/forge.nvim/bin/forge',
        paragraphs: [
          'O editor continua sendo Neovim: use :edit, :split, :terminal, macros, registros e os movimentos que você já conhece. Leader é Espaço por padrão. Altere em :ForgeLeader e reinicie.',
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
            ['Ctrl P', 'Leader f f', 'Buscar arquivos no projeto.'],
            ['Ctrl Shift F', 'Leader f g', 'Buscar texto no projeto.'],
            ['Ctrl F', 'Leader f b', 'Buscar no buffer.'],
            ['Ctrl Shift H', 'Leader f r', 'Substituir texto no projeto.'],
            ['—', 'Leader f R', 'Substituir texto no arquivo.'],
            ['F2', 'Leader c r', 'Renomear símbolo usando LSP.'],
            ['Ctrl S', ':write', 'Salvar buffer.'],
            ['Alt Shift F', 'Leader c f', 'Formatar código.'],
            ['Ctrl Shift P', 'Leader Leader', 'Abrir paleta de comandos.'],
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
            ['K / Leader c h', 'Mostrar documentação de classe, variável ou função.'],
            ['Leader c s', 'Mostrar assinatura da função.'],
            ['gi / gy', 'Ir à implementação / definição do tipo.'],
            ['gl / Leader c e', 'Ler diagnósticos da linha.'],
            [']d / [d', 'Próximo / anterior diagnóstico.'],
            ['Leader f s', 'Pesquisar símbolos do documento.'],
          ],
        },
      },
      {
        title: 'Debug e agentes',
        table: {
          headers: ['Atalho', 'Alternativa', 'Ação'],
          rows: [
            ['F5', 'Leader d c', 'Iniciar ou continuar debug.'],
            ['F9', 'Leader d b', 'Alternar breakpoint.'],
            ['F10', 'Leader d o', 'Avançar sem entrar.'],
            ['F11', 'Leader d i', 'Entrar na chamada.'],
            ['Shift F11', 'Leader d O', 'Sair da chamada.'],
            ['Shift F5', 'Leader d q', 'Encerrar debug.'],
            ['—', 'Leader a n', 'Iniciar agente Codex.'],
            ['—', 'Leader a a', 'Listar e revisar agentes.'],
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
      {
        title: 'Painéis, buffers e terminais',
        paragraphs: [
          'F1 abre um guia com seus atalhos configurados. Ctrl H/J/K/L alterna os painéis no modo normal e nos terminais do Forge; h/j/k/l continua nativo nos arquivos. Na árvore, h recolhe e l ou Enter abre. Clique para focar e dê dois cliques para ativar ações dos painéis.',
        ],
        table: {
          headers: ['Ação', 'Teclas'],
          rows: [
            ['Arquivos / Agentes / Chat', 'Ctrl B / Leader p a / Leader p c'],
            ['Próximo / anterior buffer', 'Ctrl Tab / Ctrl Shift Tab; Leader b n / Leader b p'],
            ['Terminal / novo terminal', 'Ctrl crase / Ctrl Shift crase; Leader o t / Leader o T'],
            ['Dividir / escolher terminal', 'Ctrl Shift 5 / Leader o s; Leader o o'],
            ['Revisão / debug / logs', 'Leader p r / Leader p d / Leader p l'],
            ['Configuração / painéis iniciais', 'Leader u s / Leader u L'],
          ],
        },
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
      'Execute agentes lado a lado e revise cada resultado antes de alterar seu projeto.',
    sections: [
      {
        title: 'Conecte e prepare a tarefa',
        code: ':ForgeAgentConnect\n# Selecione Codex, Claude Code ou Gemini e conclua o login.\n# Salve e faça commit ou stash das alterações.\n:ForgeAgentStart',
        paragraphs: [
          'O Forge usa sua instalação e autenticação do Codex, Claude Code ou Gemini CLI. Nenhuma chave é embutida no projeto. O comando cria uma branch e um worktree a partir do HEAD atual. Você pode iniciar várias tarefas independentes.',
        ],
        note: 'Use tarefas para pedidos pontuais ou abra o chat CLI para conversar e responder às permissões do provedor. Ambos usam worktrees isoladas e revisão explícita.',
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
          'Se o resultado da tarefa ou seu projeto mudar após a revisão, revise novamente antes de aceitar. Salve e faça commit das suas alterações antes de aplicar outra tarefa. O Forge verifica conflitos e mantém os resultados conflitantes disponíveis para inspeção.',
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
        title: 'Converse com seu CLI autenticado',
        paragraphs: [
          'Conecte sua conta e use :ForgeChatNew ou Leader a C. Escolha o provedor e dê um nome à conversa. O CLI oficial abre num terminal lateral: escreva seu pedido e use o histórico, as próximas mensagens e as permissões do próprio provedor.',
          'Salve os arquivos e faça commit ou stash antes. O chat usa uma worktree própria. Ocultar o painel mantém o processo ativo enquanto o Forge estiver aberto. Saia do CLI, selecione sua tarefa em Agentes e revise as alterações antes de aceitar.',
          'O terminal pertence à sessão atual do editor. Logs e worktrees continuam disponíveis depois de fechar; o Forge não promete reanexar um terminal antigo nem substitui a retomada nativa do provedor.',
        ],
        code: ':ForgeAgentConnect\n:ForgeChatNew\n:ForgeAgents',
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
          'O tema escolhido é aplicado e salvo. Tokyo Night é o padrão; Catppuccin, Rose Pine e o tema simples Habamax também estão disponíveis.',
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
        code: '-- ~/.config/forge.nvim/lua/user.lua\nreturn {\n  theme = "tokyonight",\n  format_on_save = true,\n  copilot = false,\n}',
        paragraphs: [
          'O diretório respeita XDG_CONFIG_HOME quando definido. Preferências escolhidas nos menus ficam em stdpath("state")/forge/preferences.json. A escolha salva de tema e plugins tem prioridade sobre os defaults pessoais.',
        ],
      },
      {
        title: 'Ícones e barra inferior',
        paragraphs: [
          'Ícones de pastas e linguagens vêm habilitados. Selecione uma Nerd Font no terminal, como MesloLGM Nerd Font Mono. Para usar texto simples, execute :ForgeIcons (Leader u i) e reinicie o Forge.',
          'A barra inferior permanece visível entre os painéis. Mostra modo, branch, erros, avisos, linguagem, codificação, fim de linha e posição do cursor. Os contadores vêm dos diagnósticos reais do buffer.',
          'No modo normal, K (Shift K) mostra informações do símbolo. gl ou Leader c e mostra erros e avisos da linha. ]d e [d navegam pelos diagnósticos. F1 lista suas teclas configuradas; a documentação de símbolos exige um LSP ativo.',
        ],
      },
      {
        title: 'Tamanho das janelas e Leader',
        paragraphs: [
          'O cabeçalho de cada painel mostra o atalho para ocultá-lo. Ctrl B alterna o Explorer; Leader p a alterna Agentes, Leader p c alterna o chat e Leader p l alterna os logs. Ctrl crase alterna os terminais.',
          'Foque uma janela com Ctrl H/J/K/L. Ctrl Shift Esquerda/Direita altera a largura; Ctrl Shift Cima/Baixo altera a altura. Leader w h/l/k/j oferece as mesmas ações; Leader w = equilibra as janelas. O mouse continua disponível para redimensionar.',
          'Leader é Espaço por padrão. :ForgeLeader ou Configurações salva outra tecla; reiniciar aplica a troca. Leader Leader abre comandos. Tab/Shift Tab alterna buffers no modo normal, como no VIMarcos, preservando o Tab de autocomplete nos terminais.',
          'Leader f f busca arquivos, Leader f g busca texto no projeto e Leader f b busca no buffer atual. :ForgeKeymaps altera essas teclas. :ForgeDiagnosticDisplay escolhe mensagens inline, expandidas na linha atual ou exibição discreta de erros.',
        ],
      },
      {
        title: 'Novos terminais, painéis e substituição',
        paragraphs: [
          'Leader o t mostra ou oculta o terminal atual. Alt Enter ou Leader o T cria outro shell; Leader o s divide e Leader o o lista as sessões. New, Split e List também ficam clicáveis no cabeçalho. Ctrl Space/Ctrl @ alterna o terminal fora do modo de inserção; o autocomplete em inserção é preservado.',
          'Leader p a alterna Agentes, Leader p c alterna chat, Leader p l alterna logs e Ctrl B alterna Explorer. Dentro do chat ou terminal, pressione Esc duas vezes antes de usar atalhos Leader. Durante a digitação, espaços e texto chegam intactos à CLI. Atalhos modificados de janela e terminal continuam disponíveis. Ocultar mantém o processo rodando.',
          'A prévia de substituição mostra Apply all. Revise os resultados e clique nessa ação ou pressione Leader f A. Abrir a prévia não altera arquivos. Stage e commit continuam como ações explícitas no Neogit; escolher um lado do conflito continua explícito no Diffview.',
        ],
      },
      {
        title: 'Atualizações reproduzíveis',
        paragraphs: [
          'O projeto inclui lazy-lock.json. Na primeira execução, o Forge copia esse lock para o estado local; atualizações feitas por :Lazy não alteram o checkout da distribuição.',
          'Mantenedores usam FORGE_UPDATE_LOCK=1 ao sincronizar dependências, revisam o lock e executam os testes antes de commitar.',
        ],
      },
      {
        title: 'Configure pelo editor',
        paragraphs: [
          'Leader u s abre Configurações. Escolha tema, teclas, linguagens, plugins, conta de IA, notificações ou layout inicial. Essas opções não exigem editar Lua.',
          'No layout inicial, habilite ou desabilite boas-vindas, árvore de arquivos e Agentes. Em terminais estreitos, os painéis continuam disponíveis por atalho.',
        ],
        code: ':ForgeSettings\n:ForgeStartupLayout',
      },
    ],
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
          'Ctrl B ou Leader f e alterna a árvore do projeto. Enter abre um arquivo; a cria, r renomeia, d solicita exclusão com confirmação. Use g? para ver atalhos. A árvore abre ao lado da tela inicial. Ctrl H/L alterna os painéis; h/j/k/l move o cursor.',
        ],
      },
      {
        title: 'Stage e commit com Neogit',
        code: ':ForgeGit',
        paragraphs: [
          'Use Tab para expandir arquivos, s para stage e u para unstage. A tecla c abre o popup de commit; c novamente abre o editor da mensagem. Revise o conteúdo staged, escreva sua mensagem de commit, salve e feche conforme as instruções do Neogit.',
          'Forge não faz commit ou push automaticamente. Hooks, assinatura e identidade seguem sua configuração Git.',
        ],
      },
      {
        title: 'Conflitos em três vias',
        code: ':ForgeConflicts',
        paragraphs: [
          'Abra o merge somente quando houver arquivos em conflito. ]x e [x navegam conflitos. Leader c o aceita ours/current; Leader c t aceita theirs/incoming; Leader c b aceita a base no conflito selecionado.',
          'Edite o resultado diretamente quando precisar combinar os lados. Salve, revise e faça stage apenas dos arquivos resolvidos. :ForgeDiff abre a revisão de alterações a qualquer momento.',
        ],
        note: 'Escolher um lado é sempre sua decisão. Nenhum conflito é resolvido automaticamente.',
      },
      {
        title: 'Buscar e substituir com opções visíveis',
        paragraphs: [
          'Ctrl Shift H ou Leader f r abre busca e substituição no projeto. Leader f R limita ao arquivo atual. Preencha Search e Replace, escolha File ou Project e ajuste Match case, Whole word e Regex.',
          'Pressione p para pré-visualizar. Isso não altera arquivos. Revise os resultados e use Apply all no cabeçalho ou Leader f A; g? mostra ajuda. Com as teclas padrão, vírgula seguida de r aplica a substituição.',
        ],
        code: ':ForgeReplace\n:ForgeBufferReplace',
      },
    ],
  },
];
