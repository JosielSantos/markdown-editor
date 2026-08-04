unit Document_Controller;

{$MODE objfpc}
{$H+}

interface

uses
    Classes,
    Document_State,
    Editor_Preferences,
    External_File_Controller,
    Language_Server_Controller,
    Main_Form,
    Recent_Files_Controller,
    Session_Controller;

type
    TDocumentController = class
    private
        Document: TDocumentState;
        ExternalFiles: TExternalFileController;
        Form: TEditorForm;
        LanguageServer: TLanguageServerController;
        RecentFiles: TRecentFilesController;
        Session: TSessionController;
        UpdatingEditor: Boolean;
        function GetDocumentState: TDocumentState;
        function GetFileName: string;
        function HandleUnsavedChanges: Boolean;
        function LoadMarkdownDocumentSilently(const FileName: string): Boolean;
        procedure MarkDocumentSaved;
        procedure OpenRecentMarkdown(const FileName: string);
        function SaveCurrentDocument: Boolean;
        function SaveDocumentAs: Boolean;
        function SaveDocumentTo(const FileName: string; const Encoding: TDocumentEncoding): Boolean;
        procedure SetDocumentState(const NewState: TDocumentState);
        procedure SetEditorText(const Text: string);
        function TryLoadMarkdownDocument(const FileName: string; ReportErrors: Boolean): Boolean;
        procedure UpdateWindowTitle;
    public
        constructor Create(
            TheForm: TEditorForm;
            TheLanguageServer: TLanguageServerController;
            MonitoringMode: TFileMonitoringMode;
            const SettingsFileName: string
        );
        destructor Destroy; override;
        procedure CanCloseEditor(Sender: TObject; var CanClose: Boolean);
        procedure ConfigureMonitoring(MonitoringMode: TFileMonitoringMode);
        procedure EditorChanged(Sender: TObject);
        procedure InitializeMarkdownDocument(const FileName: string);
        function LoadMarkdownDocument(const FileName: string): Boolean;
        procedure NewDocument(Sender: TObject);
        procedure OpenMarkdown(Sender: TObject);
        procedure RefreshDocument(Sender: TObject);
        procedure RestoreLastSession;
        procedure SaveMarkdown(Sender: TObject);
        procedure SaveMarkdownAs(Sender: TObject);
        property FileName: string read GetFileName;
    end;

implementation

uses
    Files,
    SysUtils;

constructor TDocumentController.Create(
    TheForm: TEditorForm;
    TheLanguageServer: TLanguageServerController;
    MonitoringMode: TFileMonitoringMode;
    const SettingsFileName: string
);
begin
    inherited Create;
    Form := TheForm;
    LanguageServer := TheLanguageServer;
    Document := CreateDocumentState;
    Session := TSessionController.Create(Form, Form.EditorControl, @LoadMarkdownDocumentSilently, SettingsFileName);
    RecentFiles := TRecentFilesController.Create(Form, Form.RecentFilesMenuItem, @OpenRecentMarkdown, SettingsFileName);
    ExternalFiles :=
        TExternalFileController
            .Create(Form, Form.EditorControl, LanguageServer, @GetDocumentState, @SetDocumentState, MonitoringMode);
    UpdateWindowTitle;
end;

destructor TDocumentController.Destroy;
begin
    ExternalFiles.Free;
    Session.Free;
    RecentFiles.Free;
    inherited Destroy;
end;

function TDocumentController.GetDocumentState: TDocumentState;
begin
    Result := Document;
end;

function TDocumentController.GetFileName: string;
begin
    Result := Document.FileName;
end;

procedure TDocumentController.SetDocumentState(const NewState: TDocumentState);
begin
    Document := NewState;
    UpdateWindowTitle;
end;

procedure TDocumentController.SetEditorText(const Text: string);
begin
    UpdatingEditor := True;
    try
        Form.DocumentText := Text;
    finally
        UpdatingEditor := False;
    end;
end;

procedure TDocumentController.CanCloseEditor(Sender: TObject; var CanClose: Boolean);
begin
    CanClose := HandleUnsavedChanges;
    if CanClose then
        Session.Persist(Document.FileName);
end;

procedure TDocumentController.ConfigureMonitoring(MonitoringMode: TFileMonitoringMode);
begin
    ExternalFiles.Configure(MonitoringMode, Document.FileName);
end;

procedure TDocumentController.EditorChanged(Sender: TObject);
begin
    if UpdatingEditor then
        Exit;
    LanguageServer.DocumentChanged(Form.DocumentText);
    UpdateWindowTitle;
end;

function TDocumentController.HandleUnsavedChanges: Boolean;
begin
    if not HasUnsavedChanges(Form.DocumentText, Document) then
        Exit(True);
    case Form.ConfirmUnsavedChanges of
        uccSave: Result := SaveCurrentDocument;
        uccDiscard: Result := True;
    else
        Result := False;
    end;
end;

procedure TDocumentController.NewDocument(Sender: TObject);
begin
    if not HandleUnsavedChanges then
        Exit;
    Session.RememberFilePosition(Document.FileName);
    LanguageServer.CloseDocument;
    ExternalFiles.Stop;
    SetEditorText('');
    Document := CreateDocumentState;
    MarkDocumentSaved;
end;

procedure TDocumentController.InitializeMarkdownDocument(const FileName: string);
begin
    if FileExists(FileName) then
    begin
        LoadMarkdownDocument(FileName);
        Exit;
    end;
    LanguageServer.CloseDocument;
    ExternalFiles.Stop;
    SetEditorText('');
    Document := CreateDocumentState(ExpandFileName(FileName));
    MarkDocumentSaved;
    ExternalFiles.Watch(Document.FileName);
    LanguageServer.OpenDocument(Document.FileName, Form.DocumentText);
end;

function TDocumentController.LoadMarkdownDocument(const FileName: string): Boolean;
begin
    Result := TryLoadMarkdownDocument(FileName, True);
end;

function TDocumentController.LoadMarkdownDocumentSilently(const FileName: string): Boolean;
begin
    Result := TryLoadMarkdownDocument(FileName, False);
end;

function TDocumentController.TryLoadMarkdownDocument(const FileName: string; ReportErrors: Boolean): Boolean;
var
    LoadedContent: string;
    LoadedEncoding: TDocumentEncoding;
    ResolvedFileName: string;
begin
    Result := False;
    ResolvedFileName := ExpandFileName(FileName);
    try
        LoadedContent := ReadTextFile(ResolvedFileName, LoadedEncoding);
    except
        on Error: Exception do
        begin
            if ReportErrors then
                Form.ShowErrorMessage('Erro ao abrir arquivo', Error.Message);
            Exit;
        end;
    end;
    Session.RememberFilePosition(Document.FileName);
    LanguageServer.CloseDocument;
    ExternalFiles.Stop;
    SetEditorText(LoadedContent);
    Document := CreateDocumentState(ResolvedFileName);
    Document.Encoding := LoadedEncoding;
    MarkDocumentSaved;
    RecentFiles.Remember(Document.FileName);
    Session.RestoreFilePosition(Document.FileName);
    ExternalFiles.Watch(Document.FileName);
    LanguageServer.OpenDocument(Document.FileName, Form.DocumentText);
    Result := True;
end;

procedure TDocumentController.MarkDocumentSaved;
begin
    Document.SavedContent := Form.DocumentText;
    Document.MissingOnDisk := False;
    UpdateWindowTitle;
end;

procedure TDocumentController.OpenMarkdown(Sender: TObject);
var
    SelectedFileName: string;
begin
    if not HandleUnsavedChanges then
        Exit;
    if Form.SelectMarkdownFileToOpen(SelectedFileName) then
        LoadMarkdownDocument(SelectedFileName);
end;

procedure TDocumentController.OpenRecentMarkdown(const FileName: string);
begin
    if not HandleUnsavedChanges then
        Exit;
    LoadMarkdownDocument(FileName);
end;

procedure TDocumentController.RefreshDocument(Sender: TObject);
begin
    ExternalFiles.Refresh;
end;

procedure TDocumentController.RestoreLastSession;
begin
    RecentFiles.RemoveMissingFiles;
    Session.Restore;
end;

function TDocumentController.SaveCurrentDocument: Boolean;
begin
    if Document.FileName = '' then
        Exit(SaveDocumentAs);
    Result := SaveDocumentTo(Document.FileName, Document.Encoding);
end;

function TDocumentController.SaveDocumentAs: Boolean;
var
    SelectedEncoding: TDocumentEncoding;
    SelectedFileName: string;
begin
    Result := False;
    if not Form.SelectMarkdownFileToSave(Document.FileName, Document.Encoding, SelectedFileName, SelectedEncoding) then
        Exit;
    Result := SaveDocumentTo(SelectedFileName, SelectedEncoding);
end;

function TDocumentController.SaveDocumentTo(const FileName: string; const Encoding: TDocumentEncoding): Boolean;
begin
    Result := False;
    try
        WriteTextFile(FileName, Form.DocumentText, Encoding);
        Document.FileName := FileName;
        Document.Encoding := Encoding;
        MarkDocumentSaved;
        RecentFiles.Remember(Document.FileName);
        Session.RememberFilePosition(Document.FileName);
        ExternalFiles.Watch(Document.FileName);
        LanguageServer.DocumentSaved(Document.FileName, Form.DocumentText);
        Result := True;
    except
        on Error: Exception do
            Form.ShowErrorMessage('Erro ao salvar arquivo', Error.Message);
    end;
end;

procedure TDocumentController.SaveMarkdown(Sender: TObject);
begin
    SaveCurrentDocument;
end;

procedure TDocumentController.SaveMarkdownAs(Sender: TObject);
begin
    Session.RememberFilePosition(Document.FileName);
    SaveDocumentAs;
end;

procedure TDocumentController.UpdateWindowTitle;
begin
    Form.UpdateDocumentTitle(Document.FileName, HasUnsavedChanges(Form.DocumentText, Document));
end;

end.
