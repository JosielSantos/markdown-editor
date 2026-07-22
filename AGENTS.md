# Repository Guidelines

## Project Structure & Module Organization

The application entry point is `markdown_editor.lpr`; Lazarus project settings
and package links live in `markdown_editor.lpi`. Production units are grouped
by responsibility under `src/`: `app/` handles startup concerns, `core/` holds
UI-independent editor rules, `gui/` contains forms, controllers, and dialogs,
and `services/` contains file, settings, Markdown, and language-server
operations. Keep unit files in the directory that matches their responsibility,
such as `gui/dialogs/insert_link.pas`, `services/markdown/renderer.pas`, and
`services/language_server/lsp_protocol.pas`. FPCUnit suites mirror the
production structure under `tests/`, while their console runner remains at
`tests/test_runner.pas`. Build helpers are in `scripts/`; the Inno Setup definition is under
`installer/`. Treat `vendor/` as read-only: its
MarkdownEngine, WebView4Delphi, and argparser-fp revisions are Git submodules. Generated files
belong in `bin/`, `dist/`, `lib/`, or `.lazarus/`.

## Build, Test, and Development Commands

Initialize dependencies after cloning:

```powershell
git submodule update --init
.\scripts\setup-marksman.ps1
.\scripts\build.ps1 -Mode Debug
.\scripts\format.ps1 -PasfmtPath .\pasfmt.exe
.\scripts\test.ps1
.\scripts\update-version.ps1 -Version 0.3.0
.\scripts\build.ps1 -Mode Release
.\scripts\package-release.ps1 -Version 0.3.0
```

The build script registers Lazarus packages and copies `WebView2Loader.dll` and
`marksman.exe` to `bin/`. The format script runs pasfmt only on project-owned Pascal sources;
use `-Check` to verify formatting without writes. The test script builds the
application, compiles the FPCUnit suite, and runs its console runner. Launch locally with
`.\bin\markdown-editor.exe .\example.md`. Development requires FPC 3.2.2+,
Lazarus 4.8+ with Win32 LCL, and the Microsoft Edge WebView2 Runtime. Build the
installer only after a Release build; its output belongs in `dist/`.
The version script synchronizes the README and Inno Setup definition. The
package script creates both installer and portable ZIP release artifacts.

## Coding Style & Naming Conventions

Use Object Pascal mode, clear names, and small routines with one purpose. Keep
project-owned Pascal files below 300 functional lines; do not count blank lines
or structural-only lines such as `begin` and `end`. Unit filenames use
`snake_case`, match their local unit name, and remain unique across `src/` so
FPC can resolve them through the configured unit search paths. Directories
express the architectural grouping; avoid repeating directory names in
filenames unless needed to keep unit names unique, and do not use dotted unit
namespaces. Types use `TEditorForm` style.
pasfmt enforces LF, UTF-8, 120-column lines, spaces instead of tabs, four-space
indentation, four-space continuations, and `begin` on its own line. Prefer DRY,
KISS implementations and native LCL/Windows behavior. Never use `MessageDlg`;
use `LCLIntf.MessageBox` for messages and confirmations so native accessible
button labels are preserved. When creating edit controls, including `TEdit`,
`TMemo`, and their descendants, set their accessible names with
`Accessibility.SetControlAccessibleName`; do not rely on the LCL
`AccessibleName` property alone because the Win32 widgetset does not expose it
reliably to screen readers. Apply the native accessible name only after the
control has its final Win32 handle. For dialog controls, call the helper in an
overridden `DoShow`, immediately after `inherited DoShow` and before setting
focus; do not call it from `CreateControls`, because the LCL may replace the
`HWND` while showing the dialog and lose the annotation. Always run
`.\scripts\format.ps1` before every commit, followed by `git diff --check`.

## Testing Guidelines

Use FPCUnit for every automated test. Name test units `test_<feature>.pas`,
derive test classes from `TTestCase`, publish test methods, and register each
class with `RegisterTest`. Add new test units to `tests/test_runner.pas`; the
runner must return a nonzero exit code on failure. Cover parser and file-service
behavior automatically. Screen-reader verification remains manual and should
be reported in the pull request when UI behavior changes.

## Commit & Pull Request Guidelines

Follow the existing Conventional Commit pattern: `feat:`, `fix:`, `refactor:`,
or `docs:` followed by a short imperative summary. Keep distinct functionality
in separate commits. Pull requests should describe user-visible behavior, list
build/test results, link relevant issues, and note manual keyboard or
screen-reader checks. Include screenshots only when visual layout changes.
