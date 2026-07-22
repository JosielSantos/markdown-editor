unit Test_Session;

{$MODE objfpc}
{$H+}

interface

uses
    FpcUnit;

type
    TSessionStateTests = class(TTestCase)
    published
        procedure ClearsSessionWithoutActiveFile;
        procedure PersistsLastFileAndLine;
    end;

implementation

uses
    Session,
    SysUtils,
    TestRegistry;

procedure TSessionStateTests.ClearsSessionWithoutActiveFile;
var
    Session: TEditorSession;
    SettingsFileName: string;
begin
    SettingsFileName := GetTempFileName('', 'mdeditor');
    try
        SaveLastSession(SettingsFileName, 'C:\documentos\capitulo.md', 12);
        SaveLastSession(SettingsFileName, '', 1);
        Session := LoadLastSession(SettingsFileName);
        AssertEquals('', Session.FileName);
        AssertEquals(1, Session.LineNumber);
    finally
        DeleteFile(SettingsFileName);
    end;
end;

procedure TSessionStateTests.PersistsLastFileAndLine;
var
    Session: TEditorSession;
    SettingsFileName: string;
begin
    SettingsFileName := GetTempFileName('', 'mdeditor');
    try
        SaveLastSession(SettingsFileName, 'C:\documentos\capitulo.md', 42);
        Session := LoadLastSession(SettingsFileName);
        AssertEquals(ExpandFileName('C:\documentos\capitulo.md'), Session.FileName);
        AssertEquals(42, Session.LineNumber);
    finally
        DeleteFile(SettingsFileName);
    end;
end;

initialization
    RegisterTest(TSessionStateTests);

end.
