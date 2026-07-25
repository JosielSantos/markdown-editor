program Fake_Lsp;

{$MODE objfpc}
{$H+}

uses
    Classes,
    fpjson,
    jsonparser,
    Lsp_Protocol,
    SysUtils;

function ServerMessageFileName(const RelativeFileName: string): string;
var
    FixturesRoot: string;
begin
    FixturesRoot := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\tests\fixtures\fake_lsp');
    Result :=
        ExpandFileName(
            IncludeTrailingPathDelimiter(FixturesRoot)
                + StringReplace(RelativeFileName, '/', DirectorySeparator, [rfReplaceAll])
        );
    FixturesRoot := IncludeTrailingPathDelimiter(FixturesRoot);
    if Pos(LowerCase(FixturesRoot), LowerCase(Result)) <> 1 then
        raise Exception.CreateFmt('Fixture fora do diretório do fake LSP: %s', [RelativeFileName]);
end;

function ReadServerMessage(const RelativeFileName: string): string;
var
    Content: RawByteString;
    MessageStream: TFileStream;
begin
    MessageStream := TFileStream.Create(ServerMessageFileName(RelativeFileName), fmOpenRead or fmShareDenyWrite);
    try
        SetLength(Content, MessageStream.Size);
        if Length(Content) > 0 then
            MessageStream.ReadBuffer(Content[1], Length(Content));
        Result := string(Content);
    finally
        MessageStream.Free;
    end;
end;

procedure WriteServerMessage(OutputStream: TStream; const RelativeFileName: string);
var
    Message: RawByteString;
begin
    Message := FrameLspMessage(ReadServerMessage(RelativeFileName));
    if Length(Message) > 0 then
        OutputStream.WriteBuffer(Message[1], Length(Message));
end;

function ReadMessage(InputStream: TStream; MessageBuffer: TLspMessageBuffer; out JsonText: string): Boolean;
var
    ByteValue: Byte;
    Chunk: RawByteString;
begin
    Result := False;
    repeat
        if InputStream.Read(ByteValue, 1) <> 1 then
            Exit;
        SetLength(Chunk, 1);
        Chunk[1] := AnsiChar(ByteValue);
        MessageBuffer.Append(Chunk);
    until MessageBuffer.TryReadMessage(JsonText);
    Result := True;
end;

function ExpectedResponseFileName(const JsonText: string): string;
var
    ExpectedResponse: TJSONData;
    Message: TJSONData;
begin
    Result := '';
    Message := GetJSON(JsonText);
    try
        ExpectedResponse := Message.FindPath('expected_response_file_name');
        if Assigned(ExpectedResponse) and (ExpectedResponse.JSONType = jtString) then
            Result := ExpectedResponse.AsString;
    finally
        Message.Free;
    end;
end;

procedure HandleMessage(OutputStream: TStream; const JsonText: string);
var
    RelativeFileName: string;
begin
    RelativeFileName := ExpectedResponseFileName(JsonText);
    if RelativeFileName <> '' then
        WriteServerMessage(OutputStream, RelativeFileName);
end;

var
    InputStream: THandleStream;
    JsonText: string;
    MessageBuffer: TLspMessageBuffer;
    OutputStream: THandleStream;
begin
    InputStream := THandleStream.Create(TTextRec(Input).Handle);
    OutputStream := THandleStream.Create(TTextRec(Output).Handle);
    MessageBuffer := TLspMessageBuffer.Create;
    try
        while ReadMessage(InputStream, MessageBuffer, JsonText) do
            HandleMessage(OutputStream, JsonText);
    finally
        MessageBuffer.Free;
        OutputStream.Free;
        InputStream.Free;
    end;
end.
