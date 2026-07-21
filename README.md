# Editor Markdown Acessível

MVP de um editor Markdown simples para Windows, escrito em Free Pascal com
Lazarus LCL e controles nativos do sistema.

## Requisitos de desenvolvimento

- Free Pascal 3.2.2 ou posterior
- Lazarus 4.8 ou posterior, com o widgetset Win32

As dependências da interface são declaradas em `markdown_editor.lpi` e
resolvidas pelo gerenciador de pacotes do Lazarus.

## Compilar

```powershell
lazbuild --build-mode=Release markdown_editor.lpi
```

O executável será criado em `bin/markdown-editor.exe`.
