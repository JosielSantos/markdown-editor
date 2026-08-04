unit Main_Form;

{$MODE objfpc}
{$H+}

interface

uses
    Classes,
    Document_State,
    External_File_Controller,
    Forms,
    Language_Server_Controller,
    Options_Controller,
    Preferences,
    Recent_Files_Controller,
    Session_Controller,
    StdCtrls;

type
    TEditorForm = class(TForm)
    private
        Document: TDocumentState;
        EditorPreferences: TEditorPreferences;
        EditorMemo: TMemo;
        ExternalFiles: TExternalFileController;
        HtmlDocumentTemplate: string;
        LanguageServer: TLanguageServerController;
        RecentFiles: TRecentFilesController;
        OptionsController: TOptionsController;
        Session: TSessionController;
        procedure CanCloseEditor(Sender: TObject; var CanClose: Boolean);
        procedure CreateEditor;
        procedure CreateMenuBar;
        procedure EditorChanged(Sender: TObject);
        procedure ExitEditor(Sender: TObject);
        procedure ExportHtml(Sender: TObject);
        procedure ExportHtmlAs(Sender: TObject);
        procedure ExportHtmlToFile(const HtmlFileName: string);
        procedure GoToLine(Sender: TObject);
        function HandleUnsavedChanges: Boolean;
        procedure InsertLink(Sender: TObject);
        procedure MarkDocumentSaved;
        procedure NavigateToDiagnostic(LineNumber: Integer);
        procedure NewDocument(Sender: TObject);
        procedure OpenMarkdown(Sender: TObject);
        procedure OpenRecentMarkdown(const FileName: string);
        procedure RefreshDocument(Sender: TObject);
        function LoadMarkdownDocumentSilently(const FileName: string): Boolean;
        function SaveCurrentDocument: Boolean;
        function SaveDocumentAs: Boolean;
        function SaveDocumentTo(const FileName: string; const Encoding: TDocumentEncoding): Boolean;
        procedure SaveMarkdown(Sender: TObject);
        procedure SaveMarkdownAs(Sender: TObject);
        procedure ShowErrorMessage(const DialogTitle, ErrorMessage: string);
        procedure ShowOptions(Sender: TObject);
        procedure ShowProblems(Sender: TObject);
        procedure ShowPreview(Sender: TObject);
        function TryLoadMarkdownDocument(const FileName: string; ReportErrors: Boolean): Boolean;
        procedure UpdateWindowTitle;
    public
        constructor Create(TheOwner: TComponent); override;
        destructor Destroy; override;
        procedure InitializeMarkdownDocument(const FileName: string);
        procedure InitializeHtmlDocumentTemplate(const HtmlTemplate: string);
        function LoadMarkdownDocument(const FileName: string): Boolean;
        procedure RestoreLastSession;
    end;

var
    EditorForm: TEditorForm;

implementation

uses
    Controls,
    Dialogs,
    Accessibility,
    Editor_Menu,
    Files,
    Go_To_Line,
    Html_Export,
    Html_Export_Dialog,
    Insert_Link,
    LCLIntf,
    LCLType,
    Link,
    Markdown_Memo,
    Markdown_Save_Dialog,
    Menus,
    Preview_Form,
    Editor,
    SysUtils;

procedure TEditorForm.CreateEditor;
begin
    EditorMemo := TMarkdownMemo.Create(Self);
    EditorMemo.Parent := Self;
    EditorMemo.Align := alClient;
    EditorMemo.ScrollBars := ssAutoBoth;
    EditorMemo.WordWrap := False;
    EditorMemo.WantTabs := True;
    EditorMemo.Font.Name := 'Consolas';
    EditorMemo.Font.Size := 11;
    EditorMemo.AccessibleDescription := 'Digite Markdown. Pressione F9 para abrir a visualização.';
    EditorMemo.AccessibleRole := larTextEditorMultiline;
    SetControlAccessibleName(EditorMemo, 'Editor de texto Markdown');
    EditorMemo.OnChange := @EditorChanged;
    ActiveControl := EditorMemo;
end;

procedure TEditorForm.CreateMenuBar;
var
    Actions: TEditorMenuActions;
    RecentFilesMenu: TMenuItem;
begin
    Actions.NewDocument := @NewDocument;
    Actions.OpenDocument := @OpenMarkdown;
    Actions.RefreshDocument := @RefreshDocument;
    Actions.SaveDocument := @SaveMarkdown;
    Actions.SaveDocumentAs := @SaveMarkdownAs;
    Actions.ExportHtml := @ExportHtml;
    Actions.ExportHtmlAs := @ExportHtmlAs;
    Actions.ExitEditor := @ExitEditor;
    Actions.GoToLine := @GoToLine;
    Actions.InsertLink := @InsertLink;
    Actions.ShowOptions := @ShowOptions;
    Actions.ShowProblems := @ShowProblems;
    Actions.ShowPreview := @ShowPreview;
    Menu := BuildEditorMenu(Self, Actions, RecentFilesMenu);
    RecentFiles := TRecentFilesController.Create(Self, RecentFilesMenu, @OpenRecentMarkdown, DefaultSettingsFileName);
end;

constructor TEditorForm.Create(TheOwner: TComponent);
begin
    inherited CreateNew(TheOwner, 1);
    Caption := 'Markdown Editor';
    Position := poScreenCenter;
    Width := 900;
    Height := 650;
    EditorPreferences := LoadEditorPreferences(DefaultSettingsFileName, DefaultLanguageServerExecutableFileName);
    CreateMenuBar;
    CreateEditor;
    LanguageServer := TLanguageServerController.Create(Self, EditorMemo, @NavigateToDiagnostic);
    OptionsController := TOptionsController.Create(Self, EditorMemo, LanguageServer, DefaultSettingsFileName);
    if EditorPreferences.UseMarkdownChecker then
        LanguageServer
            .Start(EditorPreferences.MarkdownCheckerExecutableFileName, EditorPreferences.MarkdownCheckerArguments);
    Session := TSessionController.Create(Self, EditorMemo, @LoadMarkdownDocumentSilently, DefaultSettingsFileName);
    Document := CreateDocumentState;
    ExternalFiles :=
        TExternalFileController.Create(
            Self,
            EditorMemo,
            LanguageServer,
            @Document,
            EditorPreferences.FileMonitoringMode,
            @UpdateWindowTitle
        );
    OnCloseQuery := @CanCloseEditor;
    UpdateWindowTitle;
end;

destructor TEditorForm.Destroy;
begin
    ExternalFiles.Free;
    OptionsController.Free;
    LanguageServer.Free;
    Session.Free;
    RecentFiles.Free;
    inherited Destroy;
end;

procedure TEditorForm.InitializeHtmlDocumentTemplate(const HtmlTemplate: string);
begin
    HtmlDocumentTemplate := HtmlTemplate;
end;

procedure TEditorForm.CanCloseEditor(Sender: TObject; var CanClose: Boolean);
begin
    CanClose := HandleUnsavedChanges;
    if CanClose then
        Session.Persist(Document.FileName);
end;

procedure TEditorForm.EditorChanged(Sender: TObject);
begin
    LanguageServer.DocumentChanged(EditorMemo.Text);
    UpdateWindowTitle;
end;

procedure TEditorForm.ExitEditor(Sender: TObject);
begin
    Close;
end;

procedure TEditorForm.ExportHtml(Sender: TObject);
begin
    if Document.FileName = '' then
        ExportHtmlAs(Sender)
    else
        ExportHtmlToFile(HtmlExportFileName(Document.FileName));
end;

procedure TEditorForm.ExportHtmlAs(Sender: TObject);
var
    HtmlFileName: string;
begin
    if ChooseHtmlExportFile(Self, Document.FileName, HtmlFileName) then
        ExportHtmlToFile(HtmlFileName);
end;

procedure TEditorForm.ExportHtmlToFile(const HtmlFileName: string);
begin
    try
        ExportMarkdownToHtmlFile(EditorMemo.Text, HtmlDocumentTemplate, HtmlFileName);
    except
        on Error: Exception do
            ShowErrorMessage('Erro ao exportar HTML', Error.Message);
    end;
end;

procedure TEditorForm.GoToLine(Sender: TObject);
var
    SelectedLine: Integer;
begin
    if not ChooseLineNumber(Self, EditorMemo.CaretPos.Y + 1, EditorMemo.Lines.Count, SelectedLine) then
        Exit;
    Session.PositionCursorAtLine(SelectedLine);
end;

function TEditorForm.HandleUnsavedChanges: Boolean;
var
    Choice: Integer;
begin
    if not HasUnsavedChanges(EditorMemo.Text, Document) then
        Exit(True);
    Choice :=
        LCLIntf.MessageBox(
            Handle,
            'Deseja salvar as alterações antes de continuar?',
            'Alterações não salvas',
            MB_ICONQUESTION or MB_YESNOCANCEL or MB_DEFBUTTON1
        );
    case Choice of
        IDYES: Result := SaveCurrentDocument;
        IDNO: Result := True;
    else
        Result := False;
    end;
end;

procedure TEditorForm.InsertLink(Sender: TObject);
var
    LinkAddress: string;
    LinkTitle: string;
begin
    if not ChooseMarkdownLink(Self, EditorMemo.SelText, LinkTitle, LinkAddress) then
        Exit;
    EditorMemo.SelText := BuildMarkdownLink(LinkTitle, LinkAddress);
    EditorMemo.SetFocus;
end;

procedure TEditorForm.NewDocument(Sender: TObject);
begin
    if not HandleUnsavedChanges then
        Exit;
    Session.RememberFilePosition(Document.FileName);
    LanguageServer.CloseDocument;
    ExternalFiles.Stop;
    EditorMemo.Clear;
    Document := CreateDocumentState;
    MarkDocumentSaved;
end;

procedure TEditorForm.InitializeMarkdownDocument(const FileName: string);
begin
    if FileExists(FileName) then
    begin
        LoadMarkdownDocument(FileName);
        Exit;
    end;
    LanguageServer.CloseDocument;
    EditorMemo.Clear;
    Document := CreateDocumentState(ExpandFileName(FileName));
    MarkDocumentSaved;
    ExternalFiles.Watch(Document.FileName);
    LanguageServer.OpenDocument(Document.FileName, EditorMemo.Text);
end;

function TEditorForm.LoadMarkdownDocument(const FileName: string): Boolean;
begin
    Result := TryLoadMarkdownDocument(FileName, True);
end;

function TEditorForm.LoadMarkdownDocumentSilently(const FileName: string): Boolean;
begin
    Result := TryLoadMarkdownDocument(FileName, False);
end;

function TEditorForm.TryLoadMarkdownDocument(const FileName: string; ReportErrors: Boolean): Boolean;
var
    LoadedEncoding: TDocumentEncoding;
    ResolvedFileName: string;
begin
    Result := False;
    ResolvedFileName := ExpandFileName(FileName);
    Session.RememberFilePosition(Document.FileName);
    try
        LanguageServer.CloseDocument;
        EditorMemo.Text := ReadTextFile(ResolvedFileName, LoadedEncoding);
        Document.FileName := ResolvedFileName;
        Document.Encoding := LoadedEncoding;
        Document.MissingOnDisk := False;
        MarkDocumentSaved;
        RecentFiles.Remember(Document.FileName);
        Session.RestoreFilePosition(Document.FileName);
        ExternalFiles.Watch(Document.FileName);
        LanguageServer.OpenDocument(Document.FileName, EditorMemo.Text);
        Result := True;
    except
        on Error: Exception do
            if ReportErrors then
                ShowErrorMessage('Erro ao abrir arquivo', Error.Message);
    end;
end;

procedure TEditorForm.MarkDocumentSaved;
begin
    Document.SavedContent := EditorMemo.Text;
    UpdateWindowTitle;
end;

procedure TEditorForm.NavigateToDiagnostic(LineNumber: Integer);
begin
    Session.PositionCursorAtLine(LineNumber);
end;

procedure TEditorForm.OpenMarkdown(Sender: TObject);
var
    OpenDialog: TOpenDialog;
begin
    if not HandleUnsavedChanges then
        Exit;
    OpenDialog := TOpenDialog.Create(Self);
    try
        OpenDialog.Title := 'Abrir arquivo Markdown';
        OpenDialog.Filter := 'Arquivos Markdown|*.md;*.markdown|Todos os arquivos|*.*';
        OpenDialog.Options := [ofFileMustExist, ofPathMustExist, ofEnableSizing];
        if not OpenDialog.Execute then
            Exit;
        LoadMarkdownDocument(OpenDialog.FileName);
    finally
        OpenDialog.Free;
    end;
end;

procedure TEditorForm.OpenRecentMarkdown(const FileName: string);
begin
    if not HandleUnsavedChanges then
        Exit;
    LoadMarkdownDocument(FileName);
end;

procedure TEditorForm.RefreshDocument(Sender: TObject);
begin
    ExternalFiles.Refresh;
end;

procedure TEditorForm.RestoreLastSession;
begin
    if EditorPreferences.LoadLastFile then
    begin
        RecentFiles.RemoveMissingFiles;
        Session.Restore;
    end;
end;

function TEditorForm.SaveCurrentDocument: Boolean;
begin
    if Document.FileName = '' then
        Exit(SaveDocumentAs);
    Result := SaveDocumentTo(Document.FileName, Document.Encoding);
end;

function TEditorForm.SaveDocumentAs: Boolean;
var
    SelectedEncoding: TDocumentEncoding;
    SelectedFileName: string;
begin
    Result := False;
    if not ChooseMarkdownSaveFile(Self, Document.FileName, Document.Encoding, SelectedFileName, SelectedEncoding) then
        Exit;
    Result := SaveDocumentTo(SelectedFileName, SelectedEncoding);
end;

function TEditorForm.SaveDocumentTo(const FileName: string; const Encoding: TDocumentEncoding): Boolean;
begin
    Result := False;
    try
        WriteTextFile(FileName, EditorMemo.Text, Encoding);
        Document.FileName := FileName;
        Document.Encoding := Encoding;
        Document.MissingOnDisk := False;
        MarkDocumentSaved;
        RecentFiles.Remember(Document.FileName);
        Session.RememberFilePosition(Document.FileName);
        ExternalFiles.Watch(Document.FileName);
        LanguageServer.DocumentSaved(Document.FileName, EditorMemo.Text);
        Result := True;
    except
        on Error: Exception do
            ShowErrorMessage('Erro ao salvar arquivo', Error.Message);
    end;
end;

procedure TEditorForm.SaveMarkdown(Sender: TObject);
begin
    SaveCurrentDocument;
end;

procedure TEditorForm.SaveMarkdownAs(Sender: TObject);
begin
    Session.RememberFilePosition(Document.FileName);
    SaveDocumentAs;
end;

procedure TEditorForm.ShowErrorMessage(const DialogTitle, ErrorMessage: string);
begin
    LCLIntf.MessageBox(Handle, PChar(ErrorMessage), PChar(DialogTitle), MB_OK or MB_ICONERROR);
end;

procedure TEditorForm.ShowOptions(Sender: TObject);
begin
    if OptionsController.Edit(EditorPreferences, Document.FileName) then
        ExternalFiles.Configure(EditorPreferences.FileMonitoringMode, Document.FileName);
end;

procedure TEditorForm.ShowProblems(Sender: TObject);
begin
    if not EditorPreferences.UseMarkdownChecker then
    begin
        LCLIntf.MessageBox(
            Handle,
            'Habilite o verificador de Markdown nas opções para consultar a lista de problemas.',
            'Verificador de Markdown desabilitado',
            MB_OK or MB_ICONWARNING
        );
        Exit;
    end;
    LanguageServer.ShowProblems;
end;

procedure TEditorForm.ShowPreview(Sender: TObject);
var
    Preview: TPreviewForm;
begin
    Preview := TPreviewForm.Create(Self);
    try
        Preview.ShowMarkdown(EditorMemo.Text, HtmlDocumentTemplate);
    finally
        Preview.Free;
    end;
end;

procedure TEditorForm.UpdateWindowTitle;
var
    DocumentName: string;
begin
    if Document.FileName = '' then
        DocumentName := 'Sem título'
    else
        DocumentName := ExtractFileName(Document.FileName);
    if HasUnsavedChanges(EditorMemo.Text, Document) then
        DocumentName := DocumentName + ' *';
    Caption := DocumentName + ' — Markdown Editor';
end;

end.
