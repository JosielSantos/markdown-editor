unit Test_File_Position_History;

{$MODE objfpc}
{$H+}

interface

uses
    FpcUnit;

type
    TFilePositionHistoryTests = class(TTestCase)
    published
        procedure KeepsIndependentFilePositions;
        procedure PreservesLastSessionSettings;
        procedure UpdatesKnownFilePosition;
    end;

implementation

uses
    File_Position_History,
    Session,
    SysUtils,
    TestRegistry;

procedure TFilePositionHistoryTests.KeepsIndependentFilePositions;
var
    SettingsFileName: string;
begin
    SettingsFileName := GetTempFileName('', 'mdeditor');
    try
        SaveFileLine(SettingsFileName, 'C:\livro\capitulo1.md', 12);
        SaveFileLine(SettingsFileName, 'C:\livro\capitulo2.md', 37);
        AssertEquals(12, LoadFileLine(SettingsFileName, 'C:\livro\capitulo1.md'));
        AssertEquals(37, LoadFileLine(SettingsFileName, 'C:\livro\capitulo2.md'));
    finally
        DeleteFile(SettingsFileName);
    end;
end;

procedure TFilePositionHistoryTests.PreservesLastSessionSettings;
var
    Session: TEditorSession;
    SettingsFileName: string;
begin
    SettingsFileName := GetTempFileName('', 'mdeditor');
    try
        SaveLastSession(SettingsFileName, 'C:\livro\capitulo.md', 18);
        SaveFileLine(SettingsFileName, 'C:\livro\capitulo.md', 18);
        Session := LoadLastSession(SettingsFileName);
        AssertEquals(ExpandFileName('C:\livro\capitulo.md'), Session.FileName);
        AssertEquals(18, Session.LineNumber);
    finally
        DeleteFile(SettingsFileName);
    end;
end;

procedure TFilePositionHistoryTests.UpdatesKnownFilePosition;
var
    SettingsFileName: string;
begin
    SettingsFileName := GetTempFileName('', 'mdeditor');
    try
        SaveFileLine(SettingsFileName, 'C:\livro\capitulo.md', 8);
        SaveFileLine(SettingsFileName, 'C:\LIVRO\CAPITULO.MD', 21);
        AssertEquals(21, LoadFileLine(SettingsFileName, 'C:\livro\capitulo.md'));
        SaveFileLine(SettingsFileName, 'C:\livro\capitulo.md', 0);
        AssertEquals(1, LoadFileLine(SettingsFileName, 'C:\livro\capitulo.md'));
    finally
        DeleteFile(SettingsFileName);
    end;
end;

initialization
    RegisterTest(TFilePositionHistoryTests);

end.
