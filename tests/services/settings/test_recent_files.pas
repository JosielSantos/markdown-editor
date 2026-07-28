unit Test_Recent_Files;

{$MODE objfpc}
{$H+}

interface

uses
    FpcUnit;

type
    TRecentFilesTests = class(TTestCase)
    published
        procedure ContinuesWhenRecentFileCannotBeOpened;
        procedure KeepsNewestUniqueFilesWithinLimit;
        procedure RemovesAllMissingFilesBeforeOpeningMostRecentFile;
        procedure PersistsOnlyMaximumRecentFiles;
        procedure PersistsRecentFiles;
        procedure ReturnsFalseWhenNoRecentFileCanBeOpened;
    end;

implementation

uses
    Classes,
    IniFiles,
    Recent_Files,
    SysUtils,
    TestRegistry;

type
    TDocumentLoader = class
    public
        Attempts: TStringList;
        RejectedFileName: string;
        constructor Create;
        destructor Destroy; override;
        function LoadDocument(const FileName: string): Boolean;
    end;

constructor TDocumentLoader.Create;
begin
    inherited Create;
    Attempts := TStringList.Create;
end;

destructor TDocumentLoader.Destroy;
begin
    Attempts.Free;
    inherited Destroy;
end;

function TDocumentLoader.LoadDocument(const FileName: string): Boolean;
begin
    Attempts.Add(FileName);
    Result := not SameFileName(FileName, RejectedFileName);
end;

procedure TRecentFilesTests.ContinuesWhenRecentFileCannotBeOpened;
var
    Files: TStringList;
    FirstFileName: string;
    Loader: TDocumentLoader;
    SecondFileName: string;
    SettingsFileName: string;
begin
    SettingsFileName := GetTempFileName('', 'mdeditor');
    FirstFileName := SettingsFileName + '.first.md';
    SecondFileName := SettingsFileName + '.second.md';
    Files := TStringList.Create;
    Loader := TDocumentLoader.Create;
    try
        Files.SaveToFile(FirstFileName);
        Files.SaveToFile(SecondFileName);
        Files.Add(FirstFileName);
        Files.Add(SecondFileName);
        SaveRecentFiles(SettingsFileName, Files);
        Loader.RejectedFileName := FirstFileName;

        AssertTrue(
            'Expected a recent file to open',
            TryOpenMostRecentAvailableFile(SettingsFileName, @Loader.LoadDocument)
        );

        AssertEquals('Expected two open attempts', 2, Loader.Attempts.Count);
        AssertEquals(ExpandFileName(FirstFileName), Loader.Attempts[0]);
        AssertEquals(ExpandFileName(SecondFileName), Loader.Attempts[1]);
    finally
        Loader.Free;
        Files.Free;
        DeleteFile(FirstFileName);
        DeleteFile(SecondFileName);
        DeleteFile(SettingsFileName);
    end;
end;

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
        AssertEquals(10, MaximumRecentFiles);
        AssertEquals(MaximumRecentFiles, Files.Count);
        AssertEquals(ExpandFileName('C:\documentos\arquivo5.md'), Files[0]);
        AssertEquals(1, Files.IndexOf(ExpandFileName('C:\documentos\arquivo11.md')));
        AssertEquals(-1, Files.IndexOf(ExpandFileName('C:\documentos\arquivo1.md')));
    finally
        Files.Free;
    end;
end;

procedure TRecentFilesTests.RemovesAllMissingFilesBeforeOpeningMostRecentFile;
var
    AvailableFileName: string;
    Files: TStringList;
    Loader: TDocumentLoader;
    MissingFileName: string;
    Settings: TMemIniFile;
    SettingsFileName: string;
begin
    SettingsFileName := GetTempFileName('', 'mdeditor');
    MissingFileName := SettingsFileName + '.missing.md';
    AvailableFileName := SettingsFileName + '.available.md';
    Files := TStringList.Create;
    Loader := TDocumentLoader.Create;
    try
        Files.SaveToFile(AvailableFileName);
        Files.Add(AvailableFileName);
        Files.Add(MissingFileName);
        SaveRecentFiles(SettingsFileName, Files);

        AssertTrue(
            'Expected a recent file to open',
            TryOpenMostRecentAvailableFile(SettingsFileName, @Loader.LoadDocument)
        );

        AssertEquals(1, Loader.Attempts.Count);
        AssertEquals(ExpandFileName(AvailableFileName), Loader.Attempts[0]);
        Files.Clear;
        LoadRecentFiles(SettingsFileName, Files);
        AssertEquals(1, Files.Count);
        AssertEquals(AvailableFileName, Files[0]);
        Settings := TMemIniFile.Create(SettingsFileName);
        try
            AssertEquals(AvailableFileName, Settings.ReadString('RecentFiles', 'File1', ''));
            AssertEquals('', Settings.ReadString('RecentFiles', 'File2', ''));
            AssertEquals('', Settings.ReadString('RecentFiles', 'File3', ''));
        finally
            Settings.Free;
        end;
    finally
        Loader.Free;
        Files.Free;
        DeleteFile(AvailableFileName);
        DeleteFile(SettingsFileName);
    end;
end;

procedure TRecentFilesTests.PersistsOnlyMaximumRecentFiles;
var
    FileIndex: Integer;
    Files: TStringList;
    SettingsFileName: string;
begin
    SettingsFileName := GetTempFileName('', 'mdeditor');
    Files := TStringList.Create;
    try
        for FileIndex := 1 to MaximumRecentFiles + 1 do
            Files.Add(Format('C:\documentos\arquivo%d.md', [FileIndex]));
        SaveRecentFiles(SettingsFileName, Files);
        Files.Clear;
        LoadRecentFiles(SettingsFileName, Files);
        AssertEquals(MaximumRecentFiles, Files.Count);
        AssertEquals('C:\documentos\arquivo1.md', Files[0]);
        AssertEquals(-1, Files.IndexOf('C:\documentos\arquivo11.md'));
    finally
        Files.Free;
        DeleteFile(SettingsFileName);
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

procedure TRecentFilesTests.ReturnsFalseWhenNoRecentFileCanBeOpened;
var
    Files: TStringList;
    Loader: TDocumentLoader;
    MissingFileName: string;
    SettingsFileName: string;
begin
    SettingsFileName := GetTempFileName('', 'mdeditor');
    MissingFileName := SettingsFileName + '.missing.md';
    Files := TStringList.Create;
    Loader := TDocumentLoader.Create;
    try
        Files.Add(MissingFileName);
        SaveRecentFiles(SettingsFileName, Files);

        AssertFalse(
            'Expected every recent file to fail',
            TryOpenMostRecentAvailableFile(SettingsFileName, @Loader.LoadDocument)
        );

        AssertEquals('Expected no attempt for missing files', 0, Loader.Attempts.Count);
        Files.Clear;
        LoadRecentFiles(SettingsFileName, Files);
        AssertEquals(0, Files.Count);
    finally
        Loader.Free;
        Files.Free;
        DeleteFile(SettingsFileName);
    end;
end;

initialization
    RegisterTest(TRecentFilesTests);

end.
