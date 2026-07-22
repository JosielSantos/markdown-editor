unit Test_Html_Export;

{$MODE objfpc}
{$H+}

interface

uses
    FpcUnit;

type
    THtmlExportTests = class(TTestCase)
    published
        procedure BuildsHtmlExportFileName;
    end;

implementation

uses
    Html_Export,
    SysUtils,
    TestRegistry;

procedure THtmlExportTests.BuildsHtmlExportFileName;
begin
    AssertEquals(
        'pasta' + DirectorySeparator + 'notas.html',
        HtmlExportFileName('pasta' + DirectorySeparator + 'notas.markdown')
    );
end;

initialization
    RegisterTest(THtmlExportTests);

end.
