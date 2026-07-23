# Markdown Editor

Editor simples de Markdown para Windows. Ele permite escrever em uma área de
texto, conferir o documento renderizado sem sair do programa e exportar uma
cópia em HTML.

## Instalação

Baixe `markdown-editor-0.2.1-setup.exe` na página de
[releases](https://github.com/JosielSantos/markdown-editor/releases) e execute o
arquivo. Durante a instalação, você pode associar as extensões `.md` e
`.markdown` ao Markdown Editor e escolher se o programa deve ser iniciado ao
final.

Como alternativa, baixe `markdown-editor-0.2.1-portable.zip` e extraia seu conteúdo. A
pasta `markdown-editor` criada pelo ZIP contém o programa e suas dependências,
sem instalador ou associação automática de arquivos.

O programa é destinado ao Windows 10 ou 11 de 64 bits e precisa do Microsoft
Edge WebView2 Runtime. Esse componente normalmente já está presente em
instalações atuais do Windows e do Microsoft Edge.

## Como usar

Digite ou cole o Markdown na janela principal. Use `F9` para abrir a
visualização e `Esc` para voltar ao editor. A visualização é interna; somente
links para páginas e endereços de e-mail são encaminhados ao aplicativo padrão
do Windows.

| Ação | Atalho |
| --- | --- |
| Novo documento | `Ctrl+N` |
| Abrir um arquivo Markdown | `Ctrl+O` |
| Salvar | `Ctrl+S` |
| Salvar como | `Ctrl+Shift+S` |
| Ir para uma linha | `Ctrl+G` |
| Abrir as opções | `Alt+O` |
| Exportar HTML ao lado do Markdown | `F2` |
| Escolher onde exportar o HTML | `Ctrl+F2` |
| Abrir a visualização | `F9` |
| Fechar a visualização | `Esc` |

Todos os comandos também estão disponíveis na barra de menus. O título da
janela recebe um asterisco quando o conteúdo é alterado. Se uma edição for
desfeita e o texto voltar a ser igual à última versão salva, o asterisco é
removido.

`F2` usa o nome do documento atual e troca sua extensão por `.html`. Em um
documento ainda sem nome, o programa pergunta onde criar o HTML. `Ctrl+F2`
sempre permite escolher outro nome ou diretório.

O menu **Arquivo > Arquivos recentes** mantém até nove documentos. Ao iniciar
o editor novamente, o último arquivo é reaberto na linha em que estava. Esse
comportamento pode ser desativado em **Ferramentas > Opções**, na aba **Geral**.
O programa também memoriza separadamente a última linha visitada em cada arquivo.

## Markdown aceito

O editor processa GitHub Flavored Markdown, incluindo:

- títulos, parágrafos e citações;
- listas simples, numeradas e aninhadas;
- listas de tarefas;
- links, tabelas e texto riscado;
- blocos e trechos de código.

HTML potencialmente inseguro não é executado na visualização.

## Acessibilidade

A janela de edição, os menus, as mensagens e os diálogos de arquivo usam
controles nativos do Windows. A visualização expõe a estrutura do HTML ao
leitor de tela, incluindo títulos, listas, links e caixas de seleção. Não há
barra de ferramentas de formatação nem controles adicionais entre o editor e
os menus.

## Abrir pela linha de comando

É possível informar um arquivo ao iniciar o programa:

```powershell
markdown-editor.exe "C:\Documentos\anotacoes.md"
```

Se o arquivo ainda não existir, o editor começa vazio e usa o caminho informado
quando você pressionar `Ctrl+S`.

A associação de arquivos também pode ser feita manualmente:

```powershell
markdown-editor.exe associate-files
```

## Desenvolvimento

O projeto usa Free Pascal, Lazarus e dependências mantidas como submódulos Git.
Para compilar e executar os testes:

```powershell
git clone --recurse-submodules https://github.com/JosielSantos/markdown-editor.git
cd markdown-editor
.\scripts\build.ps1 -Mode Debug
.\scripts\test.ps1
```

As orientações para contribuir estão em [AGENTS.md](AGENTS.md). Licenças e
avisos das bibliotecas utilizadas estão em
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
