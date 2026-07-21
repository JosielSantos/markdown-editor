unit Test_File_Service;

{$MODE objfpc}
{$H+}

interface

uses
    FpcUnit;

type
    TFileServiceTests = class(TTestCase)
    private
        TestFileName: string;
    protected
        procedure SetUp; override;
        procedure TearDown; override;
    published
        procedure BuildsHtmlExportFileName;
        procedure ReadsWrittenUtf8Content;
    end;

implementation

uses
    File_Service,
    SysUtils,
    TestRegistry;

const
    TestContent = '# Olá' + LineEnding + 'Texto em UTF-8: ação.';

procedure TFileServiceTests.SetUp;
begin
    TestFileName := GetTempFileName(GetTempDir, 'mde');
end;

procedure TFileServiceTests.TearDown;
begin
    if FileExists(TestFileName) then
        DeleteFile(TestFileName);
end;

procedure TFileServiceTests.BuildsHtmlExportFileName;
begin
    AssertEquals(
        'pasta' + DirectorySeparator + 'notas.html',
        HtmlExportFileName('pasta' + DirectorySeparator + 'notas.markdown')
    );
end;

procedure TFileServiceTests.ReadsWrittenUtf8Content;
begin
    WriteUtf8TextFile(TestFileName, TestContent);
    AssertEquals(TestContent, ReadUtf8TextFile(TestFileName));
end;

initialization
    RegisterTest(TFileServiceTests);

end.
