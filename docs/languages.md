# Configure your languages

All language profiles start disabled for a new user. Installing a binary alone
never enables its server. Profiles start servers only for matching files, and
Flutter tooling loads only for Dart files or explicit Flutter commands.

## Guided setup

1. Run `:ForgeLanguages` (Leader u l).
2. Choose a profile. The menu displays its current on/off state.
3. Choose **Show requirements** to see available/missing SDK executables.
4. Install the language SDK/runtime separately using its official instructions.
5. If needed, choose **Add SDK bin path** and select the SDK's bin directory. This
   changes only Forge and its child terminals; it does not edit your shell profile.
6. Choose **Enable and install tools**. Mason installs the profile's LSP,
   formatter, and debug tools. Use `:Mason` to watch progress and errors.
7. Restart Forge after installation. Open a matching source file.
8. Use `K` for documentation, `gd` for definition, `gl` for line errors,
   `:ConformInfo` for formatter status, and `:ForgeHealth` for prerequisites.

**Enable with existing tools** activates a profile without downloading tools.
**Disable profile** stops activation after restart but preserves downloaded tools
and all project files. It does not uninstall an SDK. Use Mason explicitly to
uninstall an unneeded tool. Optional SDKs, emulators, device images, and services
are never all installed automatically for other users.

## Profile inventory

| Profile ID | Languages/files | Runtime prerequisite | LSP | Formatter | Debug |
| --- | --- | --- | --- | --- | --- |
| typescript | TypeScript, JavaScript, React TSX/JSX | Node.js | ts_ls | prettierd or prettier | vscode-js-debug |
| web | HTML, CSS, SCSS | Node.js | html, cssls | prettierd or prettier | Browser debugging is not configured |
| dart | Flutter and Dart | Flutter SDK including Dart | flutter-tools-managed dartls | dart format | SDK DAP through flutter-tools |
| go | Go, go.mod, go.work | Go | gopls | goimports then gofmt | Delve |
| python | Python | Python and Node.js | Pyright | isort then Black | debugpy |
| rust | Rust | Cargo, rustfmt, Rust compiler | rust-analyzer | rustfmt | codelldb |
| lua | Lua | Lua runtime | lua_ls | StyLua | Not configured |
| php | PHP | PHP, Composer, Node.js | phpactor | Pint or PHP-CS-Fixer | Xdebug adapter; Xdebug extension required |
| native | C/C++ | Compiler toolchain | clangd | clang-format | codelldb |
| astro | Astro | Node.js | astro | prettierd | Not configured |
| java/kotlin/ruby/shell/data | Optional formatter profiles | See the menu's requirements | Not configured by these profiles | Listed in Conform | Not configured |

`typescript` covers React without adding another server. Project dependencies,
React types, tsconfig, ESLint rules, and build scripts belong to the project.
Prettier loads the project's own configuration and plugins when available.

## Flutter and Dart

Use a stable Flutter SDK. It already includes Dart; do not install competing Dart
SDK paths ahead of it. Enable the **Flutter / Dart** profile after the SDK is on
Forge's PATH. flutter-tools owns the Dart language server: Forge deliberately does
not also enable nvim-lspconfig's dartls, preventing duplicate analysis processes.

| Command | Default shortcut | Purpose |
| --- | --- | --- |
| :ForgeFlutterDevices | Leader D d | Choose a connected device |
| :ForgeFlutterRun | Leader D r | Run/debug the project |
| :ForgeFlutterReload | Leader D h | Hot reload |
| :ForgeFlutterRestart | Leader D R | Hot restart |
| :ForgeFlutterOutline | Leader D o | Toggle widget outline |
| :FlutterQuit | Command palette via FlutterCommands | Stop the app |

F9 toggles breakpoints; F5 uses the Flutter/Dart DAP configuration when available.
All named Forge actions can be remapped in `:ForgeKeymaps`. DevTools and widget
guides do not start automatically. Device/emulator setup is separate from editor
support: Android builds require Android tooling; iOS/macOS builds require the
appropriate Xcode tools, signing, and user-completed license agreements.

From the terminal inside your Flutter project:

```sh
flutter doctor
flutter devices
flutter run -d <device_id>
# For an installed compatible browser:
flutter run -d chrome
```

`--device` is not a valid `flutter run` option; use `-d` with an ID. Without `-d`,
Flutter can offer available targets. `flutter run -d web-server` serves a web app
for another browser, with more limited debugging support.

## Optional Flutter menus

Flutter tooling remains opt-in through the Dart language profile. To use Telescope
for Flutter commands and Dart code actions, create this personal file outside the
repository: `~/.config/forge.nvim/after/ftplugin/dart.lua` (or the corresponding
`$XDG_CONFIG_HOME/forge.nvim` path).

```lua
if not require("forge.languages.selection").enabled("dart") then
  return
end
require("telescope").load_extension("flutter")
require("telescope").load_extension("ui-select")
```

Restart Forge and open a Dart file. Use `Leader D m` for the Flutter command menu,
`Leader c a` on a widget for available Dart actions such as wrapping or extraction,
and `Leader D o` to show or hide the outline. In the outline, `j`/`k` navigate,
Enter jumps to source, and `q` closes it. The outline navigates the current file;
it is not an editor for inserting widgets. Available actions depend on cursor
position and the connected Dart analysis server.

The `ui-select` extension changes `vim.ui.select` menus for the remainder of the
editor session after opening Dart. This file does not start an app, DevTools,
an emulator, or another analysis server. Delete it and restart to restore the
standard configuration. Personal files are not committed or replaced by updates.

## Debug prerequisites

Python uses VIRTUAL_ENV when set. Go needs a module and Delve. Build Rust/C/C++
first and select the binary. PHP requires Xdebug sending to port 9003. TypeScript
may need compilation, source maps, or a custom runtime. Load a trusted
`.vscode/launch.json` explicitly with `:ForgeDebugLoadLaunch`.

## Explicit headless installation

After enabling profiles, maintainers may install their Mason tools without opening
interactive menus:

```sh
./bin/forge --headless '+lua dofile("scripts/install-language-tools.lua")'
```

Run from the distribution checkout. The helper installs only enabled profiles,
reports failures, and never installs SDKs. Use a maintained Python runtime for
current Black/debugpy packages; the core's Python 3.9 minimum does not guarantee
compatibility with every external formatter version.

## Personal configuration alternative

Menus are the simplest path. For declarative setup, user.lua may contain:

```lua
return {
  languages = { typescript = true, web = true, dart = true },
  tool_paths = { "/path/to/flutter/bin" },
}
```

Saved menu choices override these defaults. Add another language by declaring a
focused profile under `lua/forge/languages/profiles.lua` and its LSP configuration
under `languages/lsp.lua`, or install a trusted language plugin. Keep that profile
opt-in and document its SDK and debugger requirements.

## Owner machine preset

The requested owner preset enables typescript (including JS/React), web (HTML/CSS),
dart (Flutter), go, python, rust, lua, and php. Other users receive no enabled
language profile by default. Machine installation results and limitations are
recorded separately in the validation report; SDK presence is not proof of every
device target or application build.

## Official references

- [Flutter installation](https://docs.flutter.dev/install)
- [Flutter editor/LSP/DAP support](https://docs.flutter.dev/tools/editors)
- [Flutter CLI](https://docs.flutter.dev/reference/flutter-cli)
- [Flutter tools plugin](https://github.com/nvim-flutter/flutter-tools.nvim)
- [Node.js](https://nodejs.org/en/download)
- [Go](https://go.dev/doc/install)
- [Rust](https://www.rust-lang.org/tools/install)
- [Python](https://www.python.org/downloads/)
- [PHP](https://www.php.net/manual/en/install.php)

### Reading Dart errors

K (Shift K) opens symbol/type information. It may show `InvalidType` for invalid
Dart expressions; that is hover content rather than the diagnostic explanation.
Use gl or Leader c e for complete analyzer errors on the line, ]d/[d to navigate,
and Leader p p for the project diagnostic list. Inline messages are enabled by
default. :ForgeDiagnosticDisplay changes presentation without changing analysis.

Optional actual-server verification uses an installed Dart SDK without Flutter
packages or model calls:

```sh
python3 scripts/dart-smoke.py --dart /path/to/dart-sdk/bin/dart
```

The fixture checks an undefined identifier and missing semicolon, then verifies
both messages are present in the line popup. It tests Dart LSP diagnostics and
Forge presentation; it does not claim verification of every Flutter runtime.
