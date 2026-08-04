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
        procedure IgnoresFrontMatterWhenExporting;
    end;

implementation

uses
    Files,
    Html_Export,
    StrUtils,
    SysUtils,
    TestRegistry;

const
    TEST_HTML_TEMPLATE = '<!doctype html><html><body>{{content}}</body></html>';

procedure THtmlExportTests.BuildsHtmlExportFileName;
begin
    AssertEquals(
        'pasta' + DirectorySeparator + 'notas.html',
        HtmlExportFileName('pasta' + DirectorySeparator + 'notas.markdown')
    );
end;

procedure THtmlExportTests.IgnoresFrontMatterWhenExporting;
var
    ExportFileName: string;
    Html: string;
begin
    ExportFileName := GetTempFileName(GetTempDir, 'mde');
    try
        ExportMarkdownToHtmlFile(
            '---' + LineEnding + 'title: Hidden metadata' + LineEnding + '---' + LineEnding + '# Content',
            TEST_HTML_TEMPLATE,
            ExportFileName
        );
        Html := ReadUtf8TextFile(ExportFileName);
        AssertFalse('front matter exported', ContainsStr(Html, 'Hidden metadata'));
        AssertTrue('content not exported', ContainsStr(Html, '<h1 id="content">Content</h1>'));
    finally
        DeleteFile(ExportFileName);
    end;
end;

initialization
    RegisterTest(THtmlExportTests);

end.
