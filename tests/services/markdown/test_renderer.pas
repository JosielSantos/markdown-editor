unit Test_Renderer;

{$MODE objfpc}
{$H+}

interface

uses
    FpcUnit;

type
    TMarkdownRendererTests = class(TTestCase)
    private
        procedure AssertHtmlContains(const Description, Html, Expected: string);
    published
        procedure RendersCommonMarkdown;
        procedure AddsGitHubStyleHeadingAnchors;
        procedure RendersGitHubExtensions;
        procedure RendersNestedLists;
        procedure RendersTaskLists;
        procedure SanitizesUnsafeHtml;
    end;

implementation

uses
    Renderer,
    StrUtils,
    SysUtils,
    TestRegistry;

procedure TMarkdownRendererTests.AssertHtmlContains(const Description, Html, Expected: string);
begin
    AssertTrue(Description, ContainsStr(Html, Expected));
end;

procedure TMarkdownRendererTests.AddsGitHubStyleHeadingAnchors;
var
    Html: string;
begin
    Html := MarkdownToHtml('## WebView4Delphi' + LineEnding + '## WebView4Delphi');
    AssertHtmlContains('primeira âncora', Html, '<h2 id="webview4delphi">WebView4Delphi</h2>');
    AssertHtmlContains('âncora repetida', Html, '<h2 id="webview4delphi-1">WebView4Delphi</h2>');
end;

procedure TMarkdownRendererTests.RendersCommonMarkdown;
var
    Html: string;
begin
    Html :=
        MarkdownToHtml(
            '# Título'
                + LineEnding
                + LineEnding
                + 'Texto com **negrito**, *itálico* e `código`.'
                + LineEnding
                + '- primeiro'
                + LineEnding
                + '- segundo'
                + LineEnding
                + '```pascal'
                + LineEnding
                + '<valor>'
                + LineEnding
                + '```'
        );
    AssertHtmlContains('título', Html, '<h1 id="título">Título</h1>');
    AssertHtmlContains('negrito', Html, '<strong>negrito</strong>');
    AssertHtmlContains('itálico', Html, '<em>itálico</em>');
    AssertHtmlContains('código em linha', Html, '<code>código</code>');
    AssertHtmlContains('lista', Html, '<ul>');
    AssertHtmlContains('escape no código', Html, '&lt;valor&gt;');
end;

procedure TMarkdownRendererTests.RendersGitHubExtensions;
var
    Html: string;
begin
    Html := MarkdownToHtml('~~texto removido~~');
    AssertHtmlContains('texto riscado', Html, '<del>texto removido</del>');
end;

procedure TMarkdownRendererTests.RendersNestedLists;
var
    Html: string;
begin
    Html := MarkdownToHtml('- pai' + LineEnding + '  - filho' + LineEnding + '  - filha');
    AssertHtmlContains('lista aninhada', Html, '<li>filho</li>');
end;

procedure TMarkdownRendererTests.RendersTaskLists;
var
    Html: string;
begin
    Html := MarkdownToHtml('* [] Tarefa1' + LineEnding + '* [x] Tarefa2');
    AssertHtmlContains('tarefa desmarcada', Html, '<li><input type="checkbox" disabled> Tarefa1</li>');
    AssertHtmlContains('tarefa marcada', Html, '<li><input type="checkbox" checked disabled> Tarefa2</li>');
end;

procedure TMarkdownRendererTests.SanitizesUnsafeHtml;
var
    Html: string;
begin
    Html := MarkdownToHtml('<script>alert(1)</script>' + LineEnding + '[perigoso](javascript:alert(1))');
    AssertHtmlContains('escape de HTML', Html, '&lt;script&gt;alert(1)&lt;/script&gt;');
end;

initialization
    RegisterTest(TMarkdownRendererTests);

end.
