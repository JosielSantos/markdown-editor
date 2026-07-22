unit File_Position_History;

{$MODE objfpc}
{$H+}

interface

function LoadFileLine(const SettingsFileName, FileName: string): Integer;
procedure SaveFileLine(const SettingsFileName, FileName: string; LineNumber: Integer);

implementation

uses
    IniFiles,
    SysUtils;

const
    FilePositionsSection = 'FilePositions';

function FindFileIndex(Settings: TCustomIniFile; const FileName: string): Integer;
var
    FileIndex: Integer;
    FileCount: Integer;
begin
    Result := 0;
    FileCount := Settings.ReadInteger(FilePositionsSection, 'Count', 0);
    for FileIndex := 1 to FileCount do
        if SameText(Settings.ReadString(FilePositionsSection, 'File' + IntToStr(FileIndex), ''), FileName) then
            Exit(FileIndex);
end;

function LoadFileLine(const SettingsFileName, FileName: string): Integer;
var
    FileIndex: Integer;
    Settings: TMemIniFile;
begin
    Result := 1;
    if FileName = '' then
        Exit;
    Settings := TMemIniFile.Create(SettingsFileName);
    try
        FileIndex := FindFileIndex(Settings, ExpandFileName(FileName));
        if FileIndex > 0 then
            Result := Settings.ReadInteger(FilePositionsSection, 'Line' + IntToStr(FileIndex), 1);
        if Result < 1 then
            Result := 1;
    finally
        Settings.Free;
    end;
end;

procedure SaveFileLine(const SettingsFileName, FileName: string; LineNumber: Integer);
var
    FileIndex: Integer;
    ResolvedFileName: string;
    Settings: TMemIniFile;
begin
    if FileName = '' then
        Exit;
    ForceDirectories(ExtractFileDir(SettingsFileName));
    ResolvedFileName := ExpandFileName(FileName);
    Settings := TMemIniFile.Create(SettingsFileName);
    try
        FileIndex := FindFileIndex(Settings, ResolvedFileName);
        if FileIndex = 0 then
        begin
            FileIndex := Settings.ReadInteger(FilePositionsSection, 'Count', 0) + 1;
            Settings.WriteInteger(FilePositionsSection, 'Count', FileIndex);
            Settings.WriteString(FilePositionsSection, 'File' + IntToStr(FileIndex), ResolvedFileName);
        end;
        if LineNumber < 1 then
            LineNumber := 1;
        Settings.WriteInteger(FilePositionsSection, 'Line' + IntToStr(FileIndex), LineNumber);
        Settings.UpdateFile;
    finally
        Settings.Free;
    end;
end;

end.
