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
| Exportar HTML junto ao Markdown atual | `F2` |
| Exportar HTML como | `Ctrl+F2` |
| Renderizar e abrir a visualização | `F9` |
| Fechar a visualização | `Esc` |

Todos os comandos também estão disponíveis na barra de menus. Ao fechar,
criar ou abrir outro documento, o editor pergunta o que fazer com alterações
não salvas.

Com um Markdown nomeado, `F2` grava o HTML no mesmo diretório e troca a
extensão por `.html`. Sem um arquivo atual, `F2` abre o diálogo de exportação.
`Ctrl+F2` sempre permite escolher outro nome ou diretório.

Um documento também pode ser aberto diretamente pela linha de comando:

```powershell
.\bin\markdown-editor.exe .\a.md
.\bin\markdown-editor.exe "C:\Meus documentos\anotacoes.md"
```

O conteúdo é processado pela biblioteca `MarkdownEngine` com as extensões
GitHub Flavored Markdown habilitadas, incluindo tabelas, texto riscado e
estruturas como listas aninhadas que não eram tratadas corretamente pelo
parser inicial do MVP.

## Acessibilidade

- Editor, menus e diálogos de arquivo usam controles nativos do Windows.
- O editor possui nome, descrição e papel de acessibilidade explícitos.
- A visualização é um único diálogo interno somente leitura; `Esc` volta ao
  editor.
- Não há barras de ferramentas ou controles de formatação que aumentem a
  quantidade de paradas de tabulação.

## Dependências

- Free Pascal 3.2.2 ou posterior
- Lazarus 4.8 ou posterior com o widgetset Win32

As bibliotecas são rastreadas na seção `RequiredPackages` de
`markdown_editor.lpi`, usando o gerenciador de pacotes do Lazarus:

- `LCL`, para a interface nativa;
- `TurboPowerIPro`, distribuído com o Lazarus, para a visualização HTML
  interna;
- `MarkdownEngine`, da biblioteca BSD `delphi-markdown`, para o parsing
  GitHub Flavored Markdown. A revisão usada fica fixada como submódulo Git.

As dependências são vinculadas ao executável; nenhuma DLL adicional nem
componente de navegador precisa ser distribuído.

## Compilar e testar

Clone incluindo a dependência:

```powershell
git clone --recurse-submodules <url-do-repositorio>
```

Em um clone já existente, execute `git submodule update --init`. Depois, com
`lazbuild` no `PATH` ou `LazarusDir` definido:

```powershell
.\scripts\build.ps1 -Mode Release
.\scripts\test.ps1
```

O executável é criado em `bin\markdown-editor.exe`. Também é possível abrir
`markdown_editor.lpi` no Lazarus e selecionar **Executar > Compilar**.

## Estrutura

- `src/markdown_renderer.pas`: adaptador entre `MarkdownEngine` e a página
  HTML autocontida;
- `src/main_form.pas`: ciclo de vida do documento e coordenação da interface;
- `src/preview_form.pas`: diálogo modal de visualização;
- `src/file_service.pas`: leitura e escrita UTF-8;
- `tests/`: testes executáveis sem framework externo.

Todos os arquivos Pascal próprios têm menos de 300 linhas e as unidades se
mantêm focadas em uma responsabilidade. O código de terceiros permanece sem
alterações dentro de `vendor/` e sua licença está reproduzida em
`THIRD_PARTY_NOTICES.md`.
