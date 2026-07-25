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
        InitializationResponseFileName: string;
        ReceivedDiagnostics: TLspDiagnosticArray;
        ReceivedDocumentUri: string;
        ServerReady: Boolean;
        ServerError: string;
        procedure AssertInitializationFails(const ResponseFileName, ExpectedError: string);
        procedure HandleDiagnostics(Sender: TObject; const DocumentUri: string; const Diagnostics: TLspDiagnosticArray);
        procedure HandleError(Sender: TObject; const ErrorMessage: string);
        procedure HandleReady(Sender: TObject);
        procedure ResetState;
        function SelectFakeLanguageServerResponse(const JsonText: string): string;
    published
        procedure ReceivesDiagnosticsFromFakeLanguageServer;
        procedure RejectsInvalidInitializationResponse;
        procedure ReportsInitializationError;
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

procedure TLspClientThreadTests.ResetState;
begin
    DiagnosticsReceived := False;
    InitializationResponseFileName := 'responses/initialization/valid_response.json';
    SetLength(ReceivedDiagnostics, 0);
    ReceivedDocumentUri := '';
    ServerReady := False;
    ServerError := '';
end;

function TLspClientThreadTests.SelectFakeLanguageServerResponse(const JsonText: string): string;
var
    ExpectedResponseFileName: string;
begin
    ExpectedResponseFileName := '';
    if (Pos('"method"', JsonText) > 0) and (Pos('"initialize"', JsonText) > 0) then
        ExpectedResponseFileName := InitializationResponseFileName
    else if (Pos('"method"', JsonText) > 0) and (Pos('"textDocument/didOpen"', JsonText) > 0) then
        ExpectedResponseFileName := 'notifications/diagnostics/valid_diagnostics.json';
    Result := JsonText;
    if ExpectedResponseFileName <> '' then
        Insert(',"expected_response_file_name":"' + ExpectedResponseFileName + '"', Result, Length(Result));
end;

procedure TLspClientThreadTests.AssertInitializationFails(const ResponseFileName, ExpectedError: string);
var
    Client: TLspClientThread;
    Deadline: QWord;
begin
    AssertTrue('Fake Markdown LSP não encontrado', FileExists(FakeLanguageServerFileName));
    ResetState;
    InitializationResponseFileName := ResponseFileName;
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
        Deadline := GetTickCount64 + ResponseTimeoutMilliseconds;
        while not ServerReady and (ServerError = '') and (GetTickCount64 < Deadline) do
        begin
            CheckSynchronize(20);
            Sleep(10);
        end;
        AssertFalse('o fake Markdown LSP não deveria ficar pronto', ServerReady);
        AssertEquals(ExpectedError, ServerError);
    finally
        Client.Free;
    end;
end;

procedure TLspClientThreadTests.ReceivesDiagnosticsFromFakeLanguageServer;
var
    Client: TLspClientThread;
    Deadline: QWord;
    DocumentUri: string;
begin
    AssertTrue('Fake Markdown LSP não encontrado', FileExists(FakeLanguageServerFileName));
    ResetState;
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

procedure TLspClientThreadTests.ReportsInitializationError;
begin
    AssertInitializationFails(
        'responses/initialization/error_response.json',
        'O servidor de linguagem recusou a inicialização (-32002): Falha simulada na inicialização'
    );
end;

procedure TLspClientThreadTests.RejectsInvalidInitializationResponse;
begin
    AssertInitializationFails(
        'responses/initialization/invalid_response.json',
        'O servidor de linguagem enviou uma resposta de inicialização inválida.'
    );
end;

initialization
    RegisterTest(TLspClientThreadTests);

end.
