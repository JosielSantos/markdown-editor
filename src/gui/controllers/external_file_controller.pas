unit External_File_Controller;

{$MODE objfpc}
{$H+}

interface

uses
    Async_File_Reader,
    Document_State,
    ExtCtrls,
    File_Change_Controller,
    Forms,
    Language_Server_Controller,
    Preferences,
    StdCtrls;

type
    TDocumentStateChangedEvent = procedure of object;

    TExternalFileController = class
    private
        ActiveReadId: QWord;
        CheckAgain: Boolean;
        Document: PDocumentState;
        EditorMemo: TMemo;
        FileChanges: TFileChangeController;
        FileReader: TAsyncFileReader;
        ForceNextCheck: Boolean;
        ForcePending: Boolean;
        HandlingResult: Boolean;
        LanguageServer: TLanguageServerController;
        MonitoringMode: TFileMonitoringMode;
        OwnerForm: TCustomForm;
        ReadTimer: TTimer;
        SignalNextUpdate: Boolean;
        SignalPending: Boolean;
        StateChangedHandler: TDocumentStateChangedEvent;
        procedure ApplyContent(const Content: string; const Encoding: TDocumentEncoding);
        procedure CancelRead;
        procedure HandleReadResult(const ReadResult: TAsyncFileReadResult);
        procedure NotifyStateChanged;
        procedure ReadTimerTick(Sender: TObject);
        procedure RequestExternalFile(Sender: TObject);
    public
        constructor Create(
            TheOwnerForm: TCustomForm;
            TheEditorMemo: TMemo;
            TheLanguageServer: TLanguageServerController;
            TheDocument: PDocumentState;
            TheMonitoringMode: TFileMonitoringMode;
            TheStateChangedHandler: TDocumentStateChangedEvent
        );
        destructor Destroy; override;
        procedure Configure(TheMonitoringMode: TFileMonitoringMode; const FileName: string);
        procedure Refresh;
        procedure Stop;
        procedure Watch(const FileName: string);
    end;

implementation

uses
    LCLIntf,
    LCLType,
    SysUtils,
    Windows;

const
    ReadPollingMilliseconds = 50;

constructor TExternalFileController.Create(
    TheOwnerForm: TCustomForm;
    TheEditorMemo: TMemo;
    TheLanguageServer: TLanguageServerController;
    TheDocument: PDocumentState;
    TheMonitoringMode: TFileMonitoringMode;
    TheStateChangedHandler: TDocumentStateChangedEvent
);
begin
    OwnerForm := TheOwnerForm;
    EditorMemo := TheEditorMemo;
    LanguageServer := TheLanguageServer;
    Document := TheDocument;
    MonitoringMode := TheMonitoringMode;
    StateChangedHandler := TheStateChangedHandler;
    FileReader := TAsyncFileReader.Create;
    ReadTimer := TTimer.Create(OwnerForm);
    ReadTimer.Enabled := False;
    ReadTimer.Interval := ReadPollingMilliseconds;
    ReadTimer.OnTimer := @ReadTimerTick;
    FileChanges := TFileChangeController.Create(OwnerForm, @RequestExternalFile);
end;

destructor TExternalFileController.Destroy;
begin
    FileChanges.Free;
    ReadTimer.Free;
    FileReader.Free;
    inherited Destroy;
end;

procedure TExternalFileController.ApplyContent(const Content: string; const Encoding: TDocumentEncoding);
var
    CaretPosition: Integer;
    SelectionLength: Integer;
begin
    CaretPosition := EditorMemo.SelStart;
    SelectionLength := EditorMemo.SelLength;
    EditorMemo.Lines.BeginUpdate;
    try
        EditorMemo.Text := Content;
    finally
        EditorMemo.Lines.EndUpdate;
    end;
    Document^.Encoding := Encoding;
    Document^.MissingOnDisk := False;
    Document^.SavedContent := EditorMemo.Text;
    if CaretPosition > Length(EditorMemo.Text) then
        CaretPosition := Length(EditorMemo.Text);
    EditorMemo.SelStart := CaretPosition;
    if SelectionLength > Length(EditorMemo.Text) - CaretPosition then
        SelectionLength := Length(EditorMemo.Text) - CaretPosition;
    EditorMemo.SelLength := SelectionLength;
    LanguageServer.DocumentSaved(Document^.FileName, EditorMemo.Text);
    NotifyStateChanged;
end;

procedure TExternalFileController.CancelRead;
begin
    FileReader.Cancel;
    ReadTimer.Enabled := False;
    CheckAgain := False;
    ActiveReadId := 0;
    ForceNextCheck := False;
    ForcePending := False;
    SignalNextUpdate := False;
    SignalPending := False;
end;

procedure TExternalFileController.HandleReadResult(const ReadResult: TAsyncFileReadResult);
var
    Choice: Integer;
    ForceUpdate: Boolean;
    PromptText: string;
    SignalUpdate: Boolean;
begin
    if not SameFileName(ReadResult.FileName, Document^.FileName) then
    begin
        CancelRead;
        Exit;
    end;
    if ReadResult.Status = afrsError then
    begin
        FileChanges.ScheduleCheck;
        Exit;
    end;
    ForceUpdate := ForcePending;
    SignalUpdate := SignalPending;
    ForcePending := False;
    SignalPending := False;
    if ReadResult.Status = afrsMissing then
    begin
        if Document^.MissingOnDisk then
            Exit;
        Document^.MissingOnDisk := True;
        NotifyStateChanged;
        LCLIntf.MessageBox(
            OwnerForm.Handle,
            'O arquivo aberto não existe mais. O conteúdo foi mantido no editor.',
            'Arquivo removido',
            MB_OK or MB_ICONWARNING
        );
        Exit;
    end;
    Document^.MissingOnDisk := False;
    if not ReadResult.Changed then
    begin
        Document^.Encoding := ReadResult.Encoding;
        NotifyStateChanged;
        Exit;
    end;
    if ForceUpdate or (MonitoringMode = fmmAutomatic) then
        Choice := IDYES
    else
    begin
        PromptText := 'O arquivo foi alterado por outro programa. Deseja atualizar o editor?';
        if HasContentChanged(EditorMemo.Text, Document^.SavedContent) then
            PromptText :=
                'O arquivo foi alterado por outro programa. Deseja recarregá-lo e descartar as alterações deste editor?';
        Choice :=
            LCLIntf.MessageBox(
                OwnerForm.Handle,
                PChar(PromptText),
                'Arquivo alterado',
                MB_ICONQUESTION or MB_YESNO or MB_DEFBUTTON2
            );
    end;
    if Choice = IDYES then
    begin
        ApplyContent(ReadResult.Content, ReadResult.Encoding);
        if SignalUpdate then
            Windows.MessageBeep(MB_OK);
    end
    else
    begin
        Document^.Encoding := ReadResult.Encoding;
        Document^.SavedContent := ReadResult.Content;
        NotifyStateChanged;
    end;
end;

procedure TExternalFileController.ReadTimerTick(Sender: TObject);
var
    CheckAfterHandling: Boolean;
    ReadResult: TAsyncFileReadResult;
begin
    if not FileReader.TryTakeResult(ReadResult) then
        Exit;
    if ReadResult.RequestId <> ActiveReadId then
        Exit;
    ReadTimer.Enabled := False;
    ActiveReadId := 0;
    HandlingResult := True;
    try
        HandleReadResult(ReadResult);
    finally
        HandlingResult := False;
        CheckAfterHandling := CheckAgain;
        CheckAgain := False;
    end;
    if CheckAfterHandling then
        RequestExternalFile(Self);
end;

procedure TExternalFileController.RequestExternalFile(Sender: TObject);
var
    ForceUpdate: Boolean;
    SignalUpdate: Boolean;
begin
    ForceUpdate := ForceNextCheck;
    SignalUpdate := SignalNextUpdate;
    ForceNextCheck := False;
    SignalNextUpdate := False;
    if ((MonitoringMode = fmmDisabled) and not ForceUpdate) or (Document^.FileName = '') then
        Exit;
    ForcePending := ForcePending or ForceUpdate;
    SignalPending := SignalPending or SignalUpdate;
    if HandlingResult then
    begin
        CheckAgain := True;
        Exit;
    end;
    ActiveReadId := FileReader.Request(Document^.FileName, Document^.SavedContent);
    ReadTimer.Enabled := True;
end;

procedure TExternalFileController.Configure(TheMonitoringMode: TFileMonitoringMode; const FileName: string);
begin
    CancelRead;
    MonitoringMode := TheMonitoringMode;
    if MonitoringMode = fmmDisabled then
        FileChanges.Stop
    else
        FileChanges.Watch(FileName);
end;

procedure TExternalFileController.NotifyStateChanged;
begin
    if Assigned(StateChangedHandler) then
        StateChangedHandler;
end;

procedure TExternalFileController.Refresh;
begin
    ForceNextCheck := True;
    SignalNextUpdate := True;
    RequestExternalFile(Self);
end;

procedure TExternalFileController.Stop;
begin
    CancelRead;
    FileChanges.Stop;
end;

procedure TExternalFileController.Watch(const FileName: string);
begin
    CancelRead;
    if MonitoringMode = fmmDisabled then
        FileChanges.Stop
    else
        FileChanges.Watch(FileName);
end;

end.
