# Configure suas linguagens

Para um novo usuário, todos os perfis começam desabilitados. Instalar um binário
não ativa seu servidor. Perfis iniciam LSP somente para arquivos compatíveis;
FlutterTools carrega apenas para Dart ou por comando explícito.

## Configuração guiada

1. Abra `:ForgeLanguages` (Espaço u l).
2. Escolha o perfil e confira seu estado on/off.
3. Use **Show requirements** para ver SDKs disponíveis e ausentes.
4. Instale o SDK/runtime seguindo a documentação oficial da linguagem.
5. Se necessário, escolha **Add SDK bin path** e selecione a pasta bin do SDK.
   Isso afeta apenas Forge e seus terminais; não altera seu perfil de shell.
6. Escolha **Enable and install tools** e acompanhe a instalação em `:Mason`.
7. Reinicie e abra um arquivo compatível.
8. Use `K` para documentação, `gd` para definição, `gl` para erros,
   `:ConformInfo` para formatadores e `:ForgeHealth` para requisitos.

**Enable with existing tools** ativa sem baixar ferramentas. **Disable profile**
desativa após reinício, preservando ferramentas baixadas e arquivos do projeto.
Não desinstala SDKs. Desinstalação é explícita no Mason. Outros usuários não
recebem automaticamente todos os SDKs, emuladores, imagens ou serviços.

## Perfis

| ID | Linguagens | Pré-requisitos | LSP / formatação | Debug |
| --- | --- | --- | --- | --- |
| typescript | TS, JS, React TSX/JSX | Node.js | ts_ls / prettierd ou prettier | vscode-js-debug |
| web | HTML, CSS, SCSS | Node.js | html + cssls / prettier | Browser não configurado |
| dart | Flutter e Dart | Flutter SDK com Dart | FlutterTools dartls / dart format | DAP do SDK |
| go | Go e módulos | Go | gopls / goimports + gofmt | Delve |
| python | Python | Python e Node.js | Pyright / isort + Black | debugpy |
| rust | Rust | Cargo, rustfmt, compilador | rust-analyzer / rustfmt | codelldb |
| lua | Lua | Runtime Lua | lua_ls / StyLua | Não configurado |
| php | PHP | PHP, Composer e Node.js | phpactor / Pint ou PHP-CS-Fixer | Xdebug; extensão necessária |
| native | C/C++ | Compilador | clangd / clang-format | codelldb |
| astro | Astro | Node.js | astro / prettierd | Não configurado |
| java/kotlin/ruby/shell/data | Formatação opcional | Confira requisitos no menu | Conform | Não configurado |

React usa o mesmo perfil TS/JS. Dependências, tipos React, tsconfig, ESLint e builds
pertencem ao projeto. Prettier usa configuração e plugins locais quando presentes.

## Flutter e Dart

Instale Flutter estável; Dart já vem incluído. Ative o perfil **Flutter / Dart**.
FlutterTools gerencia dartls; Forge não ativa outro dartls pelo nvim-lspconfig,
evitando dois servidores para o mesmo projeto.

| Comando | Atalho | Ação |
| --- | --- | --- |
| :ForgeFlutterDevices | Espaço D d | Escolher dispositivo |
| :ForgeFlutterRun | Espaço D r | Executar/debugar |
| :ForgeFlutterReload | Espaço D h | Hot reload |
| :ForgeFlutterRestart | Espaço D R | Hot restart |
| :ForgeFlutterOutline | Espaço D o | Árvore de widgets |
| :FlutterQuit | FlutterCommands | Encerrar app |

F9 marca breakpoint e F5 usa a configuração DAP Dart/Flutter. Tudo pode ser
remapeado em `:ForgeKeymaps`. DevTools e guias de widgets não abrem sozinhos.
Android exige ferramentas Android; iOS/macOS exigem Xcode, assinatura e aceite de
licenças pelo usuário. Preparar o editor não instala todos os destinos mobile.

```sh
flutter doctor
flutter devices
flutter run -d <device_id>
flutter run -d chrome
```

`--device` não é opção válida. Use `-d` com o ID. Sem `-d`, Flutter pode oferecer
destinos disponíveis. `-d web-server` permite outro navegador, com debug limitado.

## Outros debuggers

Python respeita VIRTUAL_ENV. Go exige módulo e Delve. Compile Rust/C/C++ antes de
selecionar o binário. PHP precisa de Xdebug na porta 9003. TS pode precisar de
compilação, source maps ou runtime específico. Carregue launch.json confiável por
`:ForgeDebugLoadLaunch`.

## Instalação headless explícita

Depois de habilitar perfis, execute no checkout da distribuição:

```sh
./bin/forge --headless '+lua dofile("scripts/install-language-tools.lua")'
```

Instala somente ferramentas Mason dos perfis habilitados e reporta falhas; SDKs
continuam separados. Use Python mantido para Black/debugpy atuais. O mínimo Python
3.9 do núcleo não garante compatibilidade com toda ferramenta externa.

## Configuração declarativa opcional

```lua
return {
  languages = { typescript = true, web = true, dart = true },
  tool_paths = { "/path/to/flutter/bin" },
}
```

Menus persistidos prevalecem. Uma linguagem adicional recebe perfil coeso em
languages/profiles.lua e LSP em languages/lsp.lua, ou plugin confiável. Mantenha
opt-in e documente requisitos. O preset solicitado para o proprietário ativa
TS/JS/React, HTML/CSS, Flutter/Dart, Go, Python, Rust, Lua e PHP. Outros usuários
continuam com todos os perfis desabilitados inicialmente.

Referências: [Flutter](https://docs.flutter.dev/install),
[CLI](https://docs.flutter.dev/reference/flutter-cli),
[FlutterTools](https://github.com/nvim-flutter/flutter-tools.nvim).
