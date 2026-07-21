unit Test_Recent_Files;

{$MODE objfpc}
{$H+}

interface

uses
    FpcUnit;

type
    TRecentFilesTests = class(TTestCase)
    published
        procedure KeepsNewestUniqueFilesWithinLimit;
        procedure PersistsRecentFiles;
    end;

implementation

uses
    Classes,
    Recent_Files,
    SysUtils,
    TestRegistry;

procedure TRecentFilesTests.KeepsNewestUniqueFilesWithinLimit;
var
    FileIndex: Integer;
    Files: TStringList;
begin
    Files := TStringList.Create;
    try
        for FileIndex := 1 to MaximumRecentFiles + 1 do
            AddRecentFile(Files, Format('C:\documentos\arquivo%d.md', [FileIndex]));
        AddRecentFile(Files, 'C:\documentos\arquivo5.md');
        AssertEquals(MaximumRecentFiles, Files.Count);
        AssertEquals(ExpandFileName('C:\documentos\arquivo5.md'), Files[0]);
        AssertEquals(1, Files.IndexOf(ExpandFileName('C:\documentos\arquivo10.md')));
        AssertEquals(-1, Files.IndexOf(ExpandFileName('C:\documentos\arquivo1.md')));
    finally
        Files.Free;
    end;
end;

procedure TRecentFilesTests.PersistsRecentFiles;
var
    Files: TStringList;
    SettingsFileName: string;
begin
    SettingsFileName := GetTempFileName('', 'mdeditor');
    Files := TStringList.Create;
    try
        Files.Add('C:\documentos\primeiro.md');
        Files.Add('C:\documentos\segundo.md');
        SaveRecentFiles(SettingsFileName, Files);
        Files.Clear;
        LoadRecentFiles(SettingsFileName, Files);
        AssertEquals(2, Files.Count);
        AssertEquals('C:\documentos\primeiro.md', Files[0]);
        AssertEquals('C:\documentos\segundo.md', Files[1]);
    finally
        Files.Free;
        DeleteFile(SettingsFileName);
    end;
end;

initialization
    RegisterTest(TRecentFilesTests);

end.
