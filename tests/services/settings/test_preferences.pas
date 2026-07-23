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
        procedure DefaultsToUsingMarkdownChecker;
        procedure PersistsLoadLastFilePreference;
        procedure PersistsMarkdownCheckerPreferences;
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

procedure TPreferencesTests.DefaultsToUsingMarkdownChecker;
const
    DefaultExecutableFileName = 'C:\Tools\markdown-checker.exe';
var
    EditorPreferences: TEditorPreferences;
    SettingsFileName: string;
begin
    SettingsFileName := GetTempFileName('', 'mdeditor');
    try
        EditorPreferences := LoadEditorPreferences(SettingsFileName, DefaultExecutableFileName);
        AssertTrue(EditorPreferences.UseMarkdownChecker);
        AssertEquals('', EditorPreferences.MarkdownCheckerArguments);
        AssertEquals(DefaultExecutableFileName, EditorPreferences.MarkdownCheckerExecutableFileName);
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
        EditorPreferences.UseMarkdownChecker := False;
        EditorPreferences.MarkdownCheckerArguments := Arguments;
        EditorPreferences.MarkdownCheckerExecutableFileName := ExecutableFileName;
        SaveEditorPreferences(SettingsFileName, EditorPreferences);

        EditorPreferences := LoadEditorPreferences(SettingsFileName);
        AssertFalse(EditorPreferences.UseMarkdownChecker);
        AssertEquals(Arguments, EditorPreferences.MarkdownCheckerArguments);
        AssertEquals(ExecutableFileName, EditorPreferences.MarkdownCheckerExecutableFileName);
    finally
        DeleteFile(SettingsFileName);
    end;
end;

initialization
    RegisterTest(TPreferencesTests);

end.
