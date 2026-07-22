#define AppName "Markdown Editor"
#define AppVersion "0.2.1"
#define AppPublisher "Josiel Santos"
#define AppUrl "https://github.com/JosielSantos/markdown-editor"
#define AppExecutable "markdown-editor.exe"

[Setup]
AppId={{52EDD940-B8B1-4265-AE05-58ADAE5EB6F6}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppUrl}
AppSupportURL={#AppUrl}
AppUpdatesURL={#AppUrl}
DefaultDirName={userpf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
ChangesAssociations=yes
UninstallDisplayIcon={app}\{#AppExecutable}
OutputDir=..\dist
OutputBaseFilename=markdown-editor-{#AppVersion}-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "associatefiles"; Description: "Associar arquivos Markdown"; GroupDescription: "Opções adicionais:"; Flags: unchecked
Name: "startapplication"; Description: "Executar aplicação após instalar"; GroupDescription: "Opções adicionais:"; Flags: checkedonce

[Files]
Source: "..\bin\{#AppExecutable}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\bin\WebView2Loader.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\THIRD_PARTY_NOTICES.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExecutable}"; WorkingDir: "{app}"
Name: "{group}\Desinstalar {#AppName}"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\{#AppExecutable}"; Parameters: "associate-files --start --quiet"; WorkingDir: "{app}"; Flags: nowait; Tasks: associatefiles and startapplication
Filename: "{app}\{#AppExecutable}"; Parameters: "associate-files --quiet"; WorkingDir: "{app}"; Tasks: associatefiles and not startapplication
Filename: "{app}\{#AppExecutable}"; WorkingDir: "{app}"; Flags: nowait; Tasks: startapplication and not associatefiles
