unit Session_Controller;

{$MODE objfpc}
{$H+}

interface

uses
    Forms,
    StdCtrls;

type
    TLoadDocumentEvent = function(const FileName: string): Boolean of object;

    TSessionController = class
    private
        EditorMemo: TMemo;
        LoadDocumentHandler: TLoadDocumentEvent;
        OwnerForm: TCustomForm;
        SettingsFileName: string;
        procedure ShowError(const DialogTitle, ErrorMessage: string);
    public
        constructor Create(
            TheOwnerForm: TCustomForm;
            TheEditorMemo: TMemo;
            TheLoadDocumentHandler: TLoadDocumentEvent;
            const TheSettingsFileName: string
        );
        procedure Persist(const CurrentFileName: string);
        procedure PositionCursorAtLine(LineNumber: Integer);
        procedure Restore;
    end;

implementation

uses
    LCLIntf,
    LCLType,
    Line_Navigation,
    Session_State,
    SysUtils;

procedure TSessionController.ShowError(const DialogTitle, ErrorMessage: string);
begin
    LCLIntf.MessageBox(OwnerForm.Handle, PChar(ErrorMessage), PChar(DialogTitle), MB_OK or MB_ICONERROR);
end;

constructor TSessionController.Create(
    TheOwnerForm: TCustomForm;
    TheEditorMemo: TMemo;
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
    try
        SaveLastSession(SettingsFileName, CurrentFileName, EditorMemo.CaretPos.Y + 1);
    except
        on Error: Exception do
            ShowError('Erro ao salvar última sessão', Error.Message);
    end;
end;

procedure TSessionController.PositionCursorAtLine(LineNumber: Integer);
begin
    LineNumber := ClampLineNumber(LineNumber, EditorMemo.Lines.Count);
    EditorMemo.SelStart := MemoLineStartIndex(EditorMemo.Lines, LineNumber);
    if OwnerForm.Visible and EditorMemo.CanFocus then
        EditorMemo.SetFocus;
end;

procedure TSessionController.Restore;
var
    Session: TEditorSession;
begin
    try
        Session := LoadLastSession(SettingsFileName);
        if Session.FileName = '' then
            Exit;
        if not FileExists(Session.FileName) then
        begin
            SaveLastSession(SettingsFileName, '', 1);
            ShowError(
                'Último arquivo não encontrado',
                'O arquivo da última sessão não existe mais:' + LineEnding + Session.FileName
            );
            Exit;
        end;
    except
        on Error: Exception do
        begin
            ShowError('Erro ao restaurar última sessão', Error.Message);
            Exit;
        end;
    end;
    if LoadDocumentHandler(Session.FileName) then
        PositionCursorAtLine(Session.LineNumber);
end;

end.
