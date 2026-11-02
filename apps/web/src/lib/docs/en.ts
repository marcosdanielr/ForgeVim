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
        title: 'A workspace ready to use',
        paragraphs: [
          'Open Forge to find a Tokyo Night workspace, project files on the left, Git status, and actions with visible keys. Press a displayed letter or move with j/k and press Enter.',
          'To edit an opened file, press i. Press Esc to return to normal mode; Ctrl S saves. Ctrl H/J/K/L focuses another panel. Leader Leader opens the command palette.',
        ],
      },
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
          'The installer prepares selected plugins and creates ~/.local/bin/forge. Add ~/.local/bin to PATH when needed. The launcher sets NVIM_APPNAME=forge.nvim. Plugins, state, and personal settings are separate from ~/.config/nvim. First launch installs the plugin manager and enabled plugins. Following launches use local files.',
        ],
        code: 'gh repo clone marcosdanielr/forge.nvim\ncd forge.nvim\nbash install.sh\nforge .',
      },
      {
        title: 'Your first steps',
        table: {
          headers: ['Command', 'Result'],
          rows: [
            ['f on the welcome screen', 'Find and open a project file.'],
            ['g on the welcome screen', 'Review, stage, and commit changes.'],
            ['a on the welcome screen', 'Inspect agents and review their results.'],
            ['Leader Leader', 'Search all available commands.'],
            [':ForgeLanguages', 'Choose and install tools by language.'],
            [':ForgeHealth', 'Check editor and agent prerequisites.'],
          ],
        },
        note: 'Restart Forge after installing language tools. Toolchains are never all installed automatically.',
      },
      {
        title: 'Open your project',
        paragraphs: [
          'This is still Neovim. Use :edit, :split, :terminal, macros, registers, and your familiar motions. Leader defaults to Space. Change it in :ForgeLeader and restart.',
        ],
        code: 'cd /path/to/project\n/path/to/forge.nvim/bin/forge',
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
            ['Ctrl P', 'Leader f f', 'Find project files.'],
            ['Ctrl Shift F', 'Leader f g', 'Search project text.'],
            ['Ctrl F', 'Leader f b', 'Search this buffer.'],
            ['Ctrl Shift H', 'Leader f r', 'Replace project text.'],
            ['—', 'Leader f R', 'Replace current-file text.'],
            ['F2', 'Leader c r', 'Rename an LSP symbol.'],
            ['Ctrl S', ':write', 'Save buffer.'],
            ['Alt Shift F', 'Leader c f', 'Format code.'],
            ['Ctrl Shift P', 'Leader Leader', 'Open command palette.'],
            ['Ctrl Space', '—', 'Show code completion.'],
            ['Ctrl B', 'Leader f e', 'Toggle file tree.'],
            ['Ctrl H/J/K/L', 'Ctrl W then h/j/k/l', 'Focus an adjacent window.'],
            ['Leader u w', ':ForgeWorkspace', 'Return to the workspace.'],
            ['Leader g h', ':ForgeGitHistory', 'Open the commit graph; Enter reviews a commit.'],
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
            ['K / Leader c h', 'Show class, variable, or function documentation.'],
            ['Leader c s', 'Show function signature.'],
            ['gi / gy', 'Go to implementation / type definition.'],
            ['gl / Leader c e', 'Read line diagnostics.'],
            [']d / [d', 'Go to next / previous diagnostic.'],
            ['Leader f s', 'Find document symbols.'],
          ],
        },
      },
      {
        title: 'Debugging and agents',
        table: {
          headers: ['Shortcut', 'Alternative', 'Action'],
          rows: [
            ['F5', 'Leader d c', 'Start or continue debugging.'],
            ['F9', 'Leader d b', 'Toggle breakpoint.'],
            ['F10', 'Leader d o', 'Step over.'],
            ['F11', 'Leader d i', 'Step into.'],
            ['Shift F11', 'Leader d O', 'Step out.'],
            ['Shift F5', 'Leader d q', 'Stop debugging.'],
            ['—', 'Leader a n', 'Start agent task.'],
            ['—', 'Leader a a', 'List and review agents.'],
            ['—', 'Leader a c', 'Connect provider account.'],
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
      {
        title: 'Panels, buffers, and terminals',
        paragraphs: [
          'Press F1 for a guide that reflects your configured shortcuts. Ctrl H/J/K/L moves between visible panes in normal mode and Forge terminals; h/j/k/l stays native in files. In the explorer, h collapses and l or Enter opens. Mouse clicks focus panels and double-clicks activate their actions.',
        ],
        table: {
          headers: ['Action', 'Keys'],
          rows: [
            ['Files / Agents / Chat', 'Ctrl B / Leader p a / Leader p c'],
            ['Next / previous buffer', 'Ctrl Tab / Ctrl Shift Tab; Leader b n / Leader b p'],
            [
              'Terminal / new terminal',
              'Ctrl backtick / Ctrl Shift backtick; Leader o t / Leader o T',
            ],
            ['Split / choose terminal', 'Ctrl Shift 5 / Leader o s; Leader o o'],
            ['Review / debug / logs', 'Leader p r / Leader p d / Leader p l'],
            ['Settings / startup panels', 'Leader u s / Leader u L'],
          ],
        },
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
    description: 'Run agents side by side and review each result before it changes your project.',
    sections: [
      {
        title: 'Connect your account',
        paragraphs: [
          'Select ChatGPT/Codex, Claude Code, or Gemini. Forge opens the official CLI login flow in a Neovim terminal. Complete authentication yourself. Your plan, quota, and model remain with the provider.',
          'Save buffers and commit or stash changes first. Each task starts at the current HEAD in its own branch and worktree. Start several independent tasks when useful.',
        ],
        code: ':ForgeAgentConnect\n:ForgeAgentStart',
        note: 'Use tasks for one-shot work or open CLI chat for follow-ups and interactive permission prompts. Both use isolated worktrees and explicit review.',
      },
      {
        title: 'Review the result',
        paragraphs: [
          'If the task result or your project changes after review, review again before accepting. Save and commit your changes before applying another task. Forge checks for conflicts and leaves conflicting results available for inspection.',
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
          'Notifications stay inside Neovim without exposing prompt contents. One-shot tasks keep running when the editor closes; interactive chats end with their terminal. System notifications while closed and mobile push are not implemented.',
        ],
        code: ':ForgeNotifications',
      },
      {
        title: 'Chat with your existing CLI account',
        paragraphs: [
          'Connect your account, then run :ForgeChatNew or press Leader a C. Choose a provider and name the conversation. The official CLI opens in a side terminal; type your request there and use its normal follow-ups and permission prompts.',
          'Save files and commit or stash first. Chat uses its own worktree. Hiding the pane keeps it live while Forge is open. Exit the CLI, select its task in Agents, and choose Review changes before accepting.',
          'These terminals belong to the current editor session. Logs and worktrees remain available after closing; Forge does not promise to reattach an old terminal or replace provider-native resume controls.',
        ],
        code: ':ForgeAgentConnect\n:ForgeChatNew\n:ForgeAgents',
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
          'Theme selection applies and persists. Tokyo Night is the default; Catppuccin, Rose Pine, and the plain Habamax theme are available too.',
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
          'The config path respects XDG_CONFIG_HOME. Menu preferences live under stdpath("state")/forge/preferences.json and override user defaults. Folder and language icons are enabled by default. Select a Nerd Font in your terminal, such as MesloLGM Nerd Font Mono. Use :ForgeIcons (Leader u i) and restart to switch to plain text.',
        ],
        code: '-- ~/.config/forge.nvim/lua/user.lua\nreturn {\n  theme = "tokyonight",\n  format_on_save = true,\n  copilot = false,\n  notifications = true,\n  nerd_fonts = true,\n}',
      },
      {
        title: 'Bottom statusbar',
        paragraphs: [
          'The global bottom bar stays visible across panels. It shows mode, Git branch, errors and warnings, language, encoding, line endings, and cursor position. Counts come from actual buffer diagnostics.',
          'Press K (Shift K) in normal mode for symbol documentation. Press gl or Leader c e for line errors and warnings. Use ]d and [d to move between diagnostics. F1 lists your configured keys; language documentation requires an active LSP.',
        ],
      },
      {
        title: 'Window size and Leader',
        paragraphs: [
          'Pane headers show the shortcut that hides them. Ctrl B toggles Explorer; Leader p a toggles Agents, Leader p c toggles chat, and Leader p l toggles logs. Ctrl backtick toggles terminals.',
          'Focus a split with Ctrl H/J/K/L. Ctrl Shift Left/Right changes its width; Ctrl Shift Up/Down changes its height. Leader w h/l/k/j provides the same actions; Leader w = balances windows. Mouse resizing remains available.',
          'Leader defaults to Space. :ForgeLeader or Settings saves a different key; restart applies it. Leader Leader opens commands. Tab/Shift Tab cycles buffers in normal mode, matching VIMarcos, while terminal Tab completion remains available.',
          'Find files with Leader f f, search project text with Leader f g, and search the current buffer with Leader f b. :ForgeKeymaps changes these keys. :ForgeDiagnosticDisplay selects inline, expanded current-line, or quiet error messages.',
        ],
      },
      {
        title: 'New terminals, pane toggles and replacement',
        paragraphs: [
          'Leader o t toggles the active terminal. Alt Enter or Leader o T creates another shell; Leader o s splits and Leader o o lists sessions. New, Split and List are also clickable in the terminal header. Ctrl Space/Ctrl @ is a legacy-terminal toggle outside insert mode; insert completion is preserved.',
          'Leader p a toggles Agents, Leader p c toggles chat, Leader p l toggles logs, and Ctrl B toggles Explorer. These actions also work while a Forge terminal is focused. Hiding a terminal keeps its process running.',
          'Replacement previews show Apply all. Review matches, then click it or press Leader f A. Opening preview never edits files. Git staging and commits remain explicit Neogit actions; conflict-side choices remain explicit Diffview actions.',
        ],
      },
      {
        title: 'Reproducible updates',
        paragraphs: [
          'The bundled lazy-lock.json seeds a local state copy on first launch. :Lazy updates that user copy without changing the distribution checkout.',
          'Maintainers use FORGE_UPDATE_LOCK=1 when intentionally syncing dependencies, review the lock, and run checks before committing.',
        ],
      },
      {
        title: 'Configure from the editor',
        paragraphs: [
          'Open Settings with Leader u s. Choose theme, keyboard shortcuts, languages, plugins, account login, notifications, or startup layout. No Lua edit is required for these choices.',
          'Startup layout can enable or disable the welcome screen, files sidebar, and Agents sidebar. Narrow terminals keep panels available by shortcut instead of opening every pane.',
        ],
        code: ':ForgeSettings\n:ForgeStartupLayout',
      },
    ],
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
          'Ctrl B or Leader f e toggles the project tree. Enter opens a file; a creates, r renames, and d requests deletion with confirmation. g? shows shortcuts. The tree opens beside the welcome screen. Ctrl H/L moves between panels; h/j/k/l moves the cursor.',
        ],
        code: ':ForgeTree',
      },
      {
        title: 'Stage and commit',
        paragraphs: [
          'Tab expands files, s stages, and u unstages. Press c for the commit popup, then c to open the message editor. Review staged content, write your commit message, save, and close as Neogit instructs.',
          'Forge never commits or pushes automatically. Hooks, signing, and identity follow your Git configuration. Prefer lazygit? :ForgeLazygit opens your installed CLI in a native terminal tab.',
        ],
        code: ':ForgeGit',
      },
      {
        title: 'Three-way conflict resolution',
        paragraphs: [
          'The command checks for unmerged files before opening the merge. ]x and [x navigate conflicts. Leader c o chooses ours/current, Leader c t chooses theirs/incoming, and Leader c b chooses the base at the selected conflict.',
          'Edit the result directly to combine both sides. Save, review, and stage only resolved files. :ForgeDiff opens working-tree review at any time.',
        ],
        code: ':ForgeConflicts',
        note: 'Choosing a side is your decision. No conflict is resolved automatically.',
      },
      {
        title: 'Find and replace with visible options',
        paragraphs: [
          'Ctrl Shift H or Leader f r opens project search and replace. Leader f R targets the current file. Set Search and Replace, choose File or Project, and toggle Match case, Whole word, and Regex.',
          'Press p to preview. The preview does not change files. Review matches, then use grug-far’s visible action keys; g? shows help. With default keys, comma followed by r applies replacement.',
        ],
        code: ':ForgeReplace\n:ForgeBufferReplace',
      },
    ],
  },
];
