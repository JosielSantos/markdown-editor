unit Test_Link;

{$MODE objfpc}
{$H+}

interface

uses
    FpcUnit;

type
    TMarkdownLinkTests = class(TTestCase)
    published
        procedure BuildsMarkdownLink;
        procedure PreservesUnicodeText;
    end;

implementation

uses
    Link,
    TestRegistry;

procedure TMarkdownLinkTests.BuildsMarkdownLink;
begin
    AssertEquals(
        '[Documentação](https://example.com/docs)',
        BuildMarkdownLink('Documentação', 'https://example.com/docs')
    );
end;

procedure TMarkdownLinkTests.PreservesUnicodeText;
begin
    AssertEquals('[Ação](guia/ação.md)', BuildMarkdownLink('Ação', 'guia/ação.md'));
end;

initialization
    RegisterTest(TMarkdownLinkTests);

end.
