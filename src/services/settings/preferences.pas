unit Preferences;

{$MODE objfpc}
{$H+}

interface

type
    TEditorPreferences = record
        LoadLastFile: Boolean;
    end;

function DefaultEditorPreferences: TEditorPreferences;
function LoadEditorPreferences(const SettingsFileName: string): TEditorPreferences;
procedure SaveEditorPreferences(const SettingsFileName: string; const EditorPreferences: TEditorPreferences);

implementation

uses
    IniFiles,
    SysUtils;

const
    GeneralSection = 'General';
    LoadLastFileKey = 'LoadLastFile';

function DefaultEditorPreferences: TEditorPreferences;
begin
    Result.LoadLastFile := True;
end;

function LoadEditorPreferences(const SettingsFileName: string): TEditorPreferences;
var
    Settings: TMemIniFile;
begin
    Result := DefaultEditorPreferences;
    Settings := TMemIniFile.Create(SettingsFileName);
    try
        Result.LoadLastFile := Settings.ReadBool(GeneralSection, LoadLastFileKey, Result.LoadLastFile);
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
        Settings.UpdateFile;
    finally
        Settings.Free;
    end;
end;

end.
