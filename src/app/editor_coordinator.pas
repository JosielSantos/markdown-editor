unit Editor_Coordinator;

{$MODE objfpc}
{$H+}

interface

uses
    Classes,
    Document_Controller,
    Editor_Preferences,
    Language_Server_Controller,
    Main_Form,
    Options_Controller;

type
    TEditorCoordinator = class
    private
        Documents: TDocumentController;
        EditorPreferences: TEditorPreferences;
        Form: TEditorForm;
        HtmlDocumentTemplate: string;
        LanguageServer: TLanguageServerController;
        OptionsController: TOptionsController;
        procedure BindForm;
        procedure CanCloseEditor(Sender: TObject; var CanClose: Boolean);
        procedure EditorChanged(Sender: TObject);
        procedure ExportHtml(Sender: TObject);
        procedure ExportHtmlAs(Sender: TObject);
        procedure ExportHtmlToFile(const HtmlFileName: string);
        procedure NavigateToDiagnostic(LineNumber: Integer);
        procedure NewDocument(Sender: TObject);
        procedure OpenMarkdown(Sender: TObject);
        procedure RefreshDocument(Sender: TObject);
        procedure SaveMarkdown(Sender: TObject);
        procedure SaveMarkdownAs(Sender: TObject);
        procedure ShowOptions(Sender: TObject);
        procedure ShowProblems(Sender: TObject);
        procedure ShowPreview(Sender: TObject);
    public
        constructor Create(
            TheForm: TEditorForm;
            const InitialPreferences: TEditorPreferences;
            const TheSettingsFileName, TheHtmlDocumentTemplate: string
        );
        destructor Destroy; override;
        procedure InitializeMarkdownDocument(const FileName: string);
        function LoadMarkdownDocument(const FileName: string): Boolean;
        procedure RestoreLastSession;
    end;

implementation

uses
    Editor_Menu,
    Html_Export,
    Renderer,
    SysUtils;

constructor TEditorCoordinator.Create(
    TheForm: TEditorForm;
    const InitialPreferences: TEditorPreferences;
    const TheSettingsFileName, TheHtmlDocumentTemplate: string
);
begin
    inherited Create;
    Form := TheForm;
    EditorPreferences := InitialPreferences;
    HtmlDocumentTemplate := TheHtmlDocumentTemplate;
    BindForm;
    LanguageServer := TLanguageServerController.Create(Form, Form.EditorControl, @NavigateToDiagnostic);
    OptionsController := TOptionsController.Create(Form, Form.EditorControl, LanguageServer, TheSettingsFileName);
    Documents :=
        TDocumentController.Create(Form, LanguageServer, EditorPreferences.FileMonitoringMode, TheSettingsFileName);
    if EditorPreferences.UseMarkdownChecker then
        LanguageServer
            .Start(EditorPreferences.MarkdownCheckerExecutableFileName, EditorPreferences.MarkdownCheckerArguments);
end;

destructor TEditorCoordinator.Destroy;
begin
    Documents.Free;
    OptionsController.Free;
    LanguageServer.Free;
    inherited Destroy;
end;

procedure TEditorCoordinator.BindForm;
var
    Actions: TEditorMenuActions;
begin
    FillChar(Actions, SizeOf(Actions), 0);
    Actions.NewDocument := @NewDocument;
    Actions.OpenDocument := @OpenMarkdown;
    Actions.RefreshDocument := @RefreshDocument;
    Actions.SaveDocument := @SaveMarkdown;
    Actions.SaveDocumentAs := @SaveMarkdownAs;
    Actions.ExportHtml := @ExportHtml;
    Actions.ExportHtmlAs := @ExportHtmlAs;
    Actions.ShowOptions := @ShowOptions;
    Actions.ShowProblems := @ShowProblems;
    Actions.ShowPreview := @ShowPreview;
    Form.BindActions(Actions, @EditorChanged, @CanCloseEditor);
end;

procedure TEditorCoordinator.CanCloseEditor(Sender: TObject; var CanClose: Boolean);
begin
    Documents.CanCloseEditor(Sender, CanClose);
end;

procedure TEditorCoordinator.EditorChanged(Sender: TObject);
begin
    Documents.EditorChanged(Sender);
end;

procedure TEditorCoordinator.NewDocument(Sender: TObject);
begin
    Documents.NewDocument(Sender);
end;

procedure TEditorCoordinator.OpenMarkdown(Sender: TObject);
begin
    Documents.OpenMarkdown(Sender);
end;

procedure TEditorCoordinator.RefreshDocument(Sender: TObject);
begin
    Documents.RefreshDocument(Sender);
end;

procedure TEditorCoordinator.SaveMarkdown(Sender: TObject);
begin
    Documents.SaveMarkdown(Sender);
end;

procedure TEditorCoordinator.SaveMarkdownAs(Sender: TObject);
begin
    Documents.SaveMarkdownAs(Sender);
end;

procedure TEditorCoordinator.InitializeMarkdownDocument(const FileName: string);
begin
    Documents.InitializeMarkdownDocument(FileName);
end;

function TEditorCoordinator.LoadMarkdownDocument(const FileName: string): Boolean;
begin
    Result := Documents.LoadMarkdownDocument(FileName);
end;

procedure TEditorCoordinator.RestoreLastSession;
begin
    if EditorPreferences.LoadLastFile then
        Documents.RestoreLastSession;
end;

procedure TEditorCoordinator.NavigateToDiagnostic(LineNumber: Integer);
begin
    Form.EditorControl.PositionCursorAtLine(LineNumber);
end;

procedure TEditorCoordinator.ExportHtml(Sender: TObject);
begin
    if Documents.FileName = '' then
        ExportHtmlAs(Sender)
    else
        ExportHtmlToFile(HtmlExportFileName(Documents.FileName));
end;

procedure TEditorCoordinator.ExportHtmlAs(Sender: TObject);
var
    HtmlFileName: string;
begin
    if Form.SelectHtmlExportFile(Documents.FileName, HtmlFileName) then
        ExportHtmlToFile(HtmlFileName);
end;

procedure TEditorCoordinator.ExportHtmlToFile(const HtmlFileName: string);
begin
    try
        ExportMarkdownToHtmlFile(Form.DocumentText, HtmlDocumentTemplate, HtmlFileName);
    except
        on Error: Exception do
            Form.ShowErrorMessage('Erro ao exportar HTML', Error.Message);
    end;
end;

procedure TEditorCoordinator.ShowOptions(Sender: TObject);
begin
    if OptionsController.Edit(EditorPreferences, Documents.FileName) then
        Documents.ConfigureMonitoring(EditorPreferences.FileMonitoringMode);
end;

procedure TEditorCoordinator.ShowProblems(Sender: TObject);
begin
    if not EditorPreferences.UseMarkdownChecker then
    begin
        Form.ShowMarkdownCheckerDisabled;
        Exit;
    end;
    LanguageServer.ShowProblems;
end;

procedure TEditorCoordinator.ShowPreview(Sender: TObject);
begin
    Form.ShowPreviewHtml(MarkdownToHtml(Form.DocumentText, HtmlDocumentTemplate));
end;

end.
