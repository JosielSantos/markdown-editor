unit Main_Form;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  Forms, Menus, StdCtrls;

type
  TEditorForm = class(TForm)
  private
    EditorMemo: TMemo;
    procedure CreateEditor;
    procedure CreateMenuBar;
    procedure ExitEditor(Sender: TObject);
    procedure ShowAbout(Sender: TObject);
    procedure ShowPreview(Sender: TObject);
  public
    constructor Create(TheOwner: TComponent); override;
  end;

var
  EditorForm: TEditorForm;

implementation

uses
  Controls, Dialogs, LCLType, Preview_Form;

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
  ActiveControl := EditorMemo;
end;

procedure TEditorForm.CreateMenuBar;
var
  AboutItem: TMenuItem;
  ExitItem: TMenuItem;
  FileMenu: TMenuItem;
  HelpMenu: TMenuItem;
  PreviewItem: TMenuItem;
  ViewMenu: TMenuItem;
begin
  Menu := TMainMenu.Create(Self);

  FileMenu := TMenuItem.Create(Menu);
  FileMenu.Caption := '&Arquivo';
  Menu.Items.Add(FileMenu);
  ExitItem := TMenuItem.Create(FileMenu);
  ExitItem.Caption := '&Sair';
  ExitItem.ShortCut := ShortCut(VK_F4, [ssAlt]);
  ExitItem.OnClick := @ExitEditor;
  FileMenu.Add(ExitItem);

  ViewMenu := TMenuItem.Create(Menu);
  ViewMenu.Caption := '&Visualizar';
  Menu.Items.Add(ViewMenu);
  PreviewItem := TMenuItem.Create(ViewMenu);
  PreviewItem.Caption := '&Renderizar Markdown';
  PreviewItem.ShortCut := ShortCut(VK_F9, []);
  PreviewItem.OnClick := @ShowPreview;
  ViewMenu.Add(PreviewItem);

  HelpMenu := TMenuItem.Create(Menu);
  HelpMenu.Caption := 'A&juda';
  Menu.Items.Add(HelpMenu);
  AboutItem := TMenuItem.Create(HelpMenu);
  AboutItem.Caption := '&Atalhos e acessibilidade';
  AboutItem.OnClick := @ShowAbout;
  HelpMenu.Add(AboutItem);
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
end;

procedure TEditorForm.ExitEditor(Sender: TObject);
begin
  Close;
end;

procedure TEditorForm.ShowAbout(Sender: TObject);
begin
  MessageDlg('Atalhos e acessibilidade',
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

end.
