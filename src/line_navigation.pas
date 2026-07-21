unit Line_Navigation;

{$MODE objfpc}
{$H+}

interface

function EffectiveLineCount(LineCount: Integer): Integer;
function TryParseLineNumber(const Value: string; LineCount: Integer; out LineNumber: Integer): Boolean;

implementation

uses
    SysUtils;

function EffectiveLineCount(LineCount: Integer): Integer;
begin
    if LineCount < 1 then
        Exit(1);
    Result := LineCount;
end;

function TryParseLineNumber(const Value: string; LineCount: Integer; out LineNumber: Integer): Boolean;
begin
    Result :=
        TryStrToInt(Trim(Value), LineNumber) and (LineNumber >= 1) and (LineNumber <= EffectiveLineCount(LineCount));
end;

end.
