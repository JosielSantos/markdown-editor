unit Line_Navigation;

{$MODE objfpc}
{$H+}

interface

uses
    Classes;

function EffectiveLineCount(LineCount: Integer): Integer;
function ClampLineNumber(LineNumber, LineCount: Integer): Integer;
function MemoLineStartIndex(const Lines: TStrings; LineNumber: Integer): Integer;
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

function ClampLineNumber(LineNumber, LineCount: Integer): Integer;
begin
    Result := LineNumber;
    if Result < 1 then
        Result := 1;
    if Result > EffectiveLineCount(LineCount) then
        Result := EffectiveLineCount(LineCount);
end;

function MemoLineStartIndex(const Lines: TStrings; LineNumber: Integer): Integer;
var
    LineIndex: Integer;
begin
    Result := 0;
    for LineIndex := 0 to LineNumber - 2 do
        Inc(Result, Length(UTF8Decode(Lines[LineIndex])) + Length(LineEnding));
end;

function TryParseLineNumber(const Value: string; LineCount: Integer; out LineNumber: Integer): Boolean;
begin
    Result :=
        TryStrToInt(Trim(Value), LineNumber) and (LineNumber >= 1) and (LineNumber <= EffectiveLineCount(LineCount));
end;

end.
