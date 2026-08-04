unit Session_Controller;

{$MODE objfpc}
{$H+}

interface

uses
    Forms,
    Markdown_Memo,
    Recent_Files;

type
    TLoadDocumentEvent = TFileOpenEvent;

    TSessionController = class
    private
        EditorMemo: TMarkdownMemo;
        LoadDocumentHandler: TLoadDocumentEvent;
        OwnerForm: TCustomForm;
        SettingsFileName: string;
        procedure ShowError(const DialogTitle, ErrorMessage: string);
    public
        constructor Create(
            TheOwnerForm: TCustomForm;
            TheEditorMemo: TMarkdownMemo;
            TheLoadDocumentHandler: TLoadDocumentEvent;
            const TheSettingsFileName: string
        );
        procedure Persist(const CurrentFileName: string);
        procedure PositionCursorAtLine(LineNumber: Integer);
        procedure RememberFilePosition(const FileName: string);
        function Restore: Boolean;
        procedure RestoreFilePosition(const FileName: string);
    end;

implementation

uses
    LCLIntf,
    LCLType,
    SysUtils;

procedure TSessionController.ShowError(const DialogTitle, ErrorMessage: string);
begin
    LCLIntf.MessageBox(OwnerForm.Handle, PChar(ErrorMessage), PChar(DialogTitle), MB_OK or MB_ICONERROR);
end;

constructor TSessionController.Create(
    TheOwnerForm: TCustomForm;
    TheEditorMemo: TMarkdownMemo;
    TheLoadDocumentHandler: TLoadDocumentEvent;
    const TheSettingsFileName: string
);
begin
    inherited Create;
    EditorMemo := TheEditorMemo;
    LoadDocumentHandler := TheLoadDocumentHandler;
    OwnerForm := TheOwnerForm;
    SettingsFileName := TheSettingsFileName;
end;

procedure TSessionController.Persist(const CurrentFileName: string);
begin
    RememberFilePosition(CurrentFileName);
end;

procedure TSessionController.PositionCursorAtLine(LineNumber: Integer);
begin
    EditorMemo.PositionCursorAtLine(LineNumber);
    if OwnerForm.Visible and EditorMemo.CanFocus then
        EditorMemo.SetFocus;
end;

procedure TSessionController.RememberFilePosition(const FileName: string);
begin
    if (FileName = '') or not FileExists(FileName) then
        Exit;
    try
        SaveRecentFileLine(SettingsFileName, FileName, EditorMemo.CaretPos.Y + 1);
    except
        on Error: Exception do
            ShowError('Erro ao salvar posição do arquivo', Error.Message);
    end;
end;

function TSessionController.Restore: Boolean;
begin
    Result := TryOpenMostRecentAvailableFile(SettingsFileName, LoadDocumentHandler);
end;

procedure TSessionController.RestoreFilePosition(const FileName: string);
var
    LineNumber: Integer;
begin
    if FileName = '' then
        Exit;
    try
        LineNumber := LoadRecentFileLine(SettingsFileName, FileName);
        PositionCursorAtLine(LineNumber);
    except
        on Error: Exception do
            ShowError('Erro ao restaurar posição do arquivo', Error.Message);
    end;
end;

end.
