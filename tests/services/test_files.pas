unit Test_Files;

{$MODE objfpc}
{$H+}

interface

uses
    FpcUnit;

type
    TFileServiceTests = class(TTestCase)
    private
        TestFileName: string;
        function ReadRawFile: string;
        procedure WriteRawFile(const Content: string);
    protected
        procedure SetUp; override;
        procedure TearDown; override;
    published
        procedure PreservesIso88591Encoding;
        procedure PreservesUtf8Bom;
        procedure PreservesWindows1252Encoding;
        procedure RejectsCharactersUnsupportedByOriginalEncoding;
        procedure ReadsWrittenUtf8Content;
    end;

implementation

uses
    Classes,
    Document_State,
    Files,
    SysUtils,
    TestRegistry;

const
    TEST_CONTENT_UTF8 = '# Ol' + #$C3#$A1 + LineEnding + 'Texto em UTF-8: a' + #$C3#$A7#$C3#$A3 + 'o.';
    TEST_CONTENT_ISO_8859_1 = '# Ol' + #$E1 + LineEnding + 'Texto em ISO-8859-1: a' + #$E7#$E3 + 'o.';
    TEST_CONTENT_WINDOWS_1252 = 'Cita' + #$E7#$E3 + 'o: ' + #$93 + 'pre' + #$E7 + 'o ' + #$80 + #$94;
    UTF8_BOM = #$EF#$BB#$BF;

function TFileServiceTests.ReadRawFile: string;
var
    FileStream: TFileStream;
begin
    FileStream := TFileStream.Create(TestFileName, fmOpenRead);
    try
        SetLength(Result, FileStream.Size);
        if FileStream.Size > 0 then
            FileStream.ReadBuffer(Result[1], FileStream.Size);
    finally
        FileStream.Free;
    end;
end;

procedure TFileServiceTests.WriteRawFile(const Content: string);
var
    FileStream: TFileStream;
begin
    FileStream := TFileStream.Create(TestFileName, fmCreate);
    try
        if Content <> '' then
            FileStream.WriteBuffer(Content[1], Length(Content));
    finally
        FileStream.Free;
    end;
end;

procedure TFileServiceTests.SetUp;
begin
    TestFileName := GetTempFileName(GetTempDir, 'mde');
end;

procedure TFileServiceTests.TearDown;
begin
    if FileExists(TestFileName) then
        DeleteFile(TestFileName);
end;

procedure TFileServiceTests.ReadsWrittenUtf8Content;
begin
    WriteUtf8TextFile(TestFileName, TEST_CONTENT_UTF8);
    AssertEquals(TEST_CONTENT_UTF8, ReadUtf8TextFile(TestFileName));
end;

procedure TFileServiceTests.PreservesIso88591Encoding;
var
    Content: string;
    Encoding: TDocumentEncoding;
begin
    WriteRawFile(TEST_CONTENT_ISO_8859_1);
    Content := ReadTextFile(TestFileName, Encoding);
    AssertEquals('iso88591', Encoding.Name);
    AssertEquals(TEST_CONTENT_UTF8, StringReplace(Content, 'ISO-8859-1', 'UTF-8', []));
    WriteTextFile(TestFileName, Content, Encoding);
    AssertEquals(TEST_CONTENT_ISO_8859_1, ReadRawFile);
end;

procedure TFileServiceTests.PreservesUtf8Bom;
var
    Content: string;
    Encoding: TDocumentEncoding;
begin
    WriteRawFile(UTF8_BOM + TEST_CONTENT_UTF8);
    Content := ReadTextFile(TestFileName, Encoding);
    AssertEquals(DOCUMENT_ENCODING_UTF8, Encoding.Name);
    AssertTrue(Encoding.HasUtf8Bom);
    AssertEquals(TEST_CONTENT_UTF8, Content);
    WriteTextFile(TestFileName, Content, Encoding);
    AssertEquals(UTF8_BOM + TEST_CONTENT_UTF8, ReadRawFile);
end;

procedure TFileServiceTests.PreservesWindows1252Encoding;
var
    Content: string;
    Encoding: TDocumentEncoding;
begin
    WriteRawFile(TEST_CONTENT_WINDOWS_1252);
    Content := ReadTextFile(TestFileName, Encoding);
    AssertEquals('cp1252', Encoding.Name);
    WriteTextFile(TestFileName, Content, Encoding);
    AssertEquals(TEST_CONTENT_WINDOWS_1252, ReadRawFile);
end;

procedure TFileServiceTests.RejectsCharactersUnsupportedByOriginalEncoding;
var
    Content: string;
    Encoding: TDocumentEncoding;
begin
    WriteRawFile(TEST_CONTENT_ISO_8859_1);
    Content := ReadTextFile(TestFileName, Encoding);
    try
        WriteTextFile(TestFileName, Content + #$E2#$82#$AC, Encoding);
        Fail('Era esperada uma falha de conversão.');
    except
        on ETextEncodingError do
            Exit;
    end;
end;

initialization
    RegisterTest(TFileServiceTests);

end.
