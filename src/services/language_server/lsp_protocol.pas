unit Lsp_Protocol;

{$MODE objfpc}
{$H+}

interface

uses
    Classes,
    SysUtils;

type
    ELspProtocolError = class(Exception);

    TLspMessageBuffer = class
    private
        Buffer: RawByteString;
        function ReadContentLength(const Header: string): Integer;
    public
        procedure Append(const Data: RawByteString);
        function TryReadMessage(out JsonText: string): Boolean;
    end;

function FrameLspMessage(const JsonText: string): RawByteString;
function BuildInitializeRequest(ProcessId: Integer; const RootUri: string): string;
function BuildInitializedNotification: string;
function BuildDidOpenNotification(const Uri, Text: string; Version: Integer): string;
function BuildDidChangeNotification(const Uri, Text: string; Version: Integer): string;
function BuildDidSaveNotification(const Uri: string): string;
function BuildDidCloseNotification(const Uri: string): string;
function DocumentUrisMatch(const FirstUri, SecondUri: string): Boolean;
function IsInitializeResponse(const JsonText: string): Boolean;

implementation

uses
    fpjson,
    jsonparser,
    StrUtils,
    URIParser;

const
    HeaderSeparator = #13#10#13#10;
    InitializeRequestId = 1;

function JsonRpcNotification(const MethodName: string; Parameters: TJSONObject): string;
var
    MessageObject: TJSONObject;
begin
    MessageObject := TJSONObject.Create;
    try
        MessageObject.Add('jsonrpc', '2.0');
        MessageObject.Add('method', MethodName);
        MessageObject.Add('params', Parameters);
        Result := MessageObject.AsJSON;
    finally
        MessageObject.Free;
    end;
end;

function TextDocumentIdentifier(const Uri: string): TJSONObject;
begin
    Result := TJSONObject.Create;
    Result.Add('uri', Uri);
end;

function FrameLspMessage(const JsonText: string): RawByteString;
var
    JsonBytes: RawByteString;
begin
    JsonBytes := RawByteString(JsonText);
    Result := 'Content-Length: ' + IntToStr(Length(JsonBytes)) + HeaderSeparator + JsonBytes;
end;

procedure TLspMessageBuffer.Append(const Data: RawByteString);
begin
    Buffer := Buffer + Data;
end;

function TLspMessageBuffer.ReadContentLength(const Header: string): Integer;
var
    HeaderLower: string;
    LineEnd: Integer;
    ValueStart: Integer;
    ValueText: string;
begin
    HeaderLower := LowerCase(Header);
    ValueStart := Pos('content-length:', HeaderLower);
    if ValueStart = 0 then
        raise ELspProtocolError.Create('Cabeçalho LSP sem Content-Length.');
    Inc(ValueStart, Length('content-length:'));
    LineEnd := PosEx(#13#10, Header, ValueStart);
    if LineEnd = 0 then
        LineEnd := Length(Header) + 1;
    ValueText := Trim(Copy(Header, ValueStart, LineEnd - ValueStart));
    if not TryStrToInt(ValueText, Result) or (Result < 0) then
        raise ELspProtocolError.Create('Content-Length inválido no cabeçalho LSP.');
end;

function TLspMessageBuffer.TryReadMessage(out JsonText: string): Boolean;
var
    BodyStart: Integer;
    ContentLength: Integer;
    Header: string;
    HeaderEnd: Integer;
begin
    Result := False;
    JsonText := '';
    HeaderEnd := Pos(HeaderSeparator, Buffer);
    if HeaderEnd = 0 then
        Exit;
    Header := string(Copy(Buffer, 1, HeaderEnd - 1));
    ContentLength := ReadContentLength(Header);
    BodyStart := HeaderEnd + Length(HeaderSeparator);
    if Length(Buffer) < BodyStart - 1 + ContentLength then
        Exit;
    JsonText := string(Copy(Buffer, BodyStart, ContentLength));
    Delete(Buffer, 1, BodyStart - 1 + ContentLength);
    Result := True;
end;

function BuildInitializeRequest(ProcessId: Integer; const RootUri: string): string;
var
    Capabilities: TJSONObject;
    ClientInfo: TJSONObject;
    MessageObject: TJSONObject;
    Parameters: TJSONObject;
    TextDocumentCapabilities: TJSONObject;
begin
    MessageObject := TJSONObject.Create;
    try
        Parameters := TJSONObject.Create;
        ClientInfo := TJSONObject.Create;
        ClientInfo.Add('name', 'Markdown Editor');
        Capabilities := TJSONObject.Create;
        TextDocumentCapabilities := TJSONObject.Create;
        TextDocumentCapabilities.Add('publishDiagnostics', TJSONObject.Create);
        Capabilities.Add('textDocument', TextDocumentCapabilities);
        Parameters.Add('processId', ProcessId);
        Parameters.Add('clientInfo', ClientInfo);
        if RootUri = '' then
            Parameters.Add('rootUri', TJSONNull.Create)
        else
            Parameters.Add('rootUri', RootUri);
        Parameters.Add('capabilities', Capabilities);
        MessageObject.Add('jsonrpc', '2.0');
        MessageObject.Add('id', InitializeRequestId);
        MessageObject.Add('method', 'initialize');
        MessageObject.Add('params', Parameters);
        Result := MessageObject.AsJSON;
    finally
        MessageObject.Free;
    end;
end;

function BuildInitializedNotification: string;
begin
    Result := JsonRpcNotification('initialized', TJSONObject.Create);
end;

function BuildDidOpenNotification(const Uri, Text: string; Version: Integer): string;
var
    Document: TJSONObject;
    Parameters: TJSONObject;
begin
    Parameters := TJSONObject.Create;
    Document := TextDocumentIdentifier(Uri);
    Document.Add('languageId', 'markdown');
    Document.Add('version', Version);
    Document.Add('text', Text);
    Parameters.Add('textDocument', Document);
    Result := JsonRpcNotification('textDocument/didOpen', Parameters);
end;

function BuildDidChangeNotification(const Uri, Text: string; Version: Integer): string;
var
    Changes: TJSONArray;
    Document: TJSONObject;
    Parameters: TJSONObject;
    TextChange: TJSONObject;
begin
    Parameters := TJSONObject.Create;
    Document := TextDocumentIdentifier(Uri);
    Document.Add('version', Version);
    Parameters.Add('textDocument', Document);
    Changes := TJSONArray.Create;
    TextChange := TJSONObject.Create;
    TextChange.Add('text', Text);
    Changes.Add(TextChange);
    Parameters.Add('contentChanges', Changes);
    Result := JsonRpcNotification('textDocument/didChange', Parameters);
end;

function BuildDidSaveNotification(const Uri: string): string;
var
    Parameters: TJSONObject;
begin
    Parameters := TJSONObject.Create;
    Parameters.Add('textDocument', TextDocumentIdentifier(Uri));
    Result := JsonRpcNotification('textDocument/didSave', Parameters);
end;

function BuildDidCloseNotification(const Uri: string): string;
var
    Parameters: TJSONObject;
begin
    Parameters := TJSONObject.Create;
    Parameters.Add('textDocument', TextDocumentIdentifier(Uri));
    Result := JsonRpcNotification('textDocument/didClose', Parameters);
end;

function DocumentUrisMatch(const FirstUri, SecondUri: string): Boolean;
var
    FirstFileName: string;
    SecondFileName: string;
begin
    if SameText(FirstUri, SecondUri) then
        Exit(True);
    if not URIToFilename(FirstUri, FirstFileName) or not URIToFilename(SecondUri, SecondFileName) then
        Exit(False);
    Result := SameFileName(ExpandFileName(FirstFileName), ExpandFileName(SecondFileName));
end;

function IsInitializeResponse(const JsonText: string): Boolean;
var
    IdValue: TJSONData;
    JsonData: TJSONData;
    MessageObject: TJSONObject;
begin
    Result := False;
    JsonData := GetJSON(JsonText);
    try
        if JsonData.JSONType <> jtObject then
            Exit;
        MessageObject := TJSONObject(JsonData);
        IdValue := MessageObject.Find('id');
        Result := Assigned(IdValue) and (IdValue.AsInteger = InitializeRequestId);
    finally
        JsonData.Free;
    end;
end;

end.
