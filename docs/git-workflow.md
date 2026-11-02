# Git and file workflows

Forge reuses [Neogit](https://github.com/NeogitOrg/neogit),
[Diffview](https://github.com/sindrets/diffview.nvim), and
[nvim-tree](https://github.com/nvim-tree/nvim-tree.lua), pinned by the plugin lock.
They provide established interfaces inside native Neovim buffers. A pinned version
and integration tests improve reproducibility, not a blanket security guarantee.

## File tree

`:ForgeTree` / Ctrl B / Space f e toggles the project tree. Enter opens a file;
`a` creates, `r` renames, and `d` requests deletion using nvim-tree's confirmation.
Press `g?` for its context help. An empty interactive launch opens the project tree beside the workspace. Ctrl B toggles it; Ctrl H/L focuses either side.
Nerd Font file/folder icons are disabled unless explicitly enabled by the user.

## Stage and commit

`:ForgeGit` / Space g g opens Neogit status. Expand a section/file with Tab.
Press `s` to stage a file or selected hunk, `u` to unstage, and `c` to open the
commit popup; `c` again opens the commit editor. Write a short English Conventional
Commit, save, and close the editor as directed by Neogit. `?` shows available keys.
Review the staged content before completing a commit.

No Forge action commits, pushes, disables hooks, changes signing configuration,
or stages everything automatically. The accepted agent patch remains uncommitted
until the user chooses stage and commit. Neogit uses the user's Git configuration.

## Resolve conflicts

`:ForgeConflicts` / Space g m first checks whether unmerged files exist, then opens
Diffview's three-way merge layout. Navigate conflicts with `]x` and `[x`. At a
conflict use Space c o for ours/current, Space c t for theirs/incoming, or Space c b
for the base. You can edit the result buffer directly instead of accepting a side.
Save with `:write`, inspect the result, then stage only resolved files in Neogit.

Choosing one side is a user decision; Forge never chooses automatically. Keep any
intentional edits from both sides. `:ForgeDiff` opens the working-tree review at
any time. Consult `:h diffview-usage` and the plugin help for complete commands.

## Optional lazygit

`:ForgeLazygit` / Space g L opens an installed lazygit CLI in a native terminal tab.
Forge does not install or replace that CLI. Use Escape twice to leave terminal
input mode; the underlying lazygit keyboard workflow remains unchanged.

## Visible entry points

`:ForgeWorkspace` exposes source control, review, commit, conflict, and agent actions
with visible keys. `:ForgeGitHistory` shows up to 200 recent commits across local
refs as a graph; Enter opens the selected commit in Diffview and q closes it.
`:ForgeCommit` opens Neogit’s commit popup for staged changes. It does not stage,
commit, push, or bypass hooks automatically. Use Neogit status to choose files or
hunks, inspect the staged diff, then write the commit message explicitly.
`:ForgeDiff` reviews working-tree changes regardless of whether a human, formatter,
or agent produced them. Isolated agent acceptance retains its separate snapshot gate.
