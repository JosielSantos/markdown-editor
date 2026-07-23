# 002 — Preservação de foco nas abas de opções

## Status

Ativo. Este workaround é específico para o comportamento do `TPageControl` no widgetset Win32 do LCL.

## Problema

Ao trocar de aba no diálogo de opções, o LCL transfere automaticamente o foco para o primeiro controle da
nova página. Na aba do verificador de Markdown, isso faz a caixa de seleção **Usar verificador de Markdown**
receber o foco sem que o usuário pressione `Tab`.

O comportamento esperado é manter o foco no controlador de abas após a troca. O primeiro controle da nova
página só deve receber o foco quando o usuário pressionar `Tab`.

## Causa

No widgetset Win32 do Lazarus, a implementação de `TPageControl` chama `TabControlFocusNewControl` durante a
troca de página. Essa rotina procura o primeiro controle elegível com `FindNextControl` e chama `SetFocus`
depois de entregar a notificação de mudança da aba.

O código fica no LCL, em:

```text
lcl/interfaces/win32/win32pagecontrol.inc
```

Por isso, chamar `SetFocus` somente em `OnChanging` ou `OnChange` não impede a transferência inicial. Em
`OnChanging`, o LCL ainda move o foco depois do evento. Em `OnChange`, o foco já passou pelo primeiro controle,
o que pode ser percebido visualmente e por tecnologias assistivas antes de voltar para as abas.

## Funcionamento do workaround

O diálogo instancia `TFocusPreservingPageControl`, definido em
`src/gui/focus_preserving_page_control.pas`, no lugar de instanciar `TPageControl` diretamente.

O componente sobrescreve `CanChangePageIndex` e, quando uma troca é permitida:

1. guarda todos os controles descendentes que estão com `TabStop = True`;
2. desativa temporariamente o `TabStop` desses controles;
3. mantém o foco no próprio controlador de abas;
4. agenda a restauração dos valores com `Application.QueueAsyncCall`.

Sem descendentes elegíveis durante a troca, `TabControlFocusNewControl` não encontra um controle para receber
o foco. Os `TabStop` são restaurados no próximo ciclo da fila de mensagens, antes da próxima navegação normal
por teclado.

O destrutor cancela chamadas assíncronas pendentes e restaura os controles antes de destruí-los.

## Escopo e limitações

- O comportamento só é aplicado onde `TFocusPreservingPageControl` é instanciado.
- A solução depende da ordem atual dos eventos do `TPageControl` no LCL Win32.
- Durante uma troca de página, os descendentes ficam fora da sequência de tabulação por um ciclo da fila de
  mensagens.
- Mudanças futuras no widgetset devem ser verificadas manualmente com teclado e leitor de tela.

## Alternativas consideradas

### Corrigir o LCL Win32

Alterar `TabControlFocusNewControl` para preservar o foco no controlador de abas seria a solução mais direta
na origem. Porém, isso exige manter uma versão modificada do Lazarus ou conseguir que a alteração seja aceita
no projeto upstream. Também afetaria todos os `TPageControl`, não apenas este diálogo.

Esta é a melhor opção de longo prazo se o LCL passar a oferecer esse comportamento nativamente.

### Interceptar a notificação nativa da troca de aba

Um componente poderia tratar diretamente as mensagens `TCN_SELCHANGING` e `TCN_SELCHANGE` do Win32 para
impedir a rotina de foco do widgetset. Isso acoplaria o projeto aos detalhes internos de mensagens e da
implementação do LCL, tornando a manutenção mais complexa e sensível a atualizações do Lazarus.

### Devolver o foco em `OnChange` ou por chamada assíncrona

Mover o foco de volta para as abas depois da troca é simples, mas não impede a transferência inicial. O
primeiro controle recebe e perde o foco rapidamente, causando o efeito visual e os eventos de acessibilidade
que motivaram este workaround.

### Desativar permanentemente o `TabStop` dos controles das páginas

Isso impede o foco automático, mas também remove os controles da navegação normal por `Tab`, violando o
comportamento esperado e prejudicando a acessibilidade.

## Como remover

Quando o LCL Win32 não transferir mais o foco automaticamente:

1. em `src/gui/dialogs/options.pas`, substitua `TFocusPreservingPageControl.Create` por
   `TPageControl.Create`;
2. remova `Focus_Preserving_Page_Control` da cláusula `uses`;
3. exclua `src/gui/focus_preserving_page_control.pas` e sua entrada em `markdown_editor.lpi`;
4. faça a verificação manual: troque de aba pelo teclado, confirme que o foco permanece nas abas e pressione
   `Tab` para alcançar o primeiro controle;
5. remova este documento.
