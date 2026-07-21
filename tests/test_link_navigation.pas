unit Test_Link_Navigation;

{$MODE objfpc}
{$H+}

interface

uses
    FpcUnit,
    Link_Navigation;

type
    TLinkNavigationTests = class(TTestCase)
    private
        procedure AssertAction(const Uri: string; Expected: TLinkNavigationAction);
    published
        procedure AllowsRenderedPreviewDocument;
        procedure KeepsDocumentAnchorsInPreview;
        procedure OpensSupportedLinksExternally;
        procedure BlocksUnsupportedLinks;
    end;

implementation

uses
    TestRegistry;

procedure TLinkNavigationTests.AssertAction(const Uri: string; Expected: TLinkNavigationAction);
begin
    AssertEquals(Uri, Ord(Expected), Ord(ClassifyNavigation(Uri, False)));
end;

procedure TLinkNavigationTests.AllowsRenderedPreviewDocument;
begin
    AssertEquals(
        'documento renderizado',
        Ord(lnaKeepInPreview),
        Ord(ClassifyNavigation('data:text/html,conteudo', True))
    );
end;

procedure TLinkNavigationTests.KeepsDocumentAnchorsInPreview;
begin
    AssertAction('#conteudo', lnaKeepInPreview);
    AssertAction('about:blank#conteudo', lnaKeepInPreview);
end;

procedure TLinkNavigationTests.OpensSupportedLinksExternally;
begin
    AssertAction('http://example.com', lnaOpenExternally);
    AssertAction('HTTPS://example.com/documento', lnaOpenExternally);
    AssertAction('mailto:contato@example.com', lnaOpenExternally);
end;

procedure TLinkNavigationTests.BlocksUnsupportedLinks;
begin
    AssertAction('javascript:alert(1)', lnaBlock);
    AssertAction('file:///C:/segredo.txt', lnaBlock);
    AssertAction('data:text/html,conteudo', lnaBlock);
    AssertAction('about:blank', lnaBlock);
    AssertAction('outro-arquivo.md', lnaBlock);
end;

initialization
    RegisterTest(TLinkNavigationTests);

end.
