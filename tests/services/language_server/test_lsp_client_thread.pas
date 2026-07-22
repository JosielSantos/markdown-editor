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
        ServerError: string;
        procedure HandleDiagnostics(Sender: TObject; const DocumentUri: string; const Diagnostics: TLspDiagnosticArray);
        procedure HandleError(Sender: TObject; const ErrorMessage: string);
    published
        procedure ReceivesMarksmanDiagnostics;
    end;

implementation

uses
    Classes,
    Lsp_Protocol,
    SysUtils,
    URIParser;

const
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

procedure TLspClientThreadTests.ReceivesMarksmanDiagnostics;
var
    Client: TLspClientThread;
    Deadline: QWord;
    DocumentUri: string;
begin
    AssertTrue('marksman.exe não encontrado', FileExists('marksman.exe'));
    DiagnosticsReceived := False;
    SetLength(ReceivedDiagnostics, 0);
    ReceivedDocumentUri := '';
    ServerError := '';
    DocumentUri := FilenameToURI(ExpandFileName('teste-lsp-temporario.md'));
    Client := TLspClientThread.Create('marksman.exe', @HandleDiagnostics, @HandleError);
    try
        Client.OpenDocument(
            DocumentUri,
            '# Teste' + LineEnding + LineEnding + '[[#ausente]]' + LineEnding + '##' + #$C2#$A0 + 'Aviso'
        );
        Deadline := GetTickCount64 + ResponseTimeoutMilliseconds;
        while not DiagnosticsReceived and (ServerError = '') and (GetTickCount64 < Deadline) do
        begin
            CheckSynchronize(20);
            Sleep(10);
        end;
        AssertEquals('erro inesperado do Marksman', '', ServerError);
        AssertTrue('o Marksman não publicou diagnósticos', DiagnosticsReceived);
        AssertTrue('URI devolvida pelo Marksman', DocumentUrisMatch(DocumentUri, ReceivedDocumentUri));
        AssertTrue('o Marksman não identificou a âncora inválida', Length(ReceivedDiagnostics) > 0);
        AssertEquals(Ord(ldsError), Ord(HighestSeverityAtLine(ReceivedDiagnostics, 3)));
        AssertEquals(Ord(ldsWarning), Ord(HighestSeverityAtLine(ReceivedDiagnostics, 4)));
    finally
        Client.Free;
    end;
end;

initialization
    RegisterTest(TLspClientThreadTests);

end.
