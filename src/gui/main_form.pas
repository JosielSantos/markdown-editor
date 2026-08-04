unit Main_Form;

{$MODE objfpc}
{$H+}

interface

uses
    Classes,
    Document_State,
    Editor_Menu,
    Forms,
    Markdown_Memo,
    Menus;

type
    TUnsavedChangesChoice = (uccSave, uccDiscard, uccCancel);

    TEditorForm = class(TForm)
    private
        EditorMemo: TMarkdownMemo;
        RecentFilesMenu: TMenuItem;
        procedure CreateEditor;
        procedure ExitEditor(Sender: TObject);
        function GetDocumentText: string;
        procedure GoToLine(Sender: TObject);
        procedure InsertLink(Sender: TObject);
        procedure SetDocumentText(const Value: string);
    public
        constructor Create(TheOwner: TComponent); override;
        procedure BindActions(
            const ApplicationActions: TEditorMenuActions;
            DocumentChangedHandler: TNotifyEvent;
            CloseQueryHandler: TCloseQueryEvent
        );
        function ConfirmUnsavedChanges: TUnsavedChangesChoice;
        function SelectHtmlExportFile(const MarkdownFileName: string; out HtmlFileName: string): Boolean;
        function SelectMarkdownFileToOpen(out FileName: string): Boolean;
        function SelectMarkdownFileToSave(
            const FileName: string;
            const Encoding: TDocumentEncoding;
            out SelectedFileName: string;
            out SelectedEncoding: TDocumentEncoding
        ): Boolean;
        procedure ShowErrorMessage(const DialogTitle, ErrorMessage: string);
        procedure ShowMarkdownCheckerDisabled;
        procedure ShowPreviewHtml(const Html: string);
        procedure UpdateDocumentTitle(const FileName: string; Modified: Boolean);
        property DocumentText: string read GetDocumentText write SetDocumentText;
        property EditorControl: TMarkdownMemo read EditorMemo;
        property RecentFilesMenuItem: TMenuItem read RecentFilesMenu;
    end;

var
    EditorForm: TEditorForm;

implementation

uses
    Accessibility,
    Controls,
    Dialogs,
    Go_To_Line,
    Html_Export_Dialog,
    Insert_Link,
    LCLIntf,
    LCLType,
    Link,
    Markdown_Save_Dialog,
    Preview_Form,
    StdCtrls,
    SysUtils;

constructor TEditorForm.Create(TheOwner: TComponent);
begin
    inherited CreateNew(TheOwner, 1);
    Caption := 'Markdown Editor';
    Position := poScreenCenter;
    Width := 900;
    Height := 650;
    CreateEditor;
    UpdateDocumentTitle('', False);
end;

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
    ActiveControl := EditorMemo;
end;

procedure TEditorForm.BindActions(
    const ApplicationActions: TEditorMenuActions;
    DocumentChangedHandler: TNotifyEvent;
    CloseQueryHandler: TCloseQueryEvent
);
var
    Actions: TEditorMenuActions;
begin
    Actions := ApplicationActions;
    Actions.ExitEditor := @ExitEditor;
    Actions.GoToLine := @GoToLine;
    Actions.InsertLink := @InsertLink;
    Menu := BuildEditorMenu(Self, Actions, RecentFilesMenu);
    EditorMemo.OnChange := DocumentChangedHandler;
    OnCloseQuery := CloseQueryHandler;
end;

function TEditorForm.GetDocumentText: string;
begin
    Result := EditorMemo.Text;
end;

procedure TEditorForm.SetDocumentText(const Value: string);
begin
    EditorMemo.Lines.BeginUpdate;
    try
        EditorMemo.Text := Value;
    finally
        EditorMemo.Lines.EndUpdate;
    end;
end;

procedure TEditorForm.ExitEditor(Sender: TObject);
begin
    Close;
end;

procedure TEditorForm.GoToLine(Sender: TObject);
var
    SelectedLine: Integer;
begin
    if not ChooseLineNumber(Self, EditorMemo.CaretPos.Y + 1, EditorMemo.Lines.Count, SelectedLine) then
        Exit;
    EditorMemo.PositionCursorAtLine(SelectedLine);
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

function TEditorForm.ConfirmUnsavedChanges: TUnsavedChangesChoice;
var
    Choice: Integer;
begin
    Choice :=
        LCLIntf.MessageBox(
            Handle,
            'Deseja salvar as alterações antes de continuar?',
            'Alterações não salvas',
            MB_ICONQUESTION or MB_YESNOCANCEL or MB_DEFBUTTON1
        );
    case Choice of
        IDYES: Result := uccSave;
        IDNO: Result := uccDiscard;
    else
        Result := uccCancel;
    end;
end;

function TEditorForm.SelectMarkdownFileToOpen(out FileName: string): Boolean;
var
    OpenDialog: TOpenDialog;
begin
    Result := False;
    OpenDialog := TOpenDialog.Create(Self);
    try
        OpenDialog.Title := 'Abrir arquivo Markdown';
        OpenDialog.Filter := 'Arquivos Markdown|*.md;*.markdown|Todos os arquivos|*.*';
        OpenDialog.Options := [ofFileMustExist, ofPathMustExist, ofEnableSizing];
        if not OpenDialog.Execute then
            Exit;
        FileName := OpenDialog.FileName;
        Result := True;
    finally
        OpenDialog.Free;
    end;
end;

function TEditorForm.SelectMarkdownFileToSave(
    const FileName: string;
    const Encoding: TDocumentEncoding;
    out SelectedFileName: string;
    out SelectedEncoding: TDocumentEncoding
): Boolean;
begin
    Result := ChooseMarkdownSaveFile(Self, FileName, Encoding, SelectedFileName, SelectedEncoding);
end;

function TEditorForm.SelectHtmlExportFile(const MarkdownFileName: string; out HtmlFileName: string): Boolean;
begin
    Result := ChooseHtmlExportFile(Self, MarkdownFileName, HtmlFileName);
end;

procedure TEditorForm.ShowErrorMessage(const DialogTitle, ErrorMessage: string);
begin
    LCLIntf.MessageBox(Handle, PChar(ErrorMessage), PChar(DialogTitle), MB_OK or MB_ICONERROR);
end;

procedure TEditorForm.ShowMarkdownCheckerDisabled;
begin
    LCLIntf.MessageBox(
        Handle,
        'Habilite o verificador de Markdown nas opções para consultar a lista de problemas.',
        'Verificador de Markdown desabilitado',
        MB_OK or MB_ICONWARNING
    );
end;

procedure TEditorForm.ShowPreviewHtml(const Html: string);
var
    Preview: TPreviewForm;
begin
    Preview := TPreviewForm.Create(Self);
    try
        Preview.ShowHtml(Html);
    finally
        Preview.Free;
    end;
end;

procedure TEditorForm.UpdateDocumentTitle(const FileName: string; Modified: Boolean);
var
    DocumentName: string;
begin
    if FileName = '' then
        DocumentName := 'Sem título'
    else
        DocumentName := ExtractFileName(FileName);
    if Modified then
        DocumentName := DocumentName + ' *';
    Caption := DocumentName + ' — Markdown Editor';
end;

end.
