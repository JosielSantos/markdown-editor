unit Recent_Files_Controller;

{$MODE objfpc}
{$H+}

interface

uses
    Classes,
    Forms,
    Menus;

type
    TRecentFileOpenEvent = procedure(const FileName: string) of object;

    TRecentFilesController = class
    private
        Files: TStringList;
        Menu: TMenuItem;
        OpenFileHandler: TRecentFileOpenEvent;
        OwnerForm: TCustomForm;
        SettingsFileName: string;
        procedure OpenRecentFile(Sender: TObject);
        procedure Persist;
        procedure RefreshMenu;
        procedure ShowError(const DialogTitle, ErrorMessage: string);
    public
        constructor Create(
            TheOwnerForm: TCustomForm;
            TheMenu: TMenuItem;
            TheOpenFileHandler: TRecentFileOpenEvent;
            const TheSettingsFileName: string
        );
        destructor Destroy; override;
        procedure Remember(const FileName: string);
    end;

implementation

uses
    Editor_Menu,
    LCLIntf,
    LCLType,
    Recent_Files,
    SysUtils;

procedure TRecentFilesController.OpenRecentFile(Sender: TObject);
var
    FileIndex: Integer;
    RecentFileName: string;
begin
    if not (Sender is TMenuItem) then
        Exit;
    FileIndex := TMenuItem(Sender).Tag;
    if (FileIndex < 0) or (FileIndex >= Files.Count) then
        Exit;
    RecentFileName := Files[FileIndex];
    if not FileExists(RecentFileName) then
    begin
        Files.Delete(FileIndex);
        Persist;
        RefreshMenu;
        ShowError('Arquivo recente não encontrado', 'O arquivo não existe mais:' + LineEnding + RecentFileName);
        Exit;
    end;
    OpenFileHandler(RecentFileName);
end;

procedure TRecentFilesController.Persist;
begin
    try
        SaveRecentFiles(SettingsFileName, Files);
    except
        on Error: Exception do
            ShowError('Erro ao salvar arquivos recentes', Error.Message);
    end;
end;

procedure TRecentFilesController.RefreshMenu;
begin
    UpdateRecentFilesMenu(Menu, Files, @OpenRecentFile);
end;

procedure TRecentFilesController.ShowError(const DialogTitle, ErrorMessage: string);
begin
    LCLIntf.MessageBox(OwnerForm.Handle, PChar(ErrorMessage), PChar(DialogTitle), MB_OK or MB_ICONERROR);
end;

constructor TRecentFilesController.Create(
    TheOwnerForm: TCustomForm;
    TheMenu: TMenuItem;
    TheOpenFileHandler: TRecentFileOpenEvent;
    const TheSettingsFileName: string
);
begin
    inherited Create;
    Files := TStringList.Create;
    Menu := TheMenu;
    OpenFileHandler := TheOpenFileHandler;
    OwnerForm := TheOwnerForm;
    SettingsFileName := TheSettingsFileName;
    try
        LoadRecentFiles(SettingsFileName, Files);
    except
        on Error: Exception do
            ShowError('Erro ao carregar arquivos recentes', Error.Message);
    end;
    RefreshMenu;
end;

destructor TRecentFilesController.Destroy;
begin
    Files.Free;
    inherited Destroy;
end;

procedure TRecentFilesController.Remember(const FileName: string);
begin
    AddRecentFile(Files, FileName);
    Persist;
    RefreshMenu;
end;

end.
