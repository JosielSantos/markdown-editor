unit Editor;

{$MODE objfpc}
{$H+}

interface

function DefaultSettingsFileName: string;

implementation

uses
    SysUtils;

function DefaultSettingsFileName: string;
begin
    Result := IncludeTrailingPathDelimiter(GetAppConfigDir(False)) + 'settings.ini';
end;

end.
