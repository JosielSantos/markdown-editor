unit Language_Server_Controller;

{$MODE objfpc}
{$H+}

interface

uses
    Classes,
    ExtCtrls,
    Forms,
    Lsp_Client_Thread,
    Lsp_Diagnostics,
    StdCtrls;

type
    TDiagnosticLineEvent = procedure(LineNumber: Integer) of object;

    TLanguageServerController = class
    private
        ActiveDocumentUri: string;
        ChangeDueAt: QWord;
        ChangePending: Boolean;
        Client: TLspClientThread;
        Diagnostics: TLspDiagnosticArray;
        EditorMemo: TMemo;
        LastCaretLine: Integer;
        LastSignaledLine: Integer;
        LastSignaledSeverity: TLspDiagnosticSeverity;
        NavigateToLineHandler: TDiagnosticLineEvent;
        OwnerForm: TCustomForm;
        PendingText: string;
        ServerArguments: string;
        ServerExecutableFileName: string;
        ServerInitializationDueAt: QWord;
        StartErrorHandler: TLspErrorEvent;
        StartReadyHandler: TNotifyEvent;
        Timer: TTimer;
        WaitingForInitialization: Boolean;
        procedure CheckCaretDiagnostic;
        procedure DiagnosticsReceived(
            Sender: TObject;
            const DocumentUri: string;
            const NewDiagnostics: TLspDiagnosticArray
        );
        procedure LanguageServerError(Sender: TObject; const ErrorMessage: string);
        procedure LanguageServerReady(Sender: TObject);
        procedure TimerTick(Sender: TObject);
    public
        constructor Create(
            TheOwnerForm: TCustomForm;
            TheEditorMemo: TMemo;
            TheNavigateToLineHandler: TDiagnosticLineEvent
        );
        destructor Destroy; override;
        procedure CloseDocument;
        procedure DocumentChanged(const Text: string);
        procedure DocumentSaved(const FileName, Text: string);
        function IsRunning: Boolean;
        procedure OpenDocument(const FileName, Text: string);
        procedure ShowProblems;
        procedure Start(
            const TheServerExecutableFileName, TheServerArguments: string;
            TheReadyHandler: TNotifyEvent = nil;
            TheErrorHandler: TLspErrorEvent = nil
        );
        procedure Stop;
        function UsesConfiguration(const TheServerExecutableFileName, TheServerArguments: string): Boolean;
    end;

function DefaultLanguageServerExecutableFileName: string;

implementation

uses
    Diagnostic_Sound,
    LCLIntf,
    LCLType,
    Lsp_Protocol,
    Problems,
    SysUtils,
    URIParser,
    Windows;

const
    ChangeDelayMilliseconds = 350;
    CaretPollingMilliseconds = 100;
    InitializationTimeoutMilliseconds = 10000;

function DefaultLanguageServerExecutableFileName: string;
var
    CandidateFileName: string;
begin
    CandidateFileName := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'marksman.exe';
    if FileExists(CandidateFileName) then
        Result := CandidateFileName
    else
        Result := '';
end;

constructor TLanguageServerController.Create(
    TheOwnerForm: TCustomForm;
    TheEditorMemo: TMemo;
    TheNavigateToLineHandler: TDiagnosticLineEvent
);
begin
    OwnerForm := TheOwnerForm;
    EditorMemo := TheEditorMemo;
    LastCaretLine := -1;
    LastSignaledLine := -1;
    NavigateToLineHandler := TheNavigateToLineHandler;
    Timer := TTimer.Create(OwnerForm);
    Timer.Enabled := False;
    Timer.Interval := CaretPollingMilliseconds;
    Timer.OnTimer := @TimerTick;
end;

destructor TLanguageServerController.Destroy;
begin
    Stop;
    Timer.Free;
    inherited Destroy;
end;

procedure TLanguageServerController.LanguageServerError(Sender: TObject; const ErrorMessage: string);
var
    ErrorHandler: TLspErrorEvent;
begin
    if (Sender <> nil) and (Sender <> Client) then
        Exit;
    ErrorHandler := StartErrorHandler;
    Stop;
    if Assigned(ErrorHandler) then
        ErrorHandler(Self, ErrorMessage)
    else
        LCLIntf
            .MessageBox(OwnerForm.Handle, PChar(ErrorMessage), 'Erro no servidor de linguagem', MB_OK or MB_ICONERROR);
end;

procedure TLanguageServerController.LanguageServerReady(Sender: TObject);
var
    ReadyHandler: TNotifyEvent;
begin
    if Sender <> Client then
        Exit;
    WaitingForInitialization := False;
    ReadyHandler := StartReadyHandler;
    StartReadyHandler := nil;
    StartErrorHandler := nil;
    if Assigned(ReadyHandler) then
        ReadyHandler(Self);
end;

procedure TLanguageServerController.Start(
    const TheServerExecutableFileName, TheServerArguments: string;
    TheReadyHandler: TNotifyEvent;
    TheErrorHandler: TLspErrorEvent
);
begin
    if TheServerExecutableFileName = '' then
    begin
        if Assigned(TheErrorHandler) then
            TheErrorHandler(Self, 'O executável do verificador de Markdown não foi configurado.')
        else
            LanguageServerError(nil, 'O executável do verificador de Markdown não foi configurado.');
        Exit;
    end;
    if not FileExists(TheServerExecutableFileName) then
    begin
        if Assigned(TheErrorHandler) then
            TheErrorHandler(
                Self,
                Format(
                    'O executável do verificador de Markdown não foi encontrado:%s%s',
                    [LineEnding, TheServerExecutableFileName]
                )
            )
        else
            LanguageServerError(
                nil,
                Format(
                    'O executável do verificador de Markdown não foi encontrado:%s%s',
                    [LineEnding, TheServerExecutableFileName]
                )
            );
        Exit;
    end;
    Stop;
    ServerExecutableFileName := ExpandFileName(TheServerExecutableFileName);
    ServerArguments := TheServerArguments;
    ServerInitializationDueAt := GetTickCount64 + InitializationTimeoutMilliseconds;
    StartReadyHandler := TheReadyHandler;
    StartErrorHandler := TheErrorHandler;
    WaitingForInitialization := True;
    Client :=
        TLspClientThread.Create(
            ServerExecutableFileName,
            ServerArguments,
            @DiagnosticsReceived,
            @LanguageServerError,
            @LanguageServerReady
        );
    Timer.Enabled := True;
end;

procedure TLanguageServerController.Stop;
begin
    Timer.Enabled := False;
    ChangePending := False;
    SetLength(Diagnostics, 0);
    ActiveDocumentUri := '';
    LastSignaledLine := -1;
    FreeAndNil(Client);
    ServerArguments := '';
    ServerExecutableFileName := '';
    StartErrorHandler := nil;
    StartReadyHandler := nil;
    WaitingForInitialization := False;
end;

function TLanguageServerController.IsRunning: Boolean;
begin
    Result := Assigned(Client);
end;

function TLanguageServerController.UsesConfiguration(
    const TheServerExecutableFileName,
    TheServerArguments: string
): Boolean;
begin
    Result :=
        Assigned(Client)
            and SameFileName(ServerExecutableFileName, ExpandFileName(TheServerExecutableFileName))
            and (ServerArguments = TheServerArguments);
end;

procedure TLanguageServerController.OpenDocument(const FileName, Text: string);
var
    DocumentUri: string;
begin
    if not Assigned(Client) or (FileName = '') then
        Exit;
    DocumentUri := FilenameToURI(ExpandFileName(FileName));
    if DocumentUrisMatch(DocumentUri, ActiveDocumentUri) then
    begin
        Client.ChangeDocument(Text);
        Exit;
    end;
    ChangePending := False;
    SetLength(Diagnostics, 0);
    ActiveDocumentUri := DocumentUri;
    LastSignaledLine := -1;
    Client.OpenDocument(DocumentUri, Text);
end;

procedure TLanguageServerController.CloseDocument;
begin
    ChangePending := False;
    SetLength(Diagnostics, 0);
    ActiveDocumentUri := '';
    LastSignaledLine := -1;
    if Assigned(Client) then
        Client.CloseDocument;
end;

procedure TLanguageServerController.DocumentChanged(const Text: string);
begin
    if not Assigned(Client) or (ActiveDocumentUri = '') then
        Exit;
    PendingText := Text;
    ChangeDueAt := GetTickCount64 + ChangeDelayMilliseconds;
    ChangePending := True;
end;

procedure TLanguageServerController.DocumentSaved(const FileName, Text: string);
var
    DocumentUri: string;
begin
    if not Assigned(Client) or (FileName = '') then
        Exit;
    DocumentUri := FilenameToURI(ExpandFileName(FileName));
    if not DocumentUrisMatch(DocumentUri, ActiveDocumentUri) then
        OpenDocument(FileName, Text)
    else
    begin
        ChangePending := False;
        Client.ChangeDocument(Text);
    end;
    Client.SaveDocument;
end;

procedure TLanguageServerController.DiagnosticsReceived(
    Sender: TObject;
    const DocumentUri: string;
    const NewDiagnostics: TLspDiagnosticArray
);
begin
    if not DocumentUrisMatch(DocumentUri, ActiveDocumentUri) then
        Exit;
    Diagnostics := Copy(NewDiagnostics, 0, Length(NewDiagnostics));
    CheckCaretDiagnostic;
end;

procedure TLanguageServerController.ShowProblems;
var
    LineNumber: Integer;
begin
    if ChooseProblemLine(OwnerForm, Diagnostics, LineNumber) and Assigned(NavigateToLineHandler) then
        NavigateToLineHandler(LineNumber);
end;

procedure TLanguageServerController.CheckCaretDiagnostic;
var
    CaretLine: Integer;
    Severity: TLspDiagnosticSeverity;
begin
    CaretLine := Integer(Windows.SendMessage(EditorMemo.Handle, EM_LINEFROMCHAR, EditorMemo.SelStart, 0)) + 1;
    if CaretLine <> LastCaretLine then
    begin
        LastCaretLine := CaretLine;
        LastSignaledLine := -1;
        LastSignaledSeverity := ldsNone;
    end;
    Severity := HighestSeverityAtLine(Diagnostics, CaretLine);
    if Severity = ldsNone then
    begin
        LastSignaledLine := -1;
        LastSignaledSeverity := ldsNone;
        Exit;
    end;
    if (LastSignaledLine = CaretLine) and (LastSignaledSeverity = Severity) then
        Exit;
    PlayDiagnosticSound(Severity);
    LastSignaledLine := CaretLine;
    LastSignaledSeverity := Severity;
end;

procedure TLanguageServerController.TimerTick(Sender: TObject);
begin
    if WaitingForInitialization and (GetTickCount64 >= ServerInitializationDueAt) then
    begin
        LanguageServerError(
            Client,
            'O servidor de linguagem não respondeu à inicialização dentro do tempo esperado.'
        );
        Exit;
    end;
    if ChangePending and (GetTickCount64 >= ChangeDueAt) then
    begin
        ChangePending := False;
        Client.ChangeDocument(PendingText);
    end;
    CheckCaretDiagnostic;
end;

end.
