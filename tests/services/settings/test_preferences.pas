unit Test_Preferences;

{$MODE objfpc}
{$H+}

interface

uses
    fpcunit,
    testregistry;

type
    TPreferencesTests = class(TTestCase)
    published
        procedure DefaultsToLoadingLastFile;
        procedure PersistsLoadLastFilePreference;
    end;

implementation

uses
    Preferences,
    SysUtils;

procedure TPreferencesTests.DefaultsToLoadingLastFile;
var
    EditorPreferences: TEditorPreferences;
    SettingsFileName: string;
begin
    SettingsFileName := GetTempFileName('', 'mdeditor');
    try
        EditorPreferences := LoadEditorPreferences(SettingsFileName);
        AssertTrue(EditorPreferences.LoadLastFile);
    finally
        DeleteFile(SettingsFileName);
    end;
end;

procedure TPreferencesTests.PersistsLoadLastFilePreference;
var
    EditorPreferences: TEditorPreferences;
    SettingsFileName: string;
begin
    SettingsFileName := GetTempFileName('', 'mdeditor');
    try
        EditorPreferences := DefaultEditorPreferences;
        EditorPreferences.LoadLastFile := False;
        SaveEditorPreferences(SettingsFileName, EditorPreferences);
        EditorPreferences := LoadEditorPreferences(SettingsFileName);
        AssertFalse(EditorPreferences.LoadLastFile);

        EditorPreferences.LoadLastFile := True;
        SaveEditorPreferences(SettingsFileName, EditorPreferences);
        EditorPreferences := LoadEditorPreferences(SettingsFileName);
        AssertTrue(EditorPreferences.LoadLastFile);
    finally
        DeleteFile(SettingsFileName);
    end;
end;

initialization
    RegisterTest(TPreferencesTests);

end.
