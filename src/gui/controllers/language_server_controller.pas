unit Language_Server_Controller;

{$MODE objfpc}
{$H+}

interface

uses
    Classes,
    ExtCtrls,
    Forms,
    Lsp_Client_Thread;

type
    TLanguageServerController = class
    private
        ActiveDocumentUri: string;
        ChangeDueAt: QWord;
        ChangePending: Boolean;
        Client: TLspClientThread;
        OwnerForm: TCustomForm;
        PendingText: string;
        Timer: TTimer;
        procedure LanguageServerError(Sender: TObject; const ErrorMessage: string);
        procedure TimerTick(Sender: TObject);
    public
        constructor Create(TheOwnerForm: TCustomForm; const MarksmanFileName: string);
        destructor Destroy; override;
        procedure CloseDocument;
        procedure DocumentChanged(const Text: string);
        procedure DocumentSaved(const FileName, Text: string);
        procedure OpenDocument(const FileName, Text: string);
    end;

function DefaultMarksmanFileName: string;

implementation

uses
    LCLIntf,
    LCLType,
    SysUtils,
    URIParser;

const
    ChangeDelayMilliseconds = 350;
    TimerIntervalMilliseconds = 100;

function DefaultMarksmanFileName: string;
begin
    Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'marksman.exe';
end;

constructor TLanguageServerController.Create(TheOwnerForm: TCustomForm; const MarksmanFileName: string);
begin
    OwnerForm := TheOwnerForm;
    Timer := TTimer.Create(OwnerForm);
    Timer.Enabled := False;
    Timer.Interval := TimerIntervalMilliseconds;
    Timer.OnTimer := @TimerTick;
    if not FileExists(MarksmanFileName) then
    begin
        LanguageServerError(Self, 'O servidor de linguagem marksman.exe não foi encontrado.');
        Exit;
    end;
    Client := TLspClientThread.Create(MarksmanFileName, nil, @LanguageServerError);
    Timer.Enabled := True;
end;

destructor TLanguageServerController.Destroy;
begin
    Timer.Enabled := False;
    Client.Free;
    Timer.Free;
    inherited Destroy;
end;

procedure TLanguageServerController.LanguageServerError(Sender: TObject; const ErrorMessage: string);
begin
    LCLIntf.MessageBox(OwnerForm.Handle, PChar(ErrorMessage), 'Erro no servidor de linguagem', MB_OK or MB_ICONERROR);
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
    ActiveDocumentUri := DocumentUri;
    Client.OpenDocument(DocumentUri, Text);
end;

procedure TLanguageServerController.CloseDocument;
begin
    ChangePending := False;
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

procedure TLanguageServerController.TimerTick(Sender: TObject);
begin
    if ChangePending and (GetTickCount64 >= ChangeDueAt) then
    begin
        ChangePending := False;
        Client.ChangeDocument(PendingText);
    end;
end;

end.
