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
        InsertLink: TNotifyEvent;
        ShowPreview: TNotifyEvent;
    end;

function BuildEditorMenu(
    Owner: TComponent;
    const Actions: TEditorMenuActions;
    out RecentFilesMenu: TMenuItem
): TMainMenu;
procedure UpdateRecentFilesMenu(RecentFilesMenu: TMenuItem; Files: TStrings; Handler: TNotifyEvent);

implementation

uses
    LCLType,
    SysUtils;

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

function BuildEditorMenu(
    Owner: TComponent;
    const Actions: TEditorMenuActions;
    out RecentFilesMenu: TMenuItem
): TMainMenu;
var
    EditMenu: TMenuItem;
    FileMenu: TMenuItem;
    InsertMenu: TMenuItem;
    ViewMenu: TMenuItem;
begin
    Result := TMainMenu.Create(Owner);

    FileMenu := AddTopLevelMenu(Result, '&Arquivo');
    AddMenuItem(FileMenu, '&Novo', ShortCut(Ord('N'), [ssCtrl]), Actions.NewDocument);
    AddMenuItem(FileMenu, '&Abrir...', ShortCut(Ord('O'), [ssCtrl]), Actions.OpenDocument);
    RecentFilesMenu := AddMenuItem(FileMenu, 'Arquivos &recentes', 0, nil);
    AddMenuItem(FileMenu, '-', 0, nil);
    AddMenuItem(FileMenu, '&Salvar', ShortCut(Ord('S'), [ssCtrl]), Actions.SaveDocument);
    AddMenuItem(FileMenu, 'Salvar &como...', ShortCut(Ord('S'), [ssCtrl, ssShift]), Actions.SaveDocumentAs);
    AddMenuItem(FileMenu, '&Exportar HTML', ShortCut(VK_F2, []), Actions.ExportHtml);
    AddMenuItem(FileMenu, 'Exportar HTML &como...', ShortCut(VK_F2, [ssCtrl]), Actions.ExportHtmlAs);
    AddMenuItem(FileMenu, '-', 0, nil);
    AddMenuItem(FileMenu, '&Sair', ShortCut(VK_F4, [ssAlt]), Actions.ExitEditor);

    EditMenu := AddTopLevelMenu(Result, '&Editar');
    AddMenuItem(EditMenu, '&Ir para a linha...', ShortCut(Ord('G'), [ssCtrl]), Actions.GoToLine);

    InsertMenu := AddTopLevelMenu(Result, '&Inserir');
    AddMenuItem(InsertMenu, '&Link...', ShortCut(Ord('L'), [ssAlt, ssShift]), Actions.InsertLink);

    ViewMenu := AddTopLevelMenu(Result, '&Visualizar');
    AddMenuItem(ViewMenu, '&Renderizar Markdown', ShortCut(VK_F9, []), Actions.ShowPreview);

end;

procedure UpdateRecentFilesMenu(RecentFilesMenu: TMenuItem; Files: TStrings; Handler: TNotifyEvent);
var
    FileIndex: Integer;
    MenuItem: TMenuItem;
begin
    RecentFilesMenu.Clear;
    if Files.Count = 0 then
    begin
        MenuItem := AddMenuItem(RecentFilesMenu, '(Nenhum arquivo recente)', 0, nil);
        MenuItem.Enabled := False;
        Exit;
    end;
    for FileIndex := 0 to Files.Count - 1 do
    begin
        MenuItem :=
            AddMenuItem(
                RecentFilesMenu,
                Format('&%d %s', [FileIndex + 1, StringReplace(Files[FileIndex], '&', '&&', [rfReplaceAll])]),
                0,
                Handler
            );
        MenuItem.Tag := FileIndex;
    end;
end;

end.
