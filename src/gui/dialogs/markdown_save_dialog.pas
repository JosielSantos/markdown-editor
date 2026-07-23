unit Markdown_Save_Dialog;

{$MODE objfpc}
{$H+}

interface

uses
    Document_State,
    Forms;

function ChooseMarkdownSaveFile(
    Owner: TCustomForm;
    const InitialFileName: string;
    const InitialEncoding: TDocumentEncoding;
    out FileName: string;
    out Encoding: TDocumentEncoding
): Boolean;

implementation

uses
    ActiveX,
    ComObj,
    ShlObj,
    SysUtils,
    Windows;

const
    ENCODING_COMBO_ID = 1001;
    ENCODING_GROUP_ID = 1002;
    ENCODING_UTF8_ITEM_ID = 1;
    ENCODING_UTF8_BOM_ITEM_ID = 2;
    ENCODING_ISO_8859_1_ITEM_ID = 3;
    ENCODING_WINDOWS_1252_ITEM_ID = 4;
    ENCODING_ORIGINAL_ITEM_ID = 5;
    ENCODING_ISO_8859_1 = 'iso88591';
    ENCODING_WINDOWS_1252 = 'cp1252';
    HRESULT_CANCELLED = HRESULT($800704C7);
    SIGDN_FILE_SYSTEM_PATH: SIGDN = -2147123200;
    IID_SHELL_ITEM: TGUID = '{43826D1E-E718-42EE-BC55-A1E261C37BFE}';

function SHCreateItemFromParsingName(
    Path: LPCWSTR;
    BindContext: IBindCtx;
    const InterfaceId: TGUID;
    out Item
): HRESULT; stdcall; external 'shell32.dll';

function EncodingItemId(const Encoding: TDocumentEncoding): DWORD;
begin
    if SameText(Encoding.Name, DOCUMENT_ENCODING_UTF8) then
    begin
        if Encoding.HasUtf8Bom then
            Exit(ENCODING_UTF8_BOM_ITEM_ID);
        Exit(ENCODING_UTF8_ITEM_ID);
    end;
    if SameText(Encoding.Name, ENCODING_ISO_8859_1) then
        Exit(ENCODING_ISO_8859_1_ITEM_ID);
    if SameText(Encoding.Name, ENCODING_WINDOWS_1252) then
        Exit(ENCODING_WINDOWS_1252_ITEM_ID);
    Result := ENCODING_ORIGINAL_ITEM_ID;
end;

function EncodingForItemId(const ItemId: DWORD; const InitialEncoding: TDocumentEncoding): TDocumentEncoding;
begin
    Result := InitialEncoding;
    case ItemId of
        ENCODING_UTF8_ITEM_ID:
        begin
            Result.Name := DOCUMENT_ENCODING_UTF8;
            Result.HasUtf8Bom := False;
        end;
        ENCODING_UTF8_BOM_ITEM_ID:
        begin
            Result.Name := DOCUMENT_ENCODING_UTF8;
            Result.HasUtf8Bom := True;
        end;
        ENCODING_ISO_8859_1_ITEM_ID:
        begin
            Result.Name := ENCODING_ISO_8859_1;
            Result.HasUtf8Bom := False;
        end;
        ENCODING_WINDOWS_1252_ITEM_ID:
        begin
            Result.Name := ENCODING_WINDOWS_1252;
            Result.HasUtf8Bom := False;
        end;
    end;
end;

procedure ConfigureFileTypes(const FileDialog: IFileSaveDialog);
var
    FilterNames: array[0..1] of UnicodeString;
    FilterPatterns: array[0..1] of UnicodeString;
    FilterSpecs: array[0..1] of COMDLG_FILTERSPEC;
begin
    FilterNames[0] := UTF8Decode('Arquivos Markdown (*.md;*.markdown)');
    FilterPatterns[0] := UTF8Decode('*.md;*.markdown');
    FilterNames[1] := UTF8Decode('Todos os arquivos (*.*)');
    FilterPatterns[1] := UTF8Decode('*.*');
    FilterSpecs[0].pszName := PWideChar(FilterNames[0]);
    FilterSpecs[0].pszSpec := PWideChar(FilterPatterns[0]);
    FilterSpecs[1].pszName := PWideChar(FilterNames[1]);
    FilterSpecs[1].pszSpec := PWideChar(FilterPatterns[1]);
    OleCheck(FileDialog.SetFileTypes(Length(FilterSpecs), @FilterSpecs[0]));
    OleCheck(FileDialog.SetFileTypeIndex(1));
    OleCheck(FileDialog.SetDefaultExtension(PWideChar(UnicodeString('md'))));
end;

procedure AddEncodingOptions(const Customizer: IFileDialogCustomize; const InitialEncoding: TDocumentEncoding);
var
    InitialItemId: DWORD;
    OriginalLabel: UnicodeString;
begin
    OleCheck(Customizer.StartVisualGroup(ENCODING_GROUP_ID, PWideChar(UTF8Decode('Opções de salvamento'))));
    OleCheck(Customizer.AddComboBox(ENCODING_COMBO_ID));
    OleCheck(Customizer.SetControlLabel(ENCODING_COMBO_ID, PWideChar(UTF8Decode('Codificação:'))));
    OleCheck(Customizer.AddControlItem(ENCODING_COMBO_ID, ENCODING_UTF8_ITEM_ID, PWideChar(UnicodeString('UTF-8'))));
    OleCheck(
        Customizer.AddControlItem(ENCODING_COMBO_ID, ENCODING_UTF8_BOM_ITEM_ID, PWideChar(UTF8Decode('UTF-8 com BOM')))
    );
    OleCheck(
        Customizer
            .AddControlItem(ENCODING_COMBO_ID, ENCODING_ISO_8859_1_ITEM_ID, PWideChar(UnicodeString('ISO-8859-1')))
    );
    OleCheck(
        Customizer
            .AddControlItem(ENCODING_COMBO_ID, ENCODING_WINDOWS_1252_ITEM_ID, PWideChar(UnicodeString('Windows-1252')))
    );
    InitialItemId := EncodingItemId(InitialEncoding);
    if InitialItemId = ENCODING_ORIGINAL_ITEM_ID then
    begin
        OriginalLabel := UTF8Decode('Original (') + UTF8Decode(InitialEncoding.Name) + UnicodeString(')');
        OleCheck(Customizer.AddControlItem(ENCODING_COMBO_ID, ENCODING_ORIGINAL_ITEM_ID, PWideChar(OriginalLabel)));
    end;
    OleCheck(Customizer.SetSelectedControlItem(ENCODING_COMBO_ID, InitialItemId));
    OleCheck(Customizer.EndVisualGroup);
end;

procedure SetInitialFileName(const FileDialog: IFileSaveDialog; const InitialFileName: string);
var
    FolderItem: IShellItem;
    FolderName: UnicodeString;
    ResolvedFileName: string;
begin
    if InitialFileName = '' then
        Exit;
    ResolvedFileName := ExpandFileName(InitialFileName);
    OleCheck(FileDialog.SetFileName(PWideChar(UTF8Decode(ExtractFileName(ResolvedFileName)))));
    FolderName := UTF8Decode(ExtractFileDir(ResolvedFileName));
    if Succeeded(SHCreateItemFromParsingName(PWideChar(FolderName), nil, IID_SHELL_ITEM, FolderItem)) then
        OleCheck(FileDialog.SetFolder(FolderItem));
end;

function GetSelectedFileName(const FileDialog: IFileSaveDialog): string;
var
    FileNamePointer: LPWSTR;
    ShellItem: IShellItem;
begin
    FileNamePointer := nil;
    OleCheck(FileDialog.GetResult(@ShellItem));
    OleCheck(ShellItem.GetDisplayName(SIGDN_FILE_SYSTEM_PATH, LPWSTR(@FileNamePointer)));
    try
        Result := UTF8Encode(UnicodeString(FileNamePointer));
    finally
        CoTaskMemFree(FileNamePointer);
    end;
end;

function ChooseMarkdownSaveFile(
    Owner: TCustomForm;
    const InitialFileName: string;
    const InitialEncoding: TDocumentEncoding;
    out FileName: string;
    out Encoding: TDocumentEncoding
): Boolean;
var
    Customizer: IFileDialogCustomize;
    DialogOptions: FILEOPENDIALOGOPTIONS;
    DialogResult: HRESULT;
    FileDialog: IFileSaveDialog;
    ComResult: HRESULT;
    SelectedEncodingItem: DWORD;
begin
    Result := False;
    ComResult := CoInitializeEx(nil, COINIT_APARTMENTTHREADED or COINIT_DISABLE_OLE1DDE);
    OleCheck(ComResult);
    try
        FileDialog := CreateComObject(CLSID_FileSaveDialog) as IFileSaveDialog;
        Customizer := FileDialog as IFileDialogCustomize;
        OleCheck(FileDialog.SetTitle(PWideChar(UTF8Decode('Salvar arquivo Markdown'))));
        OleCheck(FileDialog.GetOptions(@DialogOptions));
        OleCheck(
            FileDialog.SetOptions(DialogOptions or FOS_OVERWRITEPROMPT or FOS_PATHMUSTEXIST or FOS_FORCEFILESYSTEM)
        );
        ConfigureFileTypes(FileDialog);
        AddEncodingOptions(Customizer, InitialEncoding);
        SetInitialFileName(FileDialog, InitialFileName);
        DialogResult := FileDialog.Show(Owner.Handle);
        if DialogResult = HRESULT_CANCELLED then
            Exit;
        OleCheck(DialogResult);
        OleCheck(Customizer.GetSelectedControlItem(ENCODING_COMBO_ID, SelectedEncodingItem));
        FileName := GetSelectedFileName(FileDialog);
        Encoding := EncodingForItemId(SelectedEncodingItem, InitialEncoding);
        Result := True;
    finally
        Customizer := nil;
        FileDialog := nil;
        CoUninitialize;
    end;
end;

end.
