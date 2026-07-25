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
        procedure IgnoresMessagesUnrelatedToInitialize;
        procedure MatchesEquivalentWindowsUris;
        procedure ParsesInitializeErrorResponse;
        procedure ParsesSuccessfulInitializeResponse;
        procedure ReadsFragmentedUtf8Message;
        procedure ReadsMultipleMessages;
        procedure RejectsInvalidInitializeResponse;
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

procedure TLspProtocolTests.ParsesSuccessfulInitializeResponse;
var
    ErrorMessage: string;
    Status: TLspInitializeResponseStatus;
begin
    Status :=
        ParseInitializeResponse(
            '{"jsonrpc":"2.0","id":1,"result":{"capabilities":{"textDocumentSync":1}}}',
            ErrorMessage
        );
    AssertEquals(Ord(lirsSuccess), Ord(Status));
    AssertEquals('', ErrorMessage);
end;

procedure TLspProtocolTests.ParsesInitializeErrorResponse;
var
    ErrorMessage: string;
    Status: TLspInitializeResponseStatus;
begin
    Status :=
        ParseInitializeResponse(
            '{"jsonrpc":"2.0","id":1,"error":{"code":-32002,"message":"Falha simulada"}}',
            ErrorMessage
        );
    AssertEquals(Ord(lirsError), Ord(Status));
    AssertEquals('O servidor de linguagem recusou a inicialização (-32002): Falha simulada', ErrorMessage);
end;

procedure TLspProtocolTests.RejectsInvalidInitializeResponse;
var
    ErrorMessage: string;
    Status: TLspInitializeResponseStatus;
begin
    Status := ParseInitializeResponse('{"jsonrpc":"2.0","id":1}', ErrorMessage);
    AssertEquals(Ord(lirsError), Ord(Status));
    AssertEquals('O servidor de linguagem enviou uma resposta de inicialização inválida.', ErrorMessage);

    Status := ParseInitializeResponse('{"jsonrpc":"2.0","id":1,"result":null}', ErrorMessage);
    AssertEquals(Ord(lirsError), Ord(Status));
    AssertEquals('O servidor de linguagem enviou uma resposta de inicialização inválida.', ErrorMessage);
end;

procedure TLspProtocolTests.IgnoresMessagesUnrelatedToInitialize;
var
    ErrorMessage: string;
begin
    AssertEquals(
        Ord(lirsNotInitializeResponse),
        Ord(ParseInitializeResponse('{"jsonrpc":"2.0","id":2,"result":{}}', ErrorMessage))
    );
    AssertEquals('', ErrorMessage);
    AssertEquals(
        Ord(lirsNotInitializeResponse),
        Ord(
            ParseInitializeResponse(
                '{"jsonrpc":"2.0","id":1,"method":"workspace/configuration","params":{}}',
                ErrorMessage
            )
        )
    );
    AssertEquals('', ErrorMessage);
    AssertEquals(
        Ord(lirsNotInitializeResponse),
        Ord(ParseInitializeResponse('{"jsonrpc":"2.0","id":"1","result":{}}', ErrorMessage))
    );
    AssertEquals('', ErrorMessage);
end;

initialization
    RegisterTest(TLspProtocolTests);

end.
