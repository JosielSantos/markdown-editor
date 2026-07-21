unit File_Association_Service;

{$MODE objfpc}
{$H+}

interface

const
    MarkdownEditorApplicationName = 'Editor Markdown Acessível';

function BuildIconReference(const ExecutableFileName: string): string;
function BuildOpenCommand(const ExecutableFileName: string): string;
procedure AssociateMarkdownFiles(const ExecutableFileName: string);

implementation

uses
    Registry,
    ShlObj,
    SysUtils,
    Windows;

const
    ApplicationCapabilitiesKey = 'Software\JosielSantos\MarkdownEditor\Capabilities';
    ApplicationDescription = 'Editor e visualizador acessível de documentos Markdown';
    ClassesKey = 'Software\Classes\';
    MarkdownContentType = 'text/markdown';
    MarkdownProgId = 'JosielSantos.MarkdownEditor.Document.1';
    RegisteredApplicationsKey = 'Software\RegisteredApplications';

function QuoteCommandArgument(const Value: string): string;
begin
    Result := '"' + Value + '"';
end;

function BuildIconReference(const ExecutableFileName: string): string;
begin
    Result := QuoteCommandArgument(ExecutableFileName) + ',0';
end;

function BuildOpenCommand(const ExecutableFileName: string): string;
begin
    Result := QuoteCommandArgument(ExecutableFileName) + ' "%1"';
end;

procedure WriteRegistryString(RegistryWriter: TRegistry; const KeyName, ValueName, Value: string);
begin
    if not RegistryWriter.OpenKey(UTF8Decode(KeyName), True) then
        raise ERegistryException.CreateFmt('Não foi possível criar a chave de registro: %s', [KeyName]);
    try
        RegistryWriter.WriteString(UTF8Decode(ValueName), UTF8Decode(Value));
    finally
        RegistryWriter.CloseKey;
    end;
end;

procedure RegisterProgId(RegistryWriter: TRegistry; const ExecutableFileName: string);
var
    ProgIdKey: string;
begin
    ProgIdKey := ClassesKey + MarkdownProgId;
    WriteRegistryString(RegistryWriter, ProgIdKey, '', 'Documento Markdown');
    WriteRegistryString(RegistryWriter, ProgIdKey + '\DefaultIcon', '', BuildIconReference(ExecutableFileName));
    WriteRegistryString(RegistryWriter, ProgIdKey + '\shell\open\command', '', BuildOpenCommand(ExecutableFileName));
end;

procedure RegisterApplication(RegistryWriter: TRegistry; const ExecutableFileName: string);
var
    ApplicationKey: string;
begin
    ApplicationKey := ClassesKey + 'Applications\' + ExtractFileName(ExecutableFileName);
    WriteRegistryString(RegistryWriter, ApplicationKey, 'FriendlyAppName', MarkdownEditorApplicationName);
    WriteRegistryString(
        RegistryWriter,
        ApplicationKey + '\shell\open\command',
        '',
        BuildOpenCommand(ExecutableFileName)
    );
    WriteRegistryString(RegistryWriter, ApplicationKey + '\SupportedTypes', '.md', '');
    WriteRegistryString(RegistryWriter, ApplicationKey + '\SupportedTypes', '.markdown', '');
end;

procedure RegisterCapabilities(RegistryWriter: TRegistry);
begin
    WriteRegistryString(RegistryWriter, ApplicationCapabilitiesKey, 'ApplicationName', MarkdownEditorApplicationName);
    WriteRegistryString(RegistryWriter, ApplicationCapabilitiesKey, 'ApplicationDescription', ApplicationDescription);
    WriteRegistryString(RegistryWriter, ApplicationCapabilitiesKey + '\FileAssociations', '.md', MarkdownProgId);
    WriteRegistryString(RegistryWriter, ApplicationCapabilitiesKey + '\FileAssociations', '.markdown', MarkdownProgId);
    WriteRegistryString(
        RegistryWriter,
        RegisteredApplicationsKey,
        MarkdownEditorApplicationName,
        ApplicationCapabilitiesKey
    );
end;

procedure RegisterExtension(RegistryWriter: TRegistry; const Extension: string);
var
    ExtensionKey: string;
begin
    ExtensionKey := ClassesKey + Extension;
    WriteRegistryString(RegistryWriter, ExtensionKey, '', MarkdownProgId);
    WriteRegistryString(RegistryWriter, ExtensionKey, 'Content Type', MarkdownContentType);
    WriteRegistryString(RegistryWriter, ExtensionKey, 'PerceivedType', 'text');
    WriteRegistryString(RegistryWriter, ExtensionKey + '\OpenWithProgids', MarkdownProgId, '');
end;

procedure ValidateExecutable(const ExecutableFileName: string);
begin
    if not FileExists(ExecutableFileName) then
        raise Exception.CreateFmt('Executável não encontrado: %s', [ExecutableFileName]);
    if Pos('"', ExecutableFileName) > 0 then
        raise Exception.Create('O caminho do executável contém aspas e não pode ser registrado.');
end;

procedure AssociateMarkdownFiles(const ExecutableFileName: string);
var
    RegistryWriter: TRegistry;
begin
    ValidateExecutable(ExecutableFileName);
    RegistryWriter := TRegistry.Create(KEY_WRITE);
    try
        RegistryWriter.RootKey := HKEY_CURRENT_USER;
        RegisterProgId(RegistryWriter, ExecutableFileName);
        RegisterApplication(RegistryWriter, ExecutableFileName);
        RegisterCapabilities(RegistryWriter);
        RegisterExtension(RegistryWriter, '.md');
        RegisterExtension(RegistryWriter, '.markdown');
    finally
        RegistryWriter.Free;
    end;
    SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nil, nil);
end;

end.
