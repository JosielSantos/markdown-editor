unit Preferences_Ini;

{$MODE objfpc}
{$H+}

interface

uses
    Editor_Preferences;

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
    FileMonitoringAutomatic = 'automatic';
    FileMonitoringAsk = 'ask';
    FileMonitoringDisabled = 'disabled';
    FileMonitoringModeKey = 'FileMonitoringMode';
    GeneralSection = 'General';
    LoadLastFileKey = 'LoadLastFile';
    MarkdownCheckerSection = 'MarkdownLanguageServer';
    MarkdownCheckerArgumentsKey = 'Arguments';
    MarkdownCheckerEnabledKey = 'Enabled';
    MarkdownCheckerExecutableFileNameKey = 'ExecutableFileName';

function FileMonitoringModeName(Mode: TFileMonitoringMode): string;
begin
    case Mode of
        fmmAutomatic: Result := FileMonitoringAutomatic;
        fmmDisabled: Result := FileMonitoringDisabled;
    else
        Result := FileMonitoringAsk;
    end;
end;

function ParseFileMonitoringMode(const Value: string): TFileMonitoringMode;
begin
    if SameText(Value, FileMonitoringAutomatic) then
        Result := fmmAutomatic
    else if SameText(Value, FileMonitoringDisabled) then
        Result := fmmDisabled
    else
        Result := fmmAskBeforeUpdating;
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
        Result.FileMonitoringMode :=
            ParseFileMonitoringMode(
                Settings.ReadString(
                    GeneralSection,
                    FileMonitoringModeKey,
                    FileMonitoringModeName(Result.FileMonitoringMode)
                )
            );
        Result.LoadLastFile := Settings.ReadBool(GeneralSection, LoadLastFileKey, Result.LoadLastFile);
        Result.MarkdownCheckerArguments :=
            Settings.ReadString(MarkdownCheckerSection, MarkdownCheckerArgumentsKey, Result.MarkdownCheckerArguments);
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
        Settings.WriteString(
            GeneralSection,
            FileMonitoringModeKey,
            FileMonitoringModeName(EditorPreferences.FileMonitoringMode)
        );
        Settings.WriteBool(GeneralSection, LoadLastFileKey, EditorPreferences.LoadLastFile);
        Settings.WriteString(
            MarkdownCheckerSection,
            MarkdownCheckerArgumentsKey,
            EditorPreferences.MarkdownCheckerArguments
        );
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
