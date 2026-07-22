unit Main_Form;

{$MODE objfpc}
{$H+}

interface

uses
    Classes,
    Forms,
    Recent_Files_Controller,
    Session_Controller,
    StdCtrls;

type
    TEditorForm = class(TForm)
    private
        CurrentFileName: string;
        EditorMemo: TMemo;
        LastSavedContent: string;
        RecentFiles: TRecentFilesController;
        Session: TSessionController;
        procedure CanCloseEditor(Sender: TObject; var CanClose: Boolean);
        function ChooseMarkdownSavePath: Boolean;
        procedure CreateEditor;
        procedure CreateMenuBar;
        procedure EditorChanged(Sender: TObject);
        procedure ExitEditor(Sender: TObject);
        procedure ExportHtml(Sender: TObject);
        procedure ExportHtmlAs(Sender: TObject);
        procedure ExportHtmlToFile(const HtmlFileName: string);
        procedure GoToLine(Sender: TObject);
        function HandleUnsavedChanges: Boolean;
        procedure MarkDocumentSaved;
        procedure NewDocument(Sender: TObject);
        procedure OpenMarkdown(Sender: TObject);
        procedure OpenRecentMarkdown(const FileName: string);
        function SaveCurrentDocument: Boolean;
        procedure SaveMarkdown(Sender: TObject);
        procedure SaveMarkdownAs(Sender: TObject);
        procedure ShowErrorMessage(const DialogTitle, ErrorMessage: string);
        procedure ShowPreview(Sender: TObject);
        procedure UpdateWindowTitle;
    public
        constructor Create(TheOwner: TComponent); override;
        destructor Destroy; override;
        procedure InitializeMarkdownDocument(const FileName: string);
        function LoadMarkdownDocument(const FileName: string): Boolean;
        procedure RestoreLastSession;
    end;

var
    EditorForm: TEditorForm;

implementation

uses
    Controls,
    Dialogs,
    Document_State,
    Editor_Menu,
    Editor_Settings,
    File_Service,
    Go_To_Line_Dialog,
    Gui_Helpers,
    Html_Export_Service,
    LCLIntf,
    LCLType,
    Menus,
    Preview_Form,
    SysUtils;

procedure TEditorForm.CreateEditor;
begin
    EditorMemo := TMemo.Create(Self);
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
    Actions.SaveDocument := @SaveMarkdown;
    Actions.SaveDocumentAs := @SaveMarkdownAs;
    Actions.ExportHtml := @ExportHtml;
    Actions.ExportHtmlAs := @ExportHtmlAs;
    Actions.ExitEditor := @ExitEditor;
    Actions.GoToLine := @GoToLine;
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
    CreateMenuBar;
    CreateEditor;
    Session := TSessionController.Create(Self, EditorMemo, @LoadMarkdownDocument, DefaultSettingsFileName);
    CurrentFileName := '';
    LastSavedContent := '';
    OnCloseQuery := @CanCloseEditor;
    UpdateWindowTitle;
end;

destructor TEditorForm.Destroy;
begin
    Session.Free;
    RecentFiles.Free;
    inherited Destroy;
end;

procedure TEditorForm.CanCloseEditor(Sender: TObject; var CanClose: Boolean);
begin
    CanClose := HandleUnsavedChanges;
    if CanClose then
        Session.Persist(CurrentFileName);
end;

function TEditorForm.ChooseMarkdownSavePath: Boolean;
var
    SaveDialog: TSaveDialog;
begin
    SaveDialog := TSaveDialog.Create(Self);
    try
        SaveDialog.Title := 'Salvar arquivo Markdown';
        SaveDialog.Filter := 'Arquivos Markdown|*.md;*.markdown|Todos os arquivos|*.*';
        SaveDialog.DefaultExt := 'md';
        SaveDialog.Options := [ofOverwritePrompt, ofEnableSizing];
        if CurrentFileName <> '' then
            SaveDialog.FileName := CurrentFileName;
        Result := SaveDialog.Execute;
        if Result then
            CurrentFileName := SaveDialog.FileName;
    finally
        SaveDialog.Free;
    end;
end;

procedure TEditorForm.EditorChanged(Sender: TObject);
begin
    UpdateWindowTitle;
end;

procedure TEditorForm.ExitEditor(Sender: TObject);
begin
    Close;
end;

procedure TEditorForm.ExportHtml(Sender: TObject);
begin
    if CurrentFileName = '' then
        ExportHtmlAs(Sender)
    else
        ExportHtmlToFile(HtmlExportFileName(CurrentFileName));
end;

procedure TEditorForm.ExportHtmlAs(Sender: TObject);
var
    HtmlFileName: string;
begin
    if ChooseHtmlExportFile(Self, CurrentFileName, HtmlFileName) then
        ExportHtmlToFile(HtmlFileName);
end;

procedure TEditorForm.ExportHtmlToFile(const HtmlFileName: string);
begin
    try
        ExportMarkdownToHtmlFile(EditorMemo.Text, HtmlFileName);
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
    if not HasContentChanged(EditorMemo.Text, LastSavedContent) then
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

procedure TEditorForm.NewDocument(Sender: TObject);
begin
    if not HandleUnsavedChanges then
        Exit;
    Session.RememberFilePosition(CurrentFileName);
    EditorMemo.Clear;
    CurrentFileName := '';
    MarkDocumentSaved;
end;

procedure TEditorForm.InitializeMarkdownDocument(const FileName: string);
begin
    if FileExists(FileName) then
    begin
        LoadMarkdownDocument(FileName);
        Exit;
    end;
    EditorMemo.Clear;
    CurrentFileName := ExpandFileName(FileName);
    MarkDocumentSaved;
end;

function TEditorForm.LoadMarkdownDocument(const FileName: string): Boolean;
var
    ResolvedFileName: string;
begin
    Result := False;
    ResolvedFileName := ExpandFileName(FileName);
    Session.RememberFilePosition(CurrentFileName);
    try
        EditorMemo.Text := ReadUtf8TextFile(ResolvedFileName);
        CurrentFileName := ResolvedFileName;
        MarkDocumentSaved;
        RecentFiles.Remember(CurrentFileName);
        Session.RestoreFilePosition(CurrentFileName);
        Result := True;
    except
        on Error: Exception do
            ShowErrorMessage('Erro ao abrir arquivo', Error.Message);
    end;
end;

procedure TEditorForm.MarkDocumentSaved;
begin
    LastSavedContent := EditorMemo.Text;
    UpdateWindowTitle;
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

procedure TEditorForm.RestoreLastSession;
begin
    Session.Restore;
end;

function TEditorForm.SaveCurrentDocument: Boolean;
begin
    Result := False;
    if (CurrentFileName = '') and not ChooseMarkdownSavePath then
        Exit;
    try
        WriteUtf8TextFile(CurrentFileName, EditorMemo.Text);
        MarkDocumentSaved;
        RecentFiles.Remember(CurrentFileName);
        Session.RememberFilePosition(CurrentFileName);
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
var
    PreviousFileName: string;
begin
    PreviousFileName := CurrentFileName;
    Session.RememberFilePosition(PreviousFileName);
    CurrentFileName := '';
    if not ChooseMarkdownSavePath then
    begin
        CurrentFileName := PreviousFileName;
        Exit;
    end;
    SaveCurrentDocument;
end;

procedure TEditorForm.ShowErrorMessage(const DialogTitle, ErrorMessage: string);
begin
    LCLIntf.MessageBox(Handle, PChar(ErrorMessage), PChar(DialogTitle), MB_OK or MB_ICONERROR);
end;

procedure TEditorForm.ShowPreview(Sender: TObject);
var
    Preview: TPreviewForm;
begin
    Preview := TPreviewForm.Create(Self);
    try
        Preview.ShowMarkdown(EditorMemo.Text);
    finally
        Preview.Free;
    end;
end;

procedure TEditorForm.UpdateWindowTitle;
var
    DocumentName: string;
begin
    if CurrentFileName = '' then
        DocumentName := 'Sem título'
    else
        DocumentName := ExtractFileName(CurrentFileName);
    if HasContentChanged(EditorMemo.Text, LastSavedContent) then
        DocumentName := DocumentName + ' *';
    Caption := DocumentName + ' — Markdown Editor';
end;

end.
