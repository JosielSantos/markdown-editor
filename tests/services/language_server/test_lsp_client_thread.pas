unit Test_Lsp_Client_Thread;

{$MODE objfpc}
{$H+}

interface

uses
    fpcunit,
    Lsp_Client_Thread,
    Lsp_Diagnostics,
    testregistry;

type
    TLspClientThreadTests = class(TTestCase)
    private
        DiagnosticsReceived: Boolean;
        ReceivedDiagnostics: TLspDiagnosticArray;
        ReceivedDocumentUri: string;
        ServerReady: Boolean;
        ServerError: string;
        procedure HandleDiagnostics(Sender: TObject; const DocumentUri: string; const Diagnostics: TLspDiagnosticArray);
        procedure HandleError(Sender: TObject; const ErrorMessage: string);
        procedure HandleReady(Sender: TObject);
        function SelectFakeLanguageServerResponse(const JsonText: string): string;
    published
        procedure ReceivesDiagnosticsFromFakeLanguageServer;
    end;

implementation

uses
    Classes,
    Lsp_Protocol,
    SysUtils;

const
    FakeDocumentUri = 'file:///fake-document.md';
    FakeLanguageServerFileName = 'bin\fake_lsp.exe';
    ResponseTimeoutMilliseconds = 5000;

procedure TLspClientThreadTests.HandleDiagnostics(
    Sender: TObject;
    const DocumentUri: string;
    const Diagnostics: TLspDiagnosticArray
);
begin
    ReceivedDocumentUri := DocumentUri;
    ReceivedDiagnostics := Copy(Diagnostics, 0, Length(Diagnostics));
    DiagnosticsReceived := True;
end;

procedure TLspClientThreadTests.HandleError(Sender: TObject; const ErrorMessage: string);
begin
    ServerError := ErrorMessage;
end;

procedure TLspClientThreadTests.HandleReady(Sender: TObject);
begin
    ServerReady := True;
end;

function TLspClientThreadTests.SelectFakeLanguageServerResponse(const JsonText: string): string;
var
    ExpectedResponse: string;
begin
    ExpectedResponse := '';
    if (Pos('"method"', JsonText) > 0) and (Pos('"initialize"', JsonText) > 0) then
        ExpectedResponse := 'responses/initialization/valid_response.json'
    else if (Pos('"method"', JsonText) > 0) and (Pos('"textDocument/didOpen"', JsonText) > 0) then
        ExpectedResponse := 'notifications/diagnostics/valid_diagnostics.json';
    Result := JsonText;
    if ExpectedResponse <> '' then
        Insert(',"expected_response_file_name":"' + ExpectedResponse + '"', Result, Length(Result));
end;

procedure TLspClientThreadTests.ReceivesDiagnosticsFromFakeLanguageServer;
var
    Client: TLspClientThread;
    Deadline: QWord;
    DocumentUri: string;
begin
    AssertTrue('Fake Markdown LSP não encontrado', FileExists(FakeLanguageServerFileName));
    DiagnosticsReceived := False;
    SetLength(ReceivedDiagnostics, 0);
    ReceivedDocumentUri := '';
    ServerReady := False;
    ServerError := '';
    DocumentUri := FakeDocumentUri;
    Client :=
        TLspClientThread.Create(
            FakeLanguageServerFileName,
            '',
            @HandleDiagnostics,
            @HandleError,
            @HandleReady,
            @SelectFakeLanguageServerResponse
        );
    try
        Client.OpenDocument(
            DocumentUri,
            '# Teste' + LineEnding + LineEnding + 'Conteúdo simulado' + LineEnding + 'Aviso simulado'
        );
        Deadline := GetTickCount64 + ResponseTimeoutMilliseconds;
        while not DiagnosticsReceived and (ServerError = '') and (GetTickCount64 < Deadline) do
        begin
            CheckSynchronize(20);
            Sleep(10);
        end;
        AssertEquals('erro inesperado do Markdown LSP', '', ServerError);
        AssertTrue('o fake Markdown LSP não concluiu a inicialização', ServerReady);
        AssertTrue('o fake Markdown LSP não publicou diagnósticos', DiagnosticsReceived);
        AssertTrue('URI devolvida pelo fake Markdown LSP', DocumentUrisMatch(DocumentUri, ReceivedDocumentUri));
        AssertEquals('quantidade de diagnósticos simulados', 2, Length(ReceivedDiagnostics));
        AssertEquals(Ord(ldsError), Ord(HighestSeverityAtLine(ReceivedDiagnostics, 3)));
        AssertEquals(Ord(ldsWarning), Ord(HighestSeverityAtLine(ReceivedDiagnostics, 4)));
    finally
        Client.Free;
    end;
end;

initialization
    RegisterTest(TLspClientThreadTests);

end.
