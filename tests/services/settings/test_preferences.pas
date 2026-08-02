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
        procedure DefaultsToAskingBeforeUpdatingOpenFile;
        procedure DefaultsToLoadingLastFile;
        procedure DefaultsToNotUsingMarkdownChecker;
        procedure PersistsFileMonitoringMode;
        procedure PersistsLoadLastFilePreference;
        procedure PersistsMarkdownCheckerPreferences;
    end;

implementation

uses
    Preferences,
    SysUtils;

procedure TPreferencesTests.DefaultsToAskingBeforeUpdatingOpenFile;
var
    EditorPreferences: TEditorPreferences;
    SettingsFileName: string;
begin
    SettingsFileName := GetTempFileName('', 'mdeditor');
    try
        EditorPreferences := LoadEditorPreferences(SettingsFileName);
        AssertEquals(Ord(fmmAskBeforeUpdating), Ord(EditorPreferences.FileMonitoringMode));
    finally
        DeleteFile(SettingsFileName);
    end;
end;

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

procedure TPreferencesTests.DefaultsToNotUsingMarkdownChecker;
const
    DefaultExecutableFileName = 'C:\Tools\markdown-checker.exe';
var
    EditorPreferences: TEditorPreferences;
    SettingsFileName: string;
begin
    SettingsFileName := GetTempFileName('', 'mdeditor');
    try
        EditorPreferences := LoadEditorPreferences(SettingsFileName, DefaultExecutableFileName);
        AssertFalse(EditorPreferences.UseMarkdownChecker);
        AssertEquals('', EditorPreferences.MarkdownCheckerArguments);
        AssertEquals(DefaultExecutableFileName, EditorPreferences.MarkdownCheckerExecutableFileName);
    finally
        DeleteFile(SettingsFileName);
    end;
end;

procedure TPreferencesTests.PersistsFileMonitoringMode;
var
    EditorPreferences: TEditorPreferences;
    SettingsFileName: string;
begin
    SettingsFileName := GetTempFileName('', 'mdeditor');
    try
        EditorPreferences := DefaultEditorPreferences;
        EditorPreferences.FileMonitoringMode := fmmAutomatic;
        SaveEditorPreferences(SettingsFileName, EditorPreferences);
        EditorPreferences := LoadEditorPreferences(SettingsFileName);
        AssertEquals(Ord(fmmAutomatic), Ord(EditorPreferences.FileMonitoringMode));

        EditorPreferences.FileMonitoringMode := fmmDisabled;
        SaveEditorPreferences(SettingsFileName, EditorPreferences);
        EditorPreferences := LoadEditorPreferences(SettingsFileName);
        AssertEquals(Ord(fmmDisabled), Ord(EditorPreferences.FileMonitoringMode));
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

procedure TPreferencesTests.PersistsMarkdownCheckerPreferences;
const
    Arguments = '"C:\Program Files\checker\server.js" --stdio';
    ExecutableFileName = 'C:\Tools\custom-checker.exe';
var
    EditorPreferences: TEditorPreferences;
    SettingsFileName: string;
begin
    SettingsFileName := GetTempFileName('', 'mdeditor');
    try
        EditorPreferences := DefaultEditorPreferences;
        EditorPreferences.UseMarkdownChecker := True;
        EditorPreferences.MarkdownCheckerArguments := Arguments;
        EditorPreferences.MarkdownCheckerExecutableFileName := ExecutableFileName;
        SaveEditorPreferences(SettingsFileName, EditorPreferences);

        EditorPreferences := LoadEditorPreferences(SettingsFileName);
        AssertTrue(EditorPreferences.UseMarkdownChecker);
        AssertEquals(Arguments, EditorPreferences.MarkdownCheckerArguments);
        AssertEquals(ExecutableFileName, EditorPreferences.MarkdownCheckerExecutableFileName);
    finally
        DeleteFile(SettingsFileName);
    end;
end;

initialization
    RegisterTest(TPreferencesTests);

end.
