# ADR 001: Monitorar alterações externas no arquivo aberto

- Status: aceita
- Data: 2026-08-02

## Contexto

O editor precisa perceber quando o documento aberto é modificado, removido ou renomeado por outro programa. A solução
deve preservar alterações locais, não bloquear a interface e funcionar com FPC 3.2.2 e Lazarus 4.8 no Windows.

O projeto mantém apenas um documento aberto por vez. O conteúdo carregado ou salvo mais recentemente fica em
`TDocumentState.SavedContent` e serve como representação do conteúdo conhecido em disco.

Renomeios não serão acompanhados. Quando o caminho atual deixar de existir, o documento será tratado como removido e o
texto permanecerá disponível no editor.

## Decisão

Usar `FindFirstChangeNotificationW` para observar, sem recursão, o diretório que contém o documento aberto. A notificação
do Windows será apenas um gatilho: depois dela, a aplicação verificará exclusivamente `Document.FileName` e comparará seu
conteúdo com `Document.SavedContent`.

A implementação é dividida em três responsabilidades:

1. `TFileWatcher` mantém uma thread bloqueada na notificação nativa e sinaliza uma flag atômica. A thread não acessa
   controles da interface.
2. `TFileChangeController` consulta a flag na thread principal e aplica debounce de 350 ms para agrupar eventos de uma
   mesma gravação.
3. `TExternalFileController` verifica existência, lê e compara o arquivo aberto, decide a interação com o usuário e
   atualiza o editor e o servidor de linguagem.

O fluxo é:

```text
evento no diretório
        |
        v
debounce de 350 ms
        |
        v
Document.FileName ainda existe? -- não --> marcar como removido
        |
       sim
        |
        v
ler conteúdo e encoding
        |
        v
conteúdo igual a SavedContent? -- sim --> ignorar
        |
       não
        |
        v
modo automático? -- sim --> recarregar
        |
       não
        |
        v
perguntar antes de recarregar
```

A política é configurável entre atualizar automaticamente, perguntar antes de atualizar e não monitorar. O padrão é
perguntar. O modo automático também substitui alterações locais, por escolha explícita do usuário. O modo não monitorar
interrompe o watcher e o reinicia se outra opção for aplicada posteriormente.

Quando uma atualização é recusada, o texto do editor é preservado e o novo conteúdo em disco passa a ser a referência de
comparação. Assim, o documento fica marcado como modificado e o mesmo estado externo não provoca diálogos repetidos.

F5 executa uma atualização manual independente da preferência. Se o conteúdo em disco for diferente, ele substitui o
editor sem confirmação e emite um beep depois da atualização. Se o conteúdo for igual, nenhuma alteração ou som é
produzido. O comando também funciona quando o monitoramento automático está desabilitado.

Ao recarregar, a aplicação preserva cursor e seleção, atualiza o conteúdo dentro de `BeginUpdate`/`EndUpdate`, registra o
encoding detectado, redefine `SavedContent`, notifica o servidor de linguagem e atualiza o título da janela.

Se a leitura falhar temporariamente, por exemplo enquanto outro processo ainda escreve o arquivo, uma nova verificação é
agendada. Eventos produzidos pelo próprio salvamento são inofensivos: o conteúdo lido será igual a `SavedContent` e será
ignorado.

## Por que observar o diretório

Editores externos podem salvar substituindo o arquivo original por um temporário. Observar somente atributos de um handle
do arquivo pode perder essa substituição. Observar o diretório captura gravações, criações, exclusões e renomeios que
afetam o caminho.

`FindFirstChangeNotificationW` não informa qual entrada mudou. Uma alteração em outro arquivo do mesmo diretório pode,
portanto, provocar uma leitura do documento aberto. Isso não causa atualização incorreta: somente `Document.FileName` é
lido e a atualização exige conteúdo diferente de `SavedContent`.

Aceitamos essa leitura adicional porque existe apenas um documento aberto, as leituras acontecem em resposta a eventos e
o debounce agrupa notificações repetidas. Evitar a leitura exigiria mais estado ou uma API mais complexa, sem benefício
demonstrado para a carga esperada.

## Remoção e renomeio

Quando `Document.FileName` deixa de existir, `MissingOnDisk` é ativado e o conteúdo permanece no editor. Um documento
removido é considerado não salvo mesmo quando seu texto não mudou, garantindo que fechar ou abrir outro arquivo ofereça a
possibilidade de recriá-lo.

Um renomeio produz o mesmo resultado, por decisão de produto. A aplicação não tenta localizar nem acompanhar o novo nome.
Se o caminho original reaparecer, seu conteúdo volta a ser comparado normalmente.

## Alternativas consideradas

### Polling com `TTimer`

Verificar periodicamente existência, data, tamanho ou conteúdo seria simples e independente de uma thread nativa.
Entretanto, faria trabalho mesmo sem alterações e introduziria latência determinada pelo intervalo. Foi rejeitado em favor
de uma notificação imediata do sistema operacional.

### `ReadDirectoryChangesW`

Essa API fornece os nomes e tipos das alterações e permitiria filtrar eventos com `SameFileName`. Ela exige gerenciamento
de buffer, I/O sobreposto, cancelamento e tratamento de overflow. Além disso, o FPC 3.2.2 não a expõe diretamente pela
unit `Windows`, exigindo `JwaWinBase` ou uma declaração local. Como o produto não acompanha renomeios e sempre confirma o
conteúdo real, a precisão adicional não compensa a complexidade atual.

### Biblioteca `Wosi/DirectoryWatcher`

Oferece abstração multiplataforma sobre `ReadDirectoryChangesW`, inotify e FSEvents. Foi rejeitada porque não recebe
commits funcionais desde 2017, não possui releases, adiciona várias units, depende de `JwaWinBase` no Windows e entrega
callbacks fora da thread da interface. Sua licença também exigiria manter termos adicionais ao MIT do projeto.

### `Cromis.DirectoryWatch`

Possui licença BSD e implementação madura para Delphi. Foi rejeitada porque depende de outras units Cromis e exigiria um
porte relevante para FPC/Lazarus, maior que a integração nativa necessária neste projeto.

### Comparar metadados antes de ler

Manter tamanho e data de modificação poderia evitar algumas leituras causadas por outros arquivos do diretório. Isso
adicionaria estado e faria metadados decidirem se o conteúdo merece ser verificado. Como conteúdo é a fonte de verdade e a
carga esperada é pequena, a otimização foi adiada até existir evidência de problema de desempenho.

## Consequências

Positivas:

- reação imediata sem polling permanente do sistema de arquivos;
- nenhuma nova dependência de terceiros;
- compatibilidade com FPC 3.2.2;
- comparação do conteúdo real, evitando atualizações visíveis por eventos irrelevantes;
- suporte a substituições atômicas, remoções e recriações;
- separação entre thread nativa, debounce e comportamento da interface.

Negativas:

- implementação específica do Windows;
- alterações em outros arquivos do diretório podem causar uma leitura desnecessária;
- o arquivo inteiro é lido para comparação;
- renomeios são tratados como remoções;
- a API não identifica o arquivo que originou a notificação.
- o modo automático pode descartar alterações locais, conforme a preferência explícita do usuário.
- F5 também pode descartar alterações locais, como resultado explícito do comando de atualização manual.

## Critérios para reconsideração

Reavaliar esta decisão se medições mostrarem impacto relevante em arquivos grandes, unidades de rede ou diretórios com
atividade intensa; se o produto passar a acompanhar renomeios; ou se precisar oferecer suporte a outros sistemas
operacionais. Nesses casos, `ReadDirectoryChangesW` ou uma abstração multiplataforma mantida volta a ser justificável.
