export const agentWorkflow = {
  en: {
    steps: [
      {
        title: 'Give it a focused task.',
        description:
          'Use Codex, Claude Code, or Gemini with your own account. Open a chat for follow-ups, or start a task while you keep coding.',
        command: ':ForgeChatNew',
      },
      {
        title: 'Keep your workspace yours.',
        description:
          'Each task works in a separate Git worktree. Follow its state in Agents and inspect what it did. Nothing is silently merged.',
        command: ':ForgeAgents',
      },
      {
        title: 'Read the diff. Then decide.',
        description:
          'Review the actual patch, accept or reject it, and commit when you are satisfied. Your review is the handoff back to your project.',
        command: 'Review changes',
      },
    ],
    caption:
      'Actual ForgeVim review screen. A local example task changes a retry setting; no live model session is implied.',
    alt: 'ForgeVim showing an actual review patch with added and removed code.',
  },
  pt: {
    steps: [
      {
        title: 'Peça uma tarefa específica.',
        description:
          'Use Codex, Claude Code ou Gemini com sua conta. Abra um chat para conversar ou inicie uma tarefa enquanto continua programando.',
        command: ':ForgeChatNew',
      },
      {
        title: 'Seu projeto continua seu.',
        description:
          'Cada tarefa trabalha em uma cópia Git separada. Acompanhe o estado em Agentes e veja o que foi feito. Nada é mesclado silenciosamente.',
        command: ':ForgeAgents',
      },
      {
        title: 'Leia o diff. Depois decida.',
        description:
          'Confira a alteração real, aceite ou rejeite e faça commit quando estiver satisfeito. Sua revisão traz o resultado de volta ao projeto.',
        command: 'Review changes',
      },
    ],
    caption:
      'Tela real de revisão do ForgeVim. Uma tarefa local de exemplo altera tentativas de uma requisição; não representa uma sessão real de modelo.',
    alt: 'ForgeVim mostrando um patch real, com código adicionado e removido.',
  },
} as const;
