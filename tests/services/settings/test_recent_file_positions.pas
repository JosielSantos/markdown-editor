unit Test_Recent_File_Positions;

{$MODE objfpc}
{$H+}

interface

uses
    FpcUnit;

type
    TRecentFilePositionTests = class(TTestCase)
    published
        procedure KeepsIndependentFilePositions;
        procedure LimitsPositionsToRecentFileLimit;
        procedure PreservesPositionsWhenFilesAreReordered;
        procedure UpdatesKnownFilePosition;
    end;

implementation

uses
    Classes,
    Recent_Files,
    SysUtils,
    TestRegistry;

procedure TRecentFilePositionTests.KeepsIndependentFilePositions;
var
    SettingsFileName: string;
begin
    SettingsFileName := GetTempFileName('', 'mdeditor');
    try
        SaveRecentFileLine(SettingsFileName, 'C:\livro\capitulo1.md', 12);
        SaveRecentFileLine(SettingsFileName, 'C:\livro\capitulo2.md', 37);
        AssertEquals(12, LoadRecentFileLine(SettingsFileName, 'C:\livro\capitulo1.md'));
        AssertEquals(37, LoadRecentFileLine(SettingsFileName, 'C:\livro\capitulo2.md'));
    finally
        DeleteFile(SettingsFileName);
    end;
end;

procedure TRecentFilePositionTests.LimitsPositionsToRecentFileLimit;
var
    FileIndex: Integer;
    Files: TStringList;
    SettingsFileName: string;
begin
    SettingsFileName := GetTempFileName('', 'mdeditor');
    Files := TStringList.Create;
    try
        for FileIndex := 1 to MaximumRecentFiles + 1 do
            SaveRecentFileLine(SettingsFileName, Format('C:\livro\capitulo%d.md', [FileIndex]), FileIndex + 10);
        LoadRecentFiles(SettingsFileName, Files);
        AssertEquals(MaximumRecentFiles, Files.Count);
        AssertEquals(1, LoadRecentFileLine(SettingsFileName, 'C:\livro\capitulo1.md'));
        AssertEquals(12, LoadRecentFileLine(SettingsFileName, 'C:\livro\capitulo2.md'));
        AssertEquals(21, LoadRecentFileLine(SettingsFileName, 'C:\livro\capitulo11.md'));
    finally
        Files.Free;
        DeleteFile(SettingsFileName);
    end;
end;

procedure TRecentFilePositionTests.PreservesPositionsWhenFilesAreReordered;
var
    Files: TStringList;
    FirstFileName: string;
    SecondFileName: string;
    SettingsFileName: string;
begin
    SettingsFileName := GetTempFileName('', 'mdeditor');
    FirstFileName := 'C:\livro\capitulo1.md';
    SecondFileName := 'C:\livro\capitulo2.md';
    Files := TStringList.Create;
    try
        Files.Add(FirstFileName);
        Files.Add(SecondFileName);
        SaveRecentFiles(SettingsFileName, Files);
        SaveRecentFileLine(SettingsFileName, FirstFileName, 12);
        SaveRecentFileLine(SettingsFileName, SecondFileName, 37);
        AddRecentFile(Files, SecondFileName);
        SaveRecentFiles(SettingsFileName, Files);

        AssertEquals(12, LoadRecentFileLine(SettingsFileName, FirstFileName));
        AssertEquals(37, LoadRecentFileLine(SettingsFileName, SecondFileName));
    finally
        Files.Free;
        DeleteFile(SettingsFileName);
    end;
end;

procedure TRecentFilePositionTests.UpdatesKnownFilePosition;
var
    SettingsFileName: string;
begin
    SettingsFileName := GetTempFileName('', 'mdeditor');
    try
        SaveRecentFileLine(SettingsFileName, 'C:\livro\capitulo.md', 8);
        SaveRecentFileLine(SettingsFileName, 'C:\LIVRO\CAPITULO.MD', 21);
        AssertEquals(21, LoadRecentFileLine(SettingsFileName, 'C:\livro\capitulo.md'));
        SaveRecentFileLine(SettingsFileName, 'C:\livro\capitulo.md', 0);
        AssertEquals(1, LoadRecentFileLine(SettingsFileName, 'C:\livro\capitulo.md'));
    finally
        DeleteFile(SettingsFileName);
    end;
end;

initialization
    RegisterTest(TRecentFilePositionTests);

end.
