unit External_File_Controller;

{$MODE objfpc}
{$H+}

interface

uses
    Document_State,
    File_Change_Controller,
    Forms,
    Language_Server_Controller,
    StdCtrls;

type
    TDocumentStateChangedEvent = procedure of object;

    TExternalFileController = class
    private
        Document: PDocumentState;
        EditorMemo: TMemo;
        FileChanges: TFileChangeController;
        LanguageServer: TLanguageServerController;
        OwnerForm: TCustomForm;
        StateChangedHandler: TDocumentStateChangedEvent;
        procedure ApplyContent(const Content: string; const Encoding: TDocumentEncoding);
        procedure CheckExternalFile(Sender: TObject);
        procedure NotifyStateChanged;
    public
        constructor Create(
            TheOwnerForm: TCustomForm;
            TheEditorMemo: TMemo;
            TheLanguageServer: TLanguageServerController;
            TheDocument: PDocumentState;
            TheStateChangedHandler: TDocumentStateChangedEvent
        );
        destructor Destroy; override;
        procedure Stop;
        procedure Watch(const FileName: string);
    end;

implementation

uses
    Files,
    LCLIntf,
    LCLType,
    SysUtils;

constructor TExternalFileController.Create(
    TheOwnerForm: TCustomForm;
    TheEditorMemo: TMemo;
    TheLanguageServer: TLanguageServerController;
    TheDocument: PDocumentState;
    TheStateChangedHandler: TDocumentStateChangedEvent
);
begin
    OwnerForm := TheOwnerForm;
    EditorMemo := TheEditorMemo;
    LanguageServer := TheLanguageServer;
    Document := TheDocument;
    StateChangedHandler := TheStateChangedHandler;
    FileChanges := TFileChangeController.Create(OwnerForm, @CheckExternalFile);
end;

destructor TExternalFileController.Destroy;
begin
    FileChanges.Free;
    inherited Destroy;
end;

procedure TExternalFileController.ApplyContent(const Content: string; const Encoding: TDocumentEncoding);
var
    CaretPosition: Integer;
    SelectionLength: Integer;
begin
    CaretPosition := EditorMemo.SelStart;
    SelectionLength := EditorMemo.SelLength;
    EditorMemo.Lines.BeginUpdate;
    try
        EditorMemo.Text := Content;
    finally
        EditorMemo.Lines.EndUpdate;
    end;
    Document^.Encoding := Encoding;
    Document^.MissingOnDisk := False;
    Document^.SavedContent := EditorMemo.Text;
    if CaretPosition > Length(EditorMemo.Text) then
        CaretPosition := Length(EditorMemo.Text);
    EditorMemo.SelStart := CaretPosition;
    if SelectionLength > Length(EditorMemo.Text) - CaretPosition then
        SelectionLength := Length(EditorMemo.Text) - CaretPosition;
    EditorMemo.SelLength := SelectionLength;
    LanguageServer.DocumentSaved(Document^.FileName, EditorMemo.Text);
    NotifyStateChanged;
end;

procedure TExternalFileController.CheckExternalFile(Sender: TObject);
var
    Choice: Integer;
    ExternalContent: string;
    ExternalEncoding: TDocumentEncoding;
begin
    if Document^.FileName = '' then
        Exit;
    if not FileExists(Document^.FileName) then
    begin
        if Document^.MissingOnDisk then
            Exit;
        Document^.MissingOnDisk := True;
        NotifyStateChanged;
        LCLIntf.MessageBox(
            OwnerForm.Handle,
            'O arquivo aberto não existe mais. O conteúdo foi mantido no editor.',
            'Arquivo removido',
            MB_OK or MB_ICONWARNING
        );
        Exit;
    end;
    try
        ExternalContent := AdjustLineBreaks(ReadTextFile(Document^.FileName, ExternalEncoding), tlbsCRLF);
    except
        FileChanges.ScheduleCheck;
        Exit;
    end;
    Document^.MissingOnDisk := False;
    if ExternalContent = Document^.SavedContent then
    begin
        Document^.Encoding := ExternalEncoding;
        NotifyStateChanged;
        Exit;
    end;
    Choice := IDYES;
    if HasContentChanged(EditorMemo.Text, Document^.SavedContent) then
        Choice :=
            LCLIntf.MessageBox(
                OwnerForm.Handle,
                'O arquivo foi alterado por outro programa. Deseja recarregá-lo e descartar as alterações deste editor?',
                'Arquivo alterado',
                MB_ICONQUESTION or MB_YESNO or MB_DEFBUTTON2
            );
    if Choice = IDYES then
        ApplyContent(ExternalContent, ExternalEncoding)
    else
    begin
        Document^.Encoding := ExternalEncoding;
        Document^.SavedContent := ExternalContent;
        NotifyStateChanged;
    end;
end;

procedure TExternalFileController.NotifyStateChanged;
begin
    if Assigned(StateChangedHandler) then
        StateChangedHandler;
end;

procedure TExternalFileController.Stop;
begin
    FileChanges.Stop;
end;

procedure TExternalFileController.Watch(const FileName: string);
begin
    FileChanges.Watch(FileName);
end;

end.
