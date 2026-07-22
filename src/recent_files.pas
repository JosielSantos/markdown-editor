unit Recent_Files;

{$MODE objfpc}
{$H+}

interface

uses
    Classes;

const
    MaximumRecentFiles = 9;

procedure AddRecentFile(Files: TStrings; const FileName: string);
procedure LoadRecentFiles(const SettingsFileName: string; Files: TStrings);
procedure SaveRecentFiles(const SettingsFileName: string; Files: TStrings);

implementation

uses
    IniFiles,
    SysUtils;

const
    RecentFilesSection = 'RecentFiles';

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

procedure LoadRecentFiles(const SettingsFileName: string; Files: TStrings);
var
    FileIndex: Integer;
    RecentFileName: string;
    Settings: TMemIniFile;
begin
    Files.Clear;
    Settings := TMemIniFile.Create(SettingsFileName);
    try
        for FileIndex := 1 to MaximumRecentFiles do
        begin
            RecentFileName := Settings.ReadString(RecentFilesSection, 'File' + IntToStr(FileIndex), '');
            if RecentFileName <> '' then
                Files.Add(RecentFileName);
        end;
    finally
        Settings.Free;
    end;
end;

procedure SaveRecentFiles(const SettingsFileName: string; Files: TStrings);
var
    FileIndex: Integer;
    Settings: TMemIniFile;
begin
    ForceDirectories(ExtractFileDir(SettingsFileName));
    Settings := TMemIniFile.Create(SettingsFileName);
    try
        Settings.EraseSection(RecentFilesSection);
        for FileIndex := 0 to Files.Count - 1 do
            Settings.WriteString(RecentFilesSection, 'File' + IntToStr(FileIndex + 1), Files[FileIndex]);
        Settings.UpdateFile;
    finally
        Settings.Free;
    end;
end;

end.
