program TestMarkdownRenderer;

{$mode objfpc}{$H+}

uses
  Markdown_Renderer, StrUtils, SysUtils;

procedure ExpectContains(const Description, Actual, Expected: string);
begin
  if not ContainsStr(Actual, Expected) then
  begin
    WriteLn(StdErr, 'FALHOU: ', Description);
    WriteLn(StdErr, 'Esperado: ', Expected);
    WriteLn(StdErr, 'Obtido: ', Actual);
    Halt(1);
  end;
end;

var
  Html: string;
begin
  Html := MarkdownToHtml('# Título' + LineEnding + LineEnding +
    'Texto com **negrito**, *itálico* e `código`.' + LineEnding +
    '- primeiro' + LineEnding + '- segundo' + LineEnding +
    '```pascal' + LineEnding + '<valor>' + LineEnding + '```');
  ExpectContains('título', Html, '<h1>Título</h1>');
  ExpectContains('negrito', Html, '<strong>negrito</strong>');
  ExpectContains('itálico', Html, '<em>itálico</em>');
  ExpectContains('código em linha', Html, '<code>código</code>');
  ExpectContains('lista', Html, '<ul>');
  ExpectContains('escape no código', Html, '&lt;valor&gt;');

  Html := MarkdownToHtml('- pai' + LineEnding +
    '  - filho' + LineEnding + '  - filha');
  ExpectContains('lista aninhada', Html, '<li>filho</li>');

  Html := MarkdownToHtml('<script>alert(1)</script>' + LineEnding +
    '[perigoso](javascript:alert(1))');
  ExpectContains('escape de HTML', Html,
    '&lt;script&gt;alert(1)&lt;/script&gt;');

  WriteLn('Todos os testes do renderizador passaram.');
end.
