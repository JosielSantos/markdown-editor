# Repository Guidelines

## Project Structure & Module Organization

The application entry point is `markdown_editor.lpr`; Lazarus project settings
and package links live in `markdown_editor.lpi`. Production units are under
`src/`, with one responsibility per file: `main_form.pas` coordinates the UI,
`markdown_renderer.pas` renders GitHub Flavored Markdown, and the service units
handle files and HTML export. FPCUnit suites and their console runner are in
`tests/`. Build helpers are in `scripts/`. Treat `vendor/` as read-only: its
MarkdownEngine and WebView4Delphi revisions are Git submodules. Generated files
belong in `bin/`, `lib/`, or `.lazarus/`.

## Build, Test, and Development Commands

Initialize dependencies after cloning:

```powershell
git submodule update --init
.\scripts\build.ps1 -Mode Debug
.\scripts\build.ps1 -Mode Release
.\scripts\test.ps1
```

The build script registers Lazarus packages and copies `WebView2Loader.dll` to
`bin/`. The test script builds the application, compiles the FPCUnit suite,
and runs its console runner. Launch locally with
`.\bin\markdown-editor.exe .\example.md`. Development requires FPC 3.2.2+,
Lazarus 4.8+ with Win32 LCL, and the Microsoft Edge WebView2 Runtime.

## Coding Style & Naming Conventions

Use Object Pascal mode, two-space indentation, clear names, and small routines
with one purpose. Keep project-owned Pascal files below 300 lines. File names
use `snake_case.pas`; units and types use `Main_Form` and `TEditorForm` style.
Prefer DRY, KISS implementations and native LCL/Windows behavior. Never use
`MessageDlg`; use `LCLIntf.MessageBox` for messages and confirmations so native
accessible button labels are preserved. No automatic formatter is configured,
so match the surrounding layout and run `git diff --check` before committing.

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
