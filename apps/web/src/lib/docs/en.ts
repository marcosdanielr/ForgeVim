import type { DocPage } from '@/lib/docs-types';

export const docsEn: readonly DocPage[] = [
  {
    slug: '',
    navigationTitle: 'Getting started',
    title: 'Start with the essentials.',
    description:
      'Install Forge without replacing your current configuration. Open the editor, choose your tools, and get to work.',
    sections: [
      {
        title: 'Before you begin',
        bullets: [
          'macOS or Linux with Neovim 0.11 or later.',
          'Git, ripgrep, and Python 3.9 or later on PATH.',
          'Node.js 22+ for Copilot and JavaScript tooling.',
          'Install the Go, Rust, PHP, or Flutter runtime when your project needs it.',
        ],
        note: 'The repository is private during initial development. Clone with an authorized GitHub account.',
      },
      {
        title: 'An isolated installation',
        paragraphs: [
          'The launcher sets NVIM_APPNAME=forge.nvim. Plugins, state, and personal settings are separate from ~/.config/nvim. First launch installs the plugin manager and enabled plugins. Following launches use local files.',
        ],
        code: 'git clone https://github.com/marcosdanielr/forge.nvim.git\ncd forge.nvim\n./bin/forge',
      },
      {
        title: 'Your first three commands',
        table: {
          headers: ['Command', 'Result'],
          rows: [
            [':Forge', 'A searchable command palette.'],
            [':ForgeLanguages', 'Choose and install tools by language.'],
            [':ForgeHealth', 'Check editor and agent prerequisites.'],
          ],
        },
        note: 'Restart Forge after installing language tools. Toolchains are never all installed automatically.',
      },
      {
        title: 'Open your project',
        paragraphs: [
          'This is still Neovim. Use :edit, :split, :terminal, macros, registers, and your familiar motions. The leader key is Space.',
        ],
        code: 'cd /path/to/project\n/path/to/forge.nvim/bin/forge .',
      },
    ],
  },
  {
    slug: 'keymaps',
    navigationTitle: 'Shortcuts',
    title: 'Keep your muscle memory.',
    description:
      'VS Code-inspired shortcuts, with reliable terminal alternatives. Native Neovim motions and commands stay available.',
    sections: [
      {
        title: 'Navigation and editing',
        table: {
          headers: ['Shortcut', 'Alternative', 'Action'],
          rows: [
            ['Ctrl P', 'Space f f', 'Find project files.'],
            ['Ctrl Shift F', 'Space f g', 'Search project text.'],
            ['Ctrl F', 'Space f b', 'Search this buffer.'],
            ['Ctrl Shift H', 'Space f r', 'Replace project text.'],
            ['—', 'Space f R', 'Replace current-file text.'],
            ['F2', 'Space c r', 'Rename an LSP symbol.'],
            ['Ctrl S', ':write', 'Save buffer.'],
            ['Alt Shift F', 'Space c f', 'Format code.'],
            ['Ctrl Shift P', 'Space Space', 'Open command palette.'],
            ['Ctrl Space', '—', 'Show code completion.'],
            ['Ctrl B', 'Space f e', 'Toggle file tree.'],
          ],
        },
      },
      {
        title: 'Code understanding',
        table: {
          headers: ['Shortcut', 'Action'],
          rows: [
            ['gd / F12', 'Go to definition, including another file.'],
            ['grr / Shift F12', 'Find symbol references.'],
            ['K / Space c h', 'Show class, variable, or function documentation.'],
            ['Space c s', 'Show function signature.'],
            ['gi / gy', 'Go to implementation / type definition.'],
            ['gl / Space c e', 'Read line diagnostics.'],
            [']d / [d', 'Go to next / previous diagnostic.'],
            ['Space f s', 'Find document symbols.'],
          ],
        },
      },
      {
        title: 'Debugging and agents',
        table: {
          headers: ['Shortcut', 'Alternative', 'Action'],
          rows: [
            ['F5', 'Space d c', 'Start or continue debugging.'],
            ['F9', 'Space d b', 'Toggle breakpoint.'],
            ['F10', 'Space d o', 'Step over.'],
            ['F11', 'Space d i', 'Step into.'],
            ['Shift F11', 'Space d O', 'Step out.'],
            ['Shift F5', 'Space d q', 'Stop debugging.'],
            ['—', 'Space a n', 'Start agent task.'],
            ['—', 'Space a a', 'List and review agents.'],
            ['—', 'Space a c', 'Connect provider account.'],
          ],
        },
      },
      {
        title: 'Customize without editing Lua',
        paragraphs: [
          'Choose a named action, inspect its current shortcuts, and select add, replace, or restore defaults. Enter a combination such as <leader>xf or <F6>. Changes apply immediately and persist.',
          'The menu configures normal-mode actions. Conflicting mappings are reported. Native single-key motions and Ctrl W commands are protected. LSP actions are in the same menu.',
        ],
        code: ':ForgeKeymaps',
      },
      {
        title: 'Terminal limits',
        paragraphs: [
          'Some terminals cannot distinguish Ctrl Shift F from Ctrl F, or capture Ctrl S. Use leader alternatives when necessary. Ctrl S also works in insert and visual modes.',
          'LSP navigation and hover require a server supporting the relevant capability. Text replacement opens grug-far with a preview; Forge does not provide a custom multicursor implementation.',
        ],
      },
    ],
  },
  {
    slug: 'languages',
    navigationTitle: 'Languages and debug',
    title: 'Choose a language. Keep the rest quiet.',
    description:
      'Enable only the SDK, language server, formatter, and debugger your project needs. A guided menu keeps setup clear.',
    source: 'languages',
    sections: [],
  },
  {
    slug: 'agents',
    navigationTitle: 'Agents and review',
    title: 'Delegate. Review. Decide.',
    description:
      'Concurrent agents in independent worktrees. Acceptance is bound to the exact content you reviewed.',
    sections: [
      {
        title: 'Connect your account',
        paragraphs: [
          'Select ChatGPT/Codex, Claude Code, or Gemini. Forge opens the official CLI login flow in a Neovim terminal. Complete authentication yourself. Your plan, quota, and model remain with the provider.',
          'Save buffers and commit or stash changes first. Each task starts at the current HEAD in its own branch and worktree. Start several independent tasks when useful.',
        ],
        code: ':ForgeAgentConnect\n:ForgeAgentStart',
        note: 'Initial support is one-shot tasks, status, raw logs, review, and cancellation. Continuous conversation and interactive provider permission prompts are future work.',
      },
      {
        title: 'Review the result',
        paragraphs: [
          'SHA-256 identifies the review snapshot. Acceptance fails if its bytes change, the target becomes dirty, or HEAD changes after review. After accepting and committing one task, review sibling results against the current target. Independent patches can apply unchanged; conflicting patches remain blocked.',
        ],
        code: ':ForgeAgents',
        bullets: [
          'Select a finished task and open Review changes.',
          'Read the native diff buffer. New files and binary patches are included.',
          'Press a and confirm to apply the entire reviewed patch. Changes remain uncommitted.',
          'Press r to reject while preserving the worktree and logs.',
          'Press q to close without deciding.',
        ],
      },
      {
        title: 'Notifications you control',
        paragraphs: [
          'Enable or disable notifications for ready, failed, cancelled, and interrupted tasks. The choice persists. Watching begins when you start a task or inspect the agent list, and stops after watched tasks finish.',
          'Notifications stay inside Neovim without exposing prompt contents. Workers keep running when the editor closes; system notifications while closed and mobile push are not implemented.',
        ],
        code: ':ForgeNotifications',
      },
      {
        title: 'Clear boundaries',
        paragraphs: [
          'Worktrees isolate changes, not permissions. Codex uses workspace-write, Claude acceptEdits, and Gemini auto_edit. No blanket permission bypass is added; other provider permission checks remain. Headless operations requiring approval may be denied.',
          'Prompts, state, and logs stay in the project-local .forge directory, excluded from Git. A stale worker heartbeat marks a task interrupted without killing an unverified PID. Interrupted tasks cannot be reviewed as finished.',
        ],
      },
      {
        title: 'An editor-independent CLI',
        paragraphs: [
          'The CLI returns a versioned JSON envelope. A future mobile gateway can wrap this boundary. Remote authentication, HTTP transport, and a mobile application are not implemented.',
        ],
        code: './bin/forge-agents --root /your/project list\n./bin/forge-agents --root /your/project events --after 0',
      },
    ],
  },
  {
    slug: 'configuration',
    navigationTitle: 'Configuration',
    title: 'Your editor, less ceremony.',
    description: 'Simple daily choices. Lua remains available when you need more control.',
    sections: [
      {
        title: 'Themes, plugins, and shortcuts',
        paragraphs: [
          'Theme selection applies and persists. Habamax keeps the initial look close to stock Neovim; Tokyo Night, Catppuccin, and Rose Pine are available too.',
          'Toggle optional plugins or add a trusted GitHub owner/repository. Restart to install or unload choices; :Lazy shows versions and progress. Plugins execute code, so choose repositories you trust.',
        ],
        code: ':ForgeThemes\n:ForgePlugins\n:ForgeKeymaps',
      },
      {
        title: 'Completion and Copilot',
        paragraphs: [
          'blink.cmp provides LSP, path, snippet, and buffer completion. Copilot is optional. Enable it in the plugin menu, restart, then run :Copilot auth.',
          'Alt L accepts inline Copilot suggestions. Enter accepts a completion-menu item. Tab remains available for snippets and indentation. Copilot completion and agent tasks have separate authentication.',
        ],
      },
      {
        title: 'Personal settings',
        paragraphs: [
          'The config path respects XDG_CONFIG_HOME. Menu preferences live under stdpath("state")/forge/preferences.json and override user defaults. Nerd Fonts are optional; enable nerd_fonts only after selecting a patched font in your terminal.',
        ],
        code: '-- ~/.config/forge.nvim/lua/user.lua\nreturn {\n  theme = "habamax",\n  format_on_save = true,\n  copilot = false,\n  notifications = true,\n  nerd_fonts = false,\n}',
      },
      {
        title: 'Reproducible updates',
        paragraphs: [
          'The bundled lazy-lock.json seeds a local state copy on first launch. :Lazy updates that user copy without changing the distribution checkout.',
          'Maintainers use FORGE_UPDATE_LOCK=1 when intentionally syncing dependencies, review the lock, and run checks before committing.',
        ],
      },
    ],
  },
  {
    slug: 'architecture',
    navigationTitle: 'Architecture',
    title: 'Small where it matters.',
    description:
      'Cohesive modules. No custom renderer, permanent daemon, or extra implementation language without evidence.',
    sections: [
      {
        title: 'Monorepo boundaries',
        table: {
          headers: ['Directory', 'Responsibility'],
          rows: [
            ['apps/nvim', 'Lua editor, commands, features, and language profiles.'],
            ['packages/agent-core', 'Agent policy, lifecycle, Git, SQLite, and processes.'],
            ['packages/protocol', 'Versioned JSON boundary.'],
            ['apps/web', 'Astro presentation and bilingual documentation.'],
            ['.agents/skills', 'Scoped editor, core, and site workflows.'],
          ],
        },
      },
      {
        title: 'Why Python for agents?',
        paragraphs: [
          'Lua owns editing. Git, ripgrep, language servers, and debug adapters perform heavy work in native processes. Python coordinates their I/O on demand with its standard library.',
          'Editor requests are asynchronous. A worker exists only during a task. Rust can replace a specific boundary later if measurements justify it. No universal performance guarantee is claimed.',
        ],
      },
      {
        title: 'Contribute',
        paragraphs: [
          'Read AGENTS.md and CLAUDE.md. Use small English Conventional Commits. TypeScript uses Astro strictest, explicit any is prohibited, ESLint sorts imports, and Prettier sorts Tailwind classes.',
          'Agent tests use local fake providers and no paid model calls. Real language tests cover Pyright, StyLua, and debugpy; they do not establish every runtime or account integration.',
        ],
        code: 'make test\nmake smoke\nnpm ci\nnpm run check\nnpm run lint\nnpm run format:check\nnpm run build',
      },
    ],
  },
  {
    slug: 'business-rules',
    navigationTitle: 'Business rules',
    title: 'Explicit rules. Predictable behavior.',
    description:
      'The domain contract, with rule IDs, owners, and evidence. The same versioned source is shared with code and contributor agents.',
    sections: [],
    source: 'business-rules',
  },
  {
    slug: 'requirements',
    navigationTitle: 'Requirements',
    title: 'What we deliver. How to prove it.',
    description:
      'Functional and non-functional requirements, acceptance criteria, and limitations. Maintained beside the code.',
    sections: [],
    source: 'requirements',
  },
  {
    slug: 'git',
    navigationTitle: 'Git and files',
    title: 'Review. Resolve. Commit.',
    description:
      'Neogit, Diffview, nvim-tree, and optional lazygit. Familiar workflows in Neovim, without automating your Git decisions.',
    sections: [
      {
        title: 'File tree',
        paragraphs: [
          'Ctrl B or Space f e toggles the project tree. Enter opens a file; a creates, r renames, and d requests deletion with confirmation. g? shows shortcuts. The tree opens only on demand.',
        ],
        code: ':ForgeTree',
      },
      {
        title: 'Stage and commit',
        paragraphs: [
          'Tab expands files, s stages, and u unstages. Press c for the commit popup, then c to open the message editor. Review staged content, write a short English Conventional Commit, save, and close as Neogit instructs.',
          'Forge never commits or pushes automatically. Hooks, signing, and identity follow your Git configuration. Prefer lazygit? :ForgeLazygit opens your installed CLI in a native terminal tab.',
        ],
        code: ':ForgeGit',
      },
      {
        title: 'Three-way conflict resolution',
        paragraphs: [
          'The command checks for unmerged files before opening the merge. ]x and [x navigate conflicts. Space c o chooses ours/current, Space c t chooses theirs/incoming, and Space c b chooses the base at the selected conflict.',
          'Edit the result directly to combine both sides. Save, review, and stage only resolved files. :ForgeDiff opens working-tree review at any time.',
        ],
        code: ':ForgeConflicts',
        note: 'Choosing a side is your decision. No conflict is resolved automatically.',
      },
    ],
  },
];
