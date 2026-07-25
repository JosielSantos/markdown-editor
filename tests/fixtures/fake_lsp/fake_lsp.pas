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

procedure WriteFileContent(OutputStream: TStream; const RelativeFileName: string);
var
    Content: RawByteString;
begin
    Content := RawByteString(ReadServerMessage(RelativeFileName));
    if Length(Content) > 0 then
        OutputStream.WriteBuffer(Content[1], Length(Content));
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

function JsonStringField(Message: TJSONData; const FieldName: string): string;
var
    Value: TJSONData;
begin
    Result := '';
    Value := Message.FindPath(FieldName);
    if Assigned(Value) and (Value.JSONType = jtString) then
        Result := Value.AsString;
end;

function JsonIntegerField(Message: TJSONData; const FieldName: string; out Value: Integer): Boolean;
var
    JsonValue: TJSONData;
begin
    JsonValue := Message.FindPath(FieldName);
    Result := Assigned(JsonValue) and (JsonValue.JSONType = jtNumber);
    if Result then
        Value := JsonValue.AsInteger;
end;

procedure HandleMessage(OutputStream, ErrorStream: TStream; const JsonText: string);
var
    ErrorFileName: string;
    ExitCode: Integer;
    Message: TJSONData;
    ResponseFileName: string;
begin
    Message := GetJSON(JsonText);
    try
        ErrorFileName := JsonStringField(Message, 'expected_standard_error_file_name');
        if ErrorFileName <> '' then
            WriteFileContent(ErrorStream, ErrorFileName);
        if JsonIntegerField(Message, 'expected_exit_code', ExitCode) then
            Halt(ExitCode);
        ResponseFileName := JsonStringField(Message, 'expected_response_file_name');
        if ResponseFileName <> '' then
            WriteServerMessage(OutputStream, ResponseFileName);
    finally
        Message.Free;
    end;
end;

var
    ErrorStream: THandleStream;
    InputStream: THandleStream;
    JsonText: string;
    MessageBuffer: TLspMessageBuffer;
    OutputStream: THandleStream;
begin
    ErrorStream := THandleStream.Create(TTextRec(StdErr).Handle);
    InputStream := THandleStream.Create(TTextRec(Input).Handle);
    OutputStream := THandleStream.Create(TTextRec(Output).Handle);
    MessageBuffer := TLspMessageBuffer.Create;
    try
        while ReadMessage(InputStream, MessageBuffer, JsonText) do
            HandleMessage(OutputStream, ErrorStream, JsonText);
    finally
        MessageBuffer.Free;
        OutputStream.Free;
        InputStream.Free;
        ErrorStream.Free;
    end;
end.
