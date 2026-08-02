unit External_File_Controller;

{$MODE objfpc}
{$H+}

interface

uses
    Document_State,
    File_Change_Controller,
    Forms,
    Language_Server_Controller,
    Preferences,
    StdCtrls;

type
    TDocumentStateChangedEvent = procedure of object;

    TExternalFileController = class
    private
        Document: PDocumentState;
        EditorMemo: TMemo;
        FileChanges: TFileChangeController;
        ForceNextCheck: Boolean;
        LanguageServer: TLanguageServerController;
        MonitoringMode: TFileMonitoringMode;
        OwnerForm: TCustomForm;
        SignalNextUpdate: Boolean;
        StateChangedHandler: TDocumentStateChangedEvent;
        procedure ApplyContent(const Content: string; const Encoding: TDocumentEncoding);
        procedure CheckExternalFile(Sender: TObject);
        procedure NotifyStateChanged;
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
    Files,
    LCLIntf,
    LCLType,
    SysUtils,
    Windows;

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
    FileChanges := TFileChangeController.Create(OwnerForm, @CheckExternalFile);
end;

destructor TExternalFileController.Destroy;
begin
    FileChanges.Free;
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

procedure TExternalFileController.CheckExternalFile(Sender: TObject);
var
    Choice: Integer;
    ExternalContent: string;
    ExternalEncoding: TDocumentEncoding;
    ForceUpdate: Boolean;
    PromptText: string;
    SignalUpdate: Boolean;
begin
    ForceUpdate := ForceNextCheck;
    SignalUpdate := SignalNextUpdate;
    ForceNextCheck := False;
    SignalNextUpdate := False;
    if ((MonitoringMode = fmmDisabled) and not ForceUpdate) or (Document^.FileName = '') then
        Exit;
    if not FileExists(Document^.FileName) then
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
    try
        ExternalContent := AdjustLineBreaks(ReadTextFile(Document^.FileName, ExternalEncoding), tlbsCRLF);
    except
        FileChanges.ScheduleCheck;
        ForceNextCheck := ForceUpdate;
        SignalNextUpdate := SignalUpdate;
        Exit;
    end;
    Document^.MissingOnDisk := False;
    if ExternalContent = Document^.SavedContent then
    begin
        Document^.Encoding := ExternalEncoding;
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
        ApplyContent(ExternalContent, ExternalEncoding);
        if SignalUpdate then
            Windows.MessageBeep(MB_OK);
    end
    else
    begin
        Document^.Encoding := ExternalEncoding;
        Document^.SavedContent := ExternalContent;
        NotifyStateChanged;
    end;
end;

procedure TExternalFileController.Configure(TheMonitoringMode: TFileMonitoringMode; const FileName: string);
begin
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
    CheckExternalFile(Self);
end;

procedure TExternalFileController.Stop;
begin
    FileChanges.Stop;
end;

procedure TExternalFileController.Watch(const FileName: string);
begin
    if MonitoringMode = fmmDisabled then
        FileChanges.Stop
    else
        FileChanges.Watch(FileName);
end;

end.
