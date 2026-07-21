unit Main_Form;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  Forms, StdCtrls;

type
  TEditorForm = class(TForm)
  private
    CurrentFileName: string;
    DocumentModified: Boolean;
    EditorMemo: TMemo;
    procedure CanCloseEditor(Sender: TObject; var CanClose: Boolean);
    function ChooseMarkdownSavePath: Boolean;
    procedure CreateEditor;
    procedure CreateMenuBar;
    procedure EditorChanged(Sender: TObject);
    procedure ExitEditor(Sender: TObject);
    procedure ExportHtml(Sender: TObject);
    function HandleUnsavedChanges: Boolean;
    procedure NewDocument(Sender: TObject);
    procedure OpenMarkdown(Sender: TObject);
    function SaveCurrentDocument: Boolean;
    procedure SaveMarkdown(Sender: TObject);
    procedure SaveMarkdownAs(Sender: TObject);
    procedure ShowAbout(Sender: TObject);
    procedure ShowPreview(Sender: TObject);
    procedure UpdateWindowTitle;
  public
    constructor Create(TheOwner: TComponent); override;
  end;

var
  EditorForm: TEditorForm;

implementation

uses
  Controls, Dialogs, Editor_Menu, File_Service, Markdown_Renderer,
  Preview_Form, SysUtils;

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
  EditorMemo.AccessibleName := 'Editor de texto Markdown';
  EditorMemo.AccessibleDescription :=
    'Digite Markdown. Pressione F9 para abrir a visualização.';
  EditorMemo.AccessibleRole := larTextEditorMultiline;
  EditorMemo.OnChange := @EditorChanged;
  ActiveControl := EditorMemo;
end;

procedure TEditorForm.CreateMenuBar;
var
  Actions: TEditorMenuActions;
begin
  Actions.NewDocument := @NewDocument;
  Actions.OpenDocument := @OpenMarkdown;
  Actions.SaveDocument := @SaveMarkdown;
  Actions.SaveDocumentAs := @SaveMarkdownAs;
  Actions.ExportHtml := @ExportHtml;
  Actions.ExitEditor := @ExitEditor;
  Actions.ShowPreview := @ShowPreview;
  Actions.ShowAbout := @ShowAbout;
  Menu := BuildEditorMenu(Self, Actions);
end;

constructor TEditorForm.Create(TheOwner: TComponent);
begin
  inherited CreateNew(TheOwner, 1);
  Caption := 'Editor Markdown Acessível';
  Position := poScreenCenter;
  Width := 900;
  Height := 650;
  CreateMenuBar;
  CreateEditor;
  CurrentFileName := '';
  DocumentModified := False;
  OnCloseQuery := @CanCloseEditor;
  UpdateWindowTitle;
end;

procedure TEditorForm.CanCloseEditor(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := HandleUnsavedChanges;
end;

function TEditorForm.ChooseMarkdownSavePath: Boolean;
var
  SaveDialog: TSaveDialog;
begin
  SaveDialog := TSaveDialog.Create(Self);
  try
    SaveDialog.Title := 'Salvar arquivo Markdown';
    SaveDialog.Filter :=
      'Arquivos Markdown|*.md;*.markdown|Todos os arquivos|*.*';
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
  DocumentModified := True;
  UpdateWindowTitle;
end;

procedure TEditorForm.ExitEditor(Sender: TObject);
begin
  Close;
end;

procedure TEditorForm.ExportHtml(Sender: TObject);
var
  ExportDialog: TSaveDialog;
begin
  ExportDialog := TSaveDialog.Create(Self);
  try
    ExportDialog.Title := 'Exportar documento como HTML';
    ExportDialog.Filter := 'Arquivo HTML|*.html;*.htm|Todos os arquivos|*.*';
    ExportDialog.DefaultExt := 'html';
    ExportDialog.Options := [ofOverwritePrompt, ofEnableSizing];
    if CurrentFileName = '' then
      ExportDialog.FileName := 'documento.html'
    else
      ExportDialog.FileName := ChangeFileExt(CurrentFileName, '.html');
    if not ExportDialog.Execute then
      Exit;
    try
      WriteUtf8TextFile(ExportDialog.FileName,
        MarkdownToHtml(EditorMemo.Text));
    except
      on Error: Exception do
        MessageDlg('Erro ao exportar HTML', Error.Message, mtError, [mbOK], 0);
    end;
  finally
    ExportDialog.Free;
  end;
end;

function TEditorForm.HandleUnsavedChanges: Boolean;
var
  Choice: TModalResult;
begin
  if not DocumentModified then
    Exit(True);
  Choice := MessageDlg('Alterações não salvas',
    'Deseja salvar as alterações antes de continuar?', mtConfirmation,
    [mbYes, mbNo, mbCancel], 0);
  case Choice of
    mrYes: Result := SaveCurrentDocument;
    mrNo: Result := True;
  else
    Result := False;
  end;
end;

procedure TEditorForm.NewDocument(Sender: TObject);
begin
  if not HandleUnsavedChanges then
    Exit;
  EditorMemo.Clear;
  CurrentFileName := '';
  DocumentModified := False;
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
    OpenDialog.Filter :=
      'Arquivos Markdown|*.md;*.markdown|Todos os arquivos|*.*';
    OpenDialog.Options := [ofFileMustExist, ofPathMustExist, ofEnableSizing];
    if not OpenDialog.Execute then
      Exit;
    try
      EditorMemo.Text := ReadUtf8TextFile(OpenDialog.FileName);
      CurrentFileName := OpenDialog.FileName;
      DocumentModified := False;
      UpdateWindowTitle;
    except
      on Error: Exception do
        MessageDlg('Erro ao abrir arquivo', Error.Message, mtError, [mbOK], 0);
    end;
  finally
    OpenDialog.Free;
  end;
end;

function TEditorForm.SaveCurrentDocument: Boolean;
begin
  Result := False;
  if (CurrentFileName = '') and not ChooseMarkdownSavePath then
    Exit;
  try
    WriteUtf8TextFile(CurrentFileName, EditorMemo.Text);
    DocumentModified := False;
    UpdateWindowTitle;
    Result := True;
  except
    on Error: Exception do
      MessageDlg('Erro ao salvar arquivo', Error.Message, mtError, [mbOK], 0);
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
  CurrentFileName := '';
  if not ChooseMarkdownSavePath then
  begin
    CurrentFileName := PreviousFileName;
    Exit;
  end;
  SaveCurrentDocument;
end;

procedure TEditorForm.ShowAbout(Sender: TObject);
begin
  MessageDlg('Atalhos e acessibilidade',
    'Ctrl+O: abrir Markdown' + LineEnding +
    'Ctrl+S: salvar Markdown' + LineEnding +
    'F2: exportar como HTML' + LineEnding +
    'F9: renderizar Markdown' + LineEnding +
    'Esc: fechar a visualização' + LineEnding +
    'Ctrl+Tab: alternar a visualização visual e o texto acessível' +
    LineEnding + LineEnding +
    'O editor usa controles nativos do Windows e não abre o navegador.',
    mtInformation, [mbOK], 0);
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
  if DocumentModified then
    DocumentName := DocumentName + ' *';
  Caption := DocumentName + ' — Editor Markdown Acessível';
end;

end.
