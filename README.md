# Editor Markdown Acessível

Editor e renderizador Markdown autocontido para Windows, escrito em Free
Pascal. O MVP usa controles Win32 nativos por meio do Lazarus LCL e não abre
navegador, WebView ou servidor local.

## Funcionalidades

| Ação | Atalho |
| --- | --- |
| Abrir um arquivo Markdown | `Ctrl+O` |
| Salvar o Markdown atual | `Ctrl+S` |
| Salvar Markdown como | `Ctrl+Shift+S` |
| Exportar um HTML autocontido | `F2` |
| Renderizar e abrir a visualização | `F9` |
| Fechar a visualização | `Esc` |

Todos os comandos também estão disponíveis na barra de menus. Ao fechar,
criar ou abrir outro documento, o editor pergunta o que fazer com alterações
não salvas.

O renderizador cobre o subconjunto necessário ao MVP: títulos, parágrafos,
negrito, itálico, código em linha, links, listas ordenadas e não ordenadas,
citações, separadores e blocos de código cercados por três crases.

## Acessibilidade

- Editor, menus e diálogos de arquivo usam controles nativos do Windows.
- O editor possui nome, descrição e papel de acessibilidade explícitos.
- A visualização interna oferece duas guias: HTML visual e texto estruturado
  somente leitura para leitores de tela.
- Na visualização, `Ctrl+Tab` alterna entre as guias e `Esc` volta ao editor.
- Não há barras de ferramentas ou controles de formatação que aumentem a
  quantidade de paradas de tabulação.

## Dependências

- Free Pascal 3.2.2 ou posterior
- Lazarus 4.8 ou posterior com o widgetset Win32

As bibliotecas são rastreadas na seção `RequiredPackages` de
`markdown_editor.lpi`, usando o gerenciador de pacotes do Lazarus:

- `LCL`, para a interface nativa;
- `TurboPowerIPro`, distribuído com o Lazarus, para a visualização HTML
  interna.

As dependências são vinculadas ao executável; nenhuma DLL adicional nem
componente de navegador precisa ser distribuído.

## Compilar e testar

Com `lazbuild` no `PATH` ou `LazarusDir` definido:

```powershell
.\scripts\build.ps1 -Mode Release
.\scripts\test.ps1
```

O executável é criado em `bin\markdown-editor.exe`. Também é possível abrir
`markdown_editor.lpi` no Lazarus e selecionar **Executar > Compilar**.

## Estrutura

- `src/markdown_renderer.pas`: conversão de blocos para HTML/texto acessível;
- `src/markdown_inline.pas`: marcação em linha e escape seguro de HTML;
- `src/main_form.pas`: ciclo de vida do documento e coordenação da interface;
- `src/preview_form.pas`: diálogo modal de visualização;
- `src/file_service.pas`: leitura e escrita UTF-8;
- `tests/`: testes executáveis sem framework externo.

Todos os arquivos Pascal têm menos de 300 linhas e as unidades se mantêm
focadas em uma responsabilidade.
