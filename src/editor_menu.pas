unit Editor_Menu;

{$MODE objfpc}
{$H+}

interface

uses
    Classes,
    Menus;

type
    TEditorMenuActions = record
        NewDocument: TNotifyEvent;
        OpenDocument: TNotifyEvent;
        SaveDocument: TNotifyEvent;
        SaveDocumentAs: TNotifyEvent;
        ExportHtml: TNotifyEvent;
        ExportHtmlAs: TNotifyEvent;
        ExitEditor: TNotifyEvent;
        GoToLine: TNotifyEvent;
        ShowPreview: TNotifyEvent;
    end;

function BuildEditorMenu(Owner: TComponent; const Actions: TEditorMenuActions): TMainMenu;

implementation

uses
    LCLType;

function AddMenuItem(Parent: TMenuItem; const Caption: string; Shortcut: TShortCut; Handler: TNotifyEvent): TMenuItem;
begin
    Result := TMenuItem.Create(Parent);
    Result.Caption := Caption;
    Result.ShortCut := Shortcut;
    Result.OnClick := Handler;
    Parent.Add(Result);
end;

function AddTopLevelMenu(Menu: TMainMenu; const Caption: string): TMenuItem;
begin
    Result := TMenuItem.Create(Menu);
    Result.Caption := Caption;
    Menu.Items.Add(Result);
end;

function BuildEditorMenu(Owner: TComponent; const Actions: TEditorMenuActions): TMainMenu;
var
    EditMenu: TMenuItem;
    FileMenu: TMenuItem;
    ViewMenu: TMenuItem;
begin
    Result := TMainMenu.Create(Owner);

    FileMenu := AddTopLevelMenu(Result, '&Arquivo');
    AddMenuItem(FileMenu, '&Novo', ShortCut(Ord('N'), [ssCtrl]), Actions.NewDocument);
    AddMenuItem(FileMenu, '&Abrir...', ShortCut(Ord('O'), [ssCtrl]), Actions.OpenDocument);
    AddMenuItem(FileMenu, '&Salvar', ShortCut(Ord('S'), [ssCtrl]), Actions.SaveDocument);
    AddMenuItem(FileMenu, 'Salvar &como...', ShortCut(Ord('S'), [ssCtrl, ssShift]), Actions.SaveDocumentAs);
    AddMenuItem(FileMenu, '&Exportar HTML', ShortCut(VK_F2, []), Actions.ExportHtml);
    AddMenuItem(FileMenu, 'Exportar HTML &como...', ShortCut(VK_F2, [ssCtrl]), Actions.ExportHtmlAs);
    AddMenuItem(FileMenu, '-', 0, nil);
    AddMenuItem(FileMenu, '&Sair', ShortCut(VK_F4, [ssAlt]), Actions.ExitEditor);

    EditMenu := AddTopLevelMenu(Result, '&Editar');
    AddMenuItem(EditMenu, '&Ir para a linha...', ShortCut(Ord('G'), [ssCtrl]), Actions.GoToLine);

    ViewMenu := AddTopLevelMenu(Result, '&Visualizar');
    AddMenuItem(ViewMenu, '&Renderizar Markdown', ShortCut(VK_F9, []), Actions.ShowPreview);

end;

end.
