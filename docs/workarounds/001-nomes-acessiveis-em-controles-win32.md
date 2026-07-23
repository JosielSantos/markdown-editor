# 001 — Nomes acessíveis em controles Win32

## Status

Ativo. Este workaround é necessário com o Lazarus 4.8 e o widgetset Win32 usados pelo projeto.

## Problema

A propriedade `AccessibleName` da LCL não é suficiente para nomear controles Win32 criados pela aplicação.
O valor permanece disponível no objeto Pascal, mas não é publicado de forma confiável para MSAA/UI
Automation. Na prática, leitores de tela podem receber somente o papel e o valor do controle.

O problema foi observado em campos de edição criados em tempo de execução: o NVDA anunciava apenas “edição,
em branco”, sem informar qual dado deveria ser preenchido. Isso torna campos semelhantes indistinguíveis para
quem navega sem informação visual.

## Causa

No Lazarus 4.8, a implementação-base de `TWSLazAccessibleObject.SetAccessibleName` é vazia, e o widgetset
Win32 não fornece uma implementação que exponha o nome do objeto LCL pela API de acessibilidade nativa do
Windows.

O problema não está no texto atribuído a `Control.AccessibleName`, mas na ausência da ponte entre essa
propriedade e o objeto acessível associado ao `HWND`.

## Funcionamento do workaround

A unit `src/gui/accessibility.pas` fornece:

```pascal
SetControlAccessibleName(Control, 'Nome acessível');
```

O helper:

1. mantém `Control.AccessibleName` preenchido no nível da LCL;
2. instancia o serviço nativo `IAccPropServices`;
3. converte explicitamente o nome de UTF-8 para UTF-16;
4. chama `SetHwndPropStr` para aplicar `PROPID_ACC_NAME` ao `OBJID_CLIENT` e `CHILDID_SELF` do `HWND`;
5. retorna `Boolean` para indicar se a anotação nativa foi aplicada.

A conversão explícita é necessária porque as strings do Lazarus estão em UTF-8 e `SetHwndPropStr` recebe
`LPCWSTR`. Sem ela, nomes com caracteres como “Endereço” e “Número” podem chegar ao leitor de tela com
mojibake.

Centralizar esse código evita repetir em cada diálogo a interface COM, os GUIDs, os identificadores MSAA, a
criação do serviço e o tratamento de encoding.

## Momento correto para aplicar o nome

A anotação pertence ao `HWND`, não apenas ao objeto LCL. Ela deve ser aplicada somente depois de o controle
possuir seu identificador Win32 definitivo.

Em diálogos, o helper deve ser chamado no `DoShow`, imediatamente depois de `inherited DoShow` e antes de
definir o foco. Não deve ser chamado em `CreateControls`: ao mostrar o diálogo, a LCL pode substituir o
`HWND`, descartando a anotação feita no identificador anterior.

Se um controle recriar seu handle por outro motivo, seu nome nativo também deverá ser aplicado novamente.

## Escopo e limitações

- A implementação depende de COM, MSAA e APIs específicas do Windows.
- A propriedade é anotada diretamente no `HWND` e deixa de existir quando esse handle é destruído.
- O retorno `False` não impede o funcionamento visual do controle; ele indica que o nome pode não ter
  chegado à camada nativa de acessibilidade.
- A validação efetiva continua sendo manual, com leitor de tela, porque verificar apenas
  `Control.AccessibleName` não exercita a ponte Win32.
- A unit declara localmente `IAccPropServices` e os identificadores necessários porque eles não estão
  disponíveis pela abstração usada da LCL.

## Alternativas consideradas

### Usar somente `Control.AccessibleName`

É a API apropriada no nível da LCL e deve continuar preenchida, mas, no widgetset Win32 do Lazarus 4.8, ela
não publica o nome para o leitor de tela. Foi justamente essa limitação que motivou o workaround.

### Corrigir o widgetset Win32 do LCL

Implementar `SetAccessibleName` no próprio widgetset eliminaria a necessidade de anotar cada `HWND` na
aplicação e beneficiaria todos os projetos Lazarus. É a melhor solução de longo prazo, mas exige manter um
patch local do Lazarus ou obter a correção no projeto upstream.

### Atualizar o Lazarus

Uma versão futura pode implementar a ponte nativamente. A atualização só substitui o workaround depois de
uma verificação no código do widgetset e de um teste manual com os controles usados pelo editor. A simples
existência de `AccessibleName` na API não comprova que o nome chega ao leitor de tela no Win32.

### Implementar um provedor MSAA ou UI Automation próprio

Um provedor completo daria controle sobre nome, papel, estado e relações entre elementos, mas teria custo e
complexidade muito maiores. Para suprir apenas o nome ausente, a anotação direta com `IAccPropServices` é
menor e usa uma API nativa destinada a esse cenário.

### Depender de rótulos visuais ou alterar o texto da janela

Leitores de tela podem inferir o nome de alguns controles a partir de rótulos próximos, mas essa associação
não é garantida para todos os layouts e tipos de controle. Alterar o texto do `HWND` também pode mudar o
conteúdo ou a apresentação do componente. Nenhuma dessas opções equivale a fornecer explicitamente o nome
acessível.

## Como remover

Quando o widgetset Win32 publicar `AccessibleName` nativamente:

1. confirme no código da versão adotada do Lazarus que o nome é encaminhado à API de acessibilidade;
2. teste com NVDA os campos do editor, **Ir para linha** e **Inserir link**, incluindo nomes com acentos;
3. substitua as chamadas a `SetControlAccessibleName` pela atribuição normal de `AccessibleName`;
4. remova `src/gui/accessibility.pas` e sua entrada em `markdown_editor.lpi`;
5. atualize a regra correspondente em `AGENTS.md`;
6. remova este documento.

## Referências

- [PR #6 — add Win32 accessible name helper](https://github.com/JosielSantos/markdown-editor/pull/6)
- [Lazarus 4.8 — implementação-base de acessibilidade](https://gitlab.com/freepascal.org/lazarus/lazarus/-/blob/lazarus_4_8/lcl/widgetset/wscontrols.pp#L187)
- [Lazarus 4.8 — widgetset Win32](https://gitlab.com/freepascal.org/lazarus/lazarus/-/blob/lazarus_4_8/lcl/interfaces/win32/win32wscontrols.pp)
- [Microsoft — Using Direct Annotation](https://learn.microsoft.com/en-us/windows/win32/winauto/using-direct-annotation)
- [Microsoft — IAccPropServices::SetHwndPropStr](https://learn.microsoft.com/en-us/windows/win32/api/oleacc/nf-oleacc-iaccpropservices-sethwndpropstr)
- [Microsoft — Win32 Edit Name](https://learn.microsoft.com/en-us/accessibility-tools-docs/items/win32/edit_name)
