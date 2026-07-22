unit Session_State;

{$MODE objfpc}
{$H+}

interface

type
    TEditorSession = record
        FileName: string;
        LineNumber: Integer;
    end;

function LoadLastSession(const SettingsFileName: string): TEditorSession;
procedure SaveLastSession(const SettingsFileName, FileName: string; LineNumber: Integer);

implementation

uses
    IniFiles,
    SysUtils;

const
    LastSessionSection = 'LastSession';

function LoadLastSession(const SettingsFileName: string): TEditorSession;
var
    Settings: TMemIniFile;
begin
    Result.FileName := '';
    Result.LineNumber := 1;
    Settings := TMemIniFile.Create(SettingsFileName);
    try
        Result.FileName := Settings.ReadString(LastSessionSection, 'FileName', '');
        Result.LineNumber := Settings.ReadInteger(LastSessionSection, 'LineNumber', 1);
        if Result.LineNumber < 1 then
            Result.LineNumber := 1;
    finally
        Settings.Free;
    end;
end;

procedure SaveLastSession(const SettingsFileName, FileName: string; LineNumber: Integer);
var
    Settings: TMemIniFile;
begin
    ForceDirectories(ExtractFileDir(SettingsFileName));
    Settings := TMemIniFile.Create(SettingsFileName);
    try
        Settings.EraseSection(LastSessionSection);
        if FileName <> '' then
        begin
            Settings.WriteString(LastSessionSection, 'FileName', ExpandFileName(FileName));
            Settings.WriteInteger(LastSessionSection, 'LineNumber', LineNumber);
        end;
        Settings.UpdateFile;
    finally
        Settings.Free;
    end;
end;

end.
