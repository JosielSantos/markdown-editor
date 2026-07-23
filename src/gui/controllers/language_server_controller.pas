unit Language_Server_Controller;

{$MODE objfpc}
{$H+}

interface

uses
    Classes,
    ExtCtrls,
    Forms,
    Lsp_Client_Thread,
    Lsp_Diagnostics;

type
    TDiagnosticLineEvent = procedure(LineNumber: Integer) of object;

    TLanguageServerController = class
    private
        ActiveDocumentUri: string;
        ChangeDueAt: QWord;
        ChangePending: Boolean;
        Client: TLspClientThread;
        Diagnostics: TLspDiagnosticArray;
        NavigateToLineHandler: TDiagnosticLineEvent;
        OwnerForm: TCustomForm;
        PendingText: string;
        Timer: TTimer;
        procedure DiagnosticsReceived(
            Sender: TObject;
            const DocumentUri: string;
            const NewDiagnostics: TLspDiagnosticArray
        );
        procedure LanguageServerError(Sender: TObject; const ErrorMessage: string);
        procedure TimerTick(Sender: TObject);
    public
        constructor Create(TheOwnerForm: TCustomForm; TheNavigateToLineHandler: TDiagnosticLineEvent);
        destructor Destroy; override;
        procedure CloseDocument;
        procedure DocumentChanged(const Text: string);
        procedure DocumentSaved(const FileName, Text: string);
        procedure OpenDocument(const FileName, Text: string);
        procedure ShowProblems;
        procedure Start(const ServerExecutableFileName: string);
        procedure Stop;
    end;

function DefaultLanguageServerExecutableFileName: string;

implementation

uses
    LCLIntf,
    LCLType,
    Lsp_Protocol,
    Problems,
    SysUtils,
    URIParser;

const
    ChangeDelayMilliseconds = 350;
    TimerIntervalMilliseconds = 100;

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

constructor TLanguageServerController.Create(TheOwnerForm: TCustomForm; TheNavigateToLineHandler: TDiagnosticLineEvent);
begin
    OwnerForm := TheOwnerForm;
    NavigateToLineHandler := TheNavigateToLineHandler;
    Timer := TTimer.Create(OwnerForm);
    Timer.Enabled := False;
    Timer.Interval := TimerIntervalMilliseconds;
    Timer.OnTimer := @TimerTick;
end;

destructor TLanguageServerController.Destroy;
begin
    Stop;
    Timer.Free;
    inherited Destroy;
end;

procedure TLanguageServerController.LanguageServerError(Sender: TObject; const ErrorMessage: string);
begin
    if (Sender <> nil) and (Sender <> Client) then
        Exit;
    Stop;
    LCLIntf.MessageBox(OwnerForm.Handle, PChar(ErrorMessage), 'Erro no servidor de linguagem', MB_OK or MB_ICONERROR);
end;

procedure TLanguageServerController.Start(const ServerExecutableFileName: string);
begin
    if ServerExecutableFileName = '' then
    begin
        LanguageServerError(nil, 'O executável do verificador de Markdown não foi configurado.');
        Exit;
    end;
    if not FileExists(ServerExecutableFileName) then
    begin
        LanguageServerError(
            nil,
            Format(
                'O executável do verificador de Markdown não foi encontrado:%s%s',
                [LineEnding, ServerExecutableFileName]
            )
        );
        Exit;
    end;
    Stop;
    Client := TLspClientThread.Create(ServerExecutableFileName, @DiagnosticsReceived, @LanguageServerError);
    Timer.Enabled := True;
end;

procedure TLanguageServerController.Stop;
begin
    Timer.Enabled := False;
    ChangePending := False;
    SetLength(Diagnostics, 0);
    ActiveDocumentUri := '';
    FreeAndNil(Client);
end;

procedure TLanguageServerController.OpenDocument(const FileName, Text: string);
var
    DocumentUri: string;
begin
    if not Assigned(Client) or (FileName = '') then
        Exit;
    DocumentUri := FilenameToURI(ExpandFileName(FileName));
    if SameText(DocumentUri, ActiveDocumentUri) then
    begin
        Client.ChangeDocument(Text);
        Exit;
    end;
    ChangePending := False;
    SetLength(Diagnostics, 0);
    ActiveDocumentUri := DocumentUri;
    Client.OpenDocument(DocumentUri, Text);
end;

procedure TLanguageServerController.CloseDocument;
begin
    ChangePending := False;
    SetLength(Diagnostics, 0);
    ActiveDocumentUri := '';
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
    if not SameText(DocumentUri, ActiveDocumentUri) then
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
end;

procedure TLanguageServerController.ShowProblems;
var
    LineNumber: Integer;
begin
    if ChooseProblemLine(OwnerForm, Diagnostics, LineNumber) and Assigned(NavigateToLineHandler) then
        NavigateToLineHandler(LineNumber);
end;
procedure TLanguageServerController.TimerTick(Sender: TObject);
begin
    if ChangePending and (GetTickCount64 >= ChangeDueAt) then
    begin
        ChangePending := False;
        Client.ChangeDocument(PendingText);
    end;
end;

end.
