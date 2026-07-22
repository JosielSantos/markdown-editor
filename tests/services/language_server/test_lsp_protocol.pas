unit Test_Lsp_Protocol;

{$MODE objfpc}
{$H+}

interface

uses
    fpcunit,
    testregistry;

type
    TLspProtocolTests = class(TTestCase)
    published
        procedure BuildsDidOpenNotification;
        procedure MatchesEquivalentWindowsUris;
        procedure ReadsFragmentedUtf8Message;
        procedure ReadsMultipleMessages;
    end;

implementation

uses
    fpjson,
    jsonparser,
    Lsp_Protocol,
    SysUtils;

procedure TLspProtocolTests.ReadsFragmentedUtf8Message;
var
    Buffer: TLspMessageBuffer;
    ExpectedJson: string;
    Frame: RawByteString;
    JsonText: string;
begin
    Buffer := TLspMessageBuffer.Create;
    try
        ExpectedJson := '{"message":"a' + #$C3#$A7#$C3#$A3 + 'o"}';
        Frame := FrameLspMessage(ExpectedJson);
        Buffer.Append(Copy(Frame, 1, 12));
        AssertFalse('fragmento incompleto', Buffer.TryReadMessage(JsonText));
        Buffer.Append(Copy(Frame, 13, Length(Frame)));
        AssertTrue('mensagem completa', Buffer.TryReadMessage(JsonText));
        AssertEquals('conteúdo UTF-8', ExpectedJson, JsonText);
    finally
        Buffer.Free;
    end;
end;

procedure TLspProtocolTests.ReadsMultipleMessages;
var
    Buffer: TLspMessageBuffer;
    JsonText: string;
begin
    Buffer := TLspMessageBuffer.Create;
    try
        Buffer.Append(FrameLspMessage('{"id":1}') + FrameLspMessage('{"id":2}'));
        AssertTrue(Buffer.TryReadMessage(JsonText));
        AssertEquals('{"id":1}', JsonText);
        AssertTrue(Buffer.TryReadMessage(JsonText));
        AssertEquals('{"id":2}', JsonText);
        AssertFalse(Buffer.TryReadMessage(JsonText));
    finally
        Buffer.Free;
    end;
end;

procedure TLspProtocolTests.BuildsDidOpenNotification;
var
    JsonData: TJSONData;
begin
    JsonData := GetJSON(BuildDidOpenNotification('file:///C:/livro/capitulo.md', '# Título', 3));
    try
        AssertEquals('textDocument/didOpen', TJSONObject(JsonData).Get('method', ''));
        AssertEquals('file:///C:/livro/capitulo.md', JsonData.FindPath('params.textDocument.uri').AsString);
        AssertEquals('# Título', JsonData.FindPath('params.textDocument.text').AsString);
        AssertEquals(3, JsonData.FindPath('params.textDocument.version').AsInteger);
    finally
        JsonData.Free;
    end;
end;

procedure TLspProtocolTests.MatchesEquivalentWindowsUris;
begin
    AssertTrue(DocumentUrisMatch('file:///D:/livro/capitulo.md', 'file:///d%3A/livro/capitulo.md'));
    AssertFalse(DocumentUrisMatch('file:///D:/livro/um.md', 'file:///D:/livro/dois.md'));
end;

initialization
    RegisterTest(TLspProtocolTests);

end.
