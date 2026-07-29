unit Recent_Files;

{$MODE objfpc}
{$H+}

interface

uses
    Classes;

const
    MaximumRecentFiles = 10;

type
    TFileOpenEvent = function(const FileName: string): Boolean of object;

procedure AddRecentFile(Files: TStrings; const FileName: string);
function LoadRecentFileLine(const SettingsFileName, FileName: string): Integer;
procedure LoadRecentFiles(const SettingsFileName: string; Files: TStrings);
function RemoveMissingRecentFiles(Files: TStrings): Boolean;
procedure SaveRecentFileLine(const SettingsFileName, FileName: string; LineNumber: Integer);
procedure SaveRecentFiles(const SettingsFileName: string; Files: TStrings);
function TryOpenMostRecentAvailableFile(const SettingsFileName: string; OpenFileHandler: TFileOpenEvent): Boolean;

implementation

uses
    IniFiles,
    SysUtils;

const
    RecentFilesSection = 'RecentFiles';

type
    TRecentFileEntry = record
        FileName: string;
        LineNumber: Integer;
    end;

    TRecentFileEntries = array[0..MaximumRecentFiles - 1] of TRecentFileEntry;

procedure AddRecentFile(Files: TStrings; const FileName: string);
var
    FileIndex: Integer;
    ResolvedFileName: string;
begin
    ResolvedFileName := ExpandFileName(FileName);
    for FileIndex := Files.Count - 1 downto 0 do
        if SameText(Files[FileIndex], ResolvedFileName) then
            Files.Delete(FileIndex);
    Files.Insert(0, ResolvedFileName);
    while Files.Count > MaximumRecentFiles do
        Files.Delete(Files.Count - 1);
end;

function FindEntryIndex(const Entries: TRecentFileEntries; EntryCount: Integer; const FileName: string): Integer;
var
    EntryIndex: Integer;
begin
    Result := -1;
    for EntryIndex := 0 to EntryCount - 1 do
        if SameText(Entries[EntryIndex].FileName, FileName) then
            Exit(EntryIndex);
end;

procedure LoadEntries(Settings: TCustomIniFile; out Entries: TRecentFileEntries; out EntryCount: Integer);
var
    FileIndex: Integer;
    FileName: string;
begin
    EntryCount := 0;
    for FileIndex := 1 to MaximumRecentFiles do
    begin
        FileName := Settings.ReadString(RecentFilesSection, 'File' + IntToStr(FileIndex), '');
        if FileName = '' then
            Continue;
        Entries[EntryCount].FileName := FileName;
        Entries[EntryCount].LineNumber := Settings.ReadInteger(RecentFilesSection, 'Line' + IntToStr(FileIndex), 0);
        if Entries[EntryCount].LineNumber < 1 then
            Entries[EntryCount].LineNumber := 1;
        Inc(EntryCount);
    end;
end;

procedure SaveEntries(Settings: TMemIniFile; const Entries: TRecentFileEntries; EntryCount: Integer);
var
    EntryIndex: Integer;
begin
    Settings.EraseSection(RecentFilesSection);
    for EntryIndex := 0 to EntryCount - 1 do
    begin
        Settings.WriteString(RecentFilesSection, 'File' + IntToStr(EntryIndex + 1), Entries[EntryIndex].FileName);
        Settings.WriteInteger(RecentFilesSection, 'Line' + IntToStr(EntryIndex + 1), Entries[EntryIndex].LineNumber);
    end;
    Settings.UpdateFile;
end;

function LoadRecentFileLine(const SettingsFileName, FileName: string): Integer;
var
    Entries: TRecentFileEntries;
    EntryCount: Integer;
    EntryIndex: Integer;
    Settings: TMemIniFile;
begin
    Result := 1;
    if FileName = '' then
        Exit;
    Settings := TMemIniFile.Create(SettingsFileName);
    try
        LoadEntries(Settings, Entries, EntryCount);
        EntryIndex := FindEntryIndex(Entries, EntryCount, ExpandFileName(FileName));
        if EntryIndex >= 0 then
            Result := Entries[EntryIndex].LineNumber;
    finally
        Settings.Free;
    end;
end;

procedure LoadRecentFiles(const SettingsFileName: string; Files: TStrings);
var
    Entries: TRecentFileEntries;
    EntryCount: Integer;
    EntryIndex: Integer;
    Settings: TMemIniFile;
begin
    Files.Clear;
    Settings := TMemIniFile.Create(SettingsFileName);
    try
        LoadEntries(Settings, Entries, EntryCount);
        for EntryIndex := 0 to EntryCount - 1 do
            Files.Add(Entries[EntryIndex].FileName);
    finally
        Settings.Free;
    end;
end;

function RemoveMissingRecentFiles(Files: TStrings): Boolean;
var
    FileIndex: Integer;
begin
    Result := False;
    for FileIndex := Files.Count - 1 downto 0 do
        if not FileExists(Files[FileIndex]) then
        begin
            Files.Delete(FileIndex);
            Result := True;
        end;
end;

procedure SaveRecentFileLine(const SettingsFileName, FileName: string; LineNumber: Integer);
var
    Entries: TRecentFileEntries;
    EntryCount: Integer;
    EntryIndex: Integer;
    ResolvedFileName: string;
    Settings: TMemIniFile;
begin
    if FileName = '' then
        Exit;
    ForceDirectories(ExtractFileDir(SettingsFileName));
    ResolvedFileName := ExpandFileName(FileName);
    if LineNumber < 1 then
        LineNumber := 1;
    Settings := TMemIniFile.Create(SettingsFileName);
    try
        LoadEntries(Settings, Entries, EntryCount);
        EntryIndex := FindEntryIndex(Entries, EntryCount, ResolvedFileName);
        if EntryIndex < 0 then
        begin
            if EntryCount < MaximumRecentFiles then
                Inc(EntryCount);
            for EntryIndex := EntryCount - 1 downto 1 do
                Entries[EntryIndex] := Entries[EntryIndex - 1];
            EntryIndex := 0;
            Entries[EntryIndex].FileName := ResolvedFileName;
        end;
        Entries[EntryIndex].LineNumber := LineNumber;
        SaveEntries(Settings, Entries, EntryCount);
    finally
        Settings.Free;
    end;
end;

procedure SaveRecentFiles(const SettingsFileName: string; Files: TStrings);
var
    Entries: TRecentFileEntries;
    EntryCount: Integer;
    EntryIndex: Integer;
    ExistingEntries: TRecentFileEntries;
    ExistingEntryCount: Integer;
    ExistingEntryIndex: Integer;
    Settings: TMemIniFile;
begin
    ForceDirectories(ExtractFileDir(SettingsFileName));
    Settings := TMemIniFile.Create(SettingsFileName);
    try
        LoadEntries(Settings, ExistingEntries, ExistingEntryCount);
        EntryCount := Files.Count;
        if EntryCount > MaximumRecentFiles then
            EntryCount := MaximumRecentFiles;
        for EntryIndex := 0 to EntryCount - 1 do
        begin
            Entries[EntryIndex].FileName := Files[EntryIndex];
            ExistingEntryIndex := FindEntryIndex(ExistingEntries, ExistingEntryCount, Entries[EntryIndex].FileName);
            if ExistingEntryIndex >= 0 then
                Entries[EntryIndex].LineNumber := ExistingEntries[ExistingEntryIndex].LineNumber
            else
                Entries[EntryIndex].LineNumber := 1;
        end;
        SaveEntries(Settings, Entries, EntryCount);
    finally
        Settings.Free;
    end;
end;

function TryOpenMostRecentAvailableFile(const SettingsFileName: string; OpenFileHandler: TFileOpenEvent): Boolean;
var
    FileIndex: Integer;
    Files: TStringList;
begin
    Result := False;
    if not Assigned(OpenFileHandler) then
        Exit;
    Files := TStringList.Create;
    try
        try
            LoadRecentFiles(SettingsFileName, Files);
        except
            Exit;
        end;
        if RemoveMissingRecentFiles(Files) then
            try
                SaveRecentFiles(SettingsFileName, Files);
            except
            end;
        for FileIndex := 0 to Files.Count - 1 do
            try
                if OpenFileHandler(Files[FileIndex]) then
                    Exit(True);
            except
            end;
    finally
        Files.Free;
    end;
end;

end.
