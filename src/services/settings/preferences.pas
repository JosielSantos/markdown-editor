unit Preferences;

{$MODE objfpc}
{$H+}

interface

type
    TEditorPreferences = record
        LoadLastFile: Boolean;
        MarkdownCheckerExecutableFileName: string;
        UseMarkdownChecker: Boolean;
    end;

function DefaultEditorPreferences(const DefaultMarkdownCheckerExecutableFileName: string = ''): TEditorPreferences;
function LoadEditorPreferences(
    const SettingsFileName: string;
    const DefaultMarkdownCheckerExecutableFileName: string = ''
): TEditorPreferences;
procedure SaveEditorPreferences(const SettingsFileName: string; const EditorPreferences: TEditorPreferences);

implementation

uses
    IniFiles,
    SysUtils;

const
    GeneralSection = 'General';
    LoadLastFileKey = 'LoadLastFile';
    MarkdownCheckerSection = 'MarkdownLanguageServer';
    MarkdownCheckerEnabledKey = 'Enabled';
    MarkdownCheckerExecutableFileNameKey = 'ExecutableFileName';

function DefaultEditorPreferences(const DefaultMarkdownCheckerExecutableFileName: string): TEditorPreferences;
begin
    Result.LoadLastFile := True;
    Result.MarkdownCheckerExecutableFileName := DefaultMarkdownCheckerExecutableFileName;
    Result.UseMarkdownChecker := True;
end;

function LoadEditorPreferences(
    const SettingsFileName: string;
    const DefaultMarkdownCheckerExecutableFileName: string
): TEditorPreferences;
var
    Settings: TMemIniFile;
begin
    Result := DefaultEditorPreferences(DefaultMarkdownCheckerExecutableFileName);
    Settings := TMemIniFile.Create(SettingsFileName);
    try
        Result.LoadLastFile := Settings.ReadBool(GeneralSection, LoadLastFileKey, Result.LoadLastFile);
        Result.MarkdownCheckerExecutableFileName :=
            Settings.ReadString(
                MarkdownCheckerSection,
                MarkdownCheckerExecutableFileNameKey,
                Result.MarkdownCheckerExecutableFileName
            );
        Result.UseMarkdownChecker :=
            Settings.ReadBool(MarkdownCheckerSection, MarkdownCheckerEnabledKey, Result.UseMarkdownChecker);
    finally
        Settings.Free;
    end;
end;

procedure SaveEditorPreferences(const SettingsFileName: string; const EditorPreferences: TEditorPreferences);
var
    Settings: TMemIniFile;
begin
    ForceDirectories(ExtractFileDir(SettingsFileName));
    Settings := TMemIniFile.Create(SettingsFileName);
    try
        Settings.WriteBool(GeneralSection, LoadLastFileKey, EditorPreferences.LoadLastFile);
        Settings.WriteBool(MarkdownCheckerSection, MarkdownCheckerEnabledKey, EditorPreferences.UseMarkdownChecker);
        Settings.WriteString(
            MarkdownCheckerSection,
            MarkdownCheckerExecutableFileNameKey,
            EditorPreferences.MarkdownCheckerExecutableFileName
        );
        Settings.UpdateFile;
    finally
        Settings.Free;
    end;
end;

end.
