unit Markdown_Inline;

{$mode objfpc}{$H+}

interface

function EscapeHtml(const Value: string): string;
function RenderInlineHtml(const Value: string): string;
function RenderInlineText(const Value: string): string;

implementation

uses
  StrUtils, SysUtils;

function EscapeHtml(const Value: string): string;
var
  Character: Char;
begin
  Result := '';
  for Character in Value do
    case Character of
      '&': Result := Result + '&amp;';
      '<': Result := Result + '&lt;';
      '>': Result := Result + '&gt;';
      '"': Result := Result + '&quot;';
      '''': Result := Result + '&#39;';
    else
      Result := Result + Character;
    end;
end;

function SafeLinkUrl(const Value: string): string;
var
  ColonPosition: SizeInt;
  LowerValue: string;
begin
  Result := Trim(Value);
  LowerValue := LowerCase(Result);
  ColonPosition := Pos(':', LowerValue);
  if (ColonPosition > 0) and
    not StartsStr('http:', LowerValue) and
    not StartsStr('https:', LowerValue) and
    not StartsStr('mailto:', LowerValue) then
    Result := '#';
end;

function RenderInlineHtml(const Value: string): string;
var
  ClosingPosition: SizeInt;
  LabelEnd: SizeInt;
  LinkEnd: SizeInt;
  Position: SizeInt;
  LinkLabel: string;
  LinkUrl: string;
begin
  Result := '';
  Position := 1;
  while Position <= Length(Value) do
  begin
    if (Value[Position] = '\') and (Position < Length(Value)) then
    begin
      Result := Result + EscapeHtml(Value[Position + 1]);
      Inc(Position, 2);
      Continue;
    end;

    if Value[Position] = '`' then
    begin
      ClosingPosition := PosEx('`', Value, Position + 1);
      if ClosingPosition > 0 then
      begin
        Result := Result + '<code>' +
          EscapeHtml(Copy(Value, Position + 1, ClosingPosition - Position - 1)) +
          '</code>';
        Position := ClosingPosition + 1;
        Continue;
      end;
    end;

    if Copy(Value, Position, 2) = '**' then
    begin
      ClosingPosition := PosEx('**', Value, Position + 2);
      if ClosingPosition > 0 then
      begin
        Result := Result + '<strong>' +
          RenderInlineHtml(Copy(Value, Position + 2,
          ClosingPosition - Position - 2)) + '</strong>';
        Position := ClosingPosition + 2;
        Continue;
      end;
    end;

    if Value[Position] = '*' then
    begin
      ClosingPosition := PosEx('*', Value, Position + 1);
      if ClosingPosition > 0 then
      begin
        Result := Result + '<em>' +
          RenderInlineHtml(Copy(Value, Position + 1,
          ClosingPosition - Position - 1)) + '</em>';
        Position := ClosingPosition + 1;
        Continue;
      end;
    end;

    if Value[Position] = '[' then
    begin
      LabelEnd := PosEx('](', Value, Position + 1);
      if LabelEnd > 0 then
      begin
        LinkEnd := PosEx(')', Value, LabelEnd + 2);
        if LinkEnd > 0 then
        begin
          LinkLabel := Copy(Value, Position + 1, LabelEnd - Position - 1);
          LinkUrl := Copy(Value, LabelEnd + 2, LinkEnd - LabelEnd - 2);
          Result := Result + '<a href="' + EscapeHtml(SafeLinkUrl(LinkUrl)) +
            '">' + RenderInlineHtml(LinkLabel) + '</a>';
          Position := LinkEnd + 1;
          Continue;
        end;
      end;
    end;

    Result := Result + EscapeHtml(Value[Position]);
    Inc(Position);
  end;
end;

function RenderInlineText(const Value: string): string;
var
  ClosingPosition: SizeInt;
  LabelEnd: SizeInt;
  LinkEnd: SizeInt;
  Position: SizeInt;
  LinkLabel: string;
  LinkUrl: string;
begin
  Result := '';
  Position := 1;
  while Position <= Length(Value) do
  begin
    if (Value[Position] = '\') and (Position < Length(Value)) then
    begin
      Result := Result + Value[Position + 1];
      Inc(Position, 2);
      Continue;
    end;

    if Copy(Value, Position, 2) = '**' then
    begin
      ClosingPosition := PosEx('**', Value, Position + 2);
      if ClosingPosition > 0 then
      begin
        Result := Result + RenderInlineText(Copy(Value, Position + 2,
          ClosingPosition - Position - 2));
        Position := ClosingPosition + 2;
        Continue;
      end;
    end;

    if Value[Position] in ['*', '`'] then
    begin
      ClosingPosition := PosEx(Value[Position], Value, Position + 1);
      if ClosingPosition > 0 then
      begin
        Result := Result + Copy(Value, Position + 1,
          ClosingPosition - Position - 1);
        Position := ClosingPosition + 1;
        Continue;
      end;
    end;

    if Value[Position] = '[' then
    begin
      LabelEnd := PosEx('](', Value, Position + 1);
      if LabelEnd > 0 then
      begin
        LinkEnd := PosEx(')', Value, LabelEnd + 2);
        if LinkEnd > 0 then
        begin
          LinkLabel := RenderInlineText(Copy(Value, Position + 1,
            LabelEnd - Position - 1));
          LinkUrl := Copy(Value, LabelEnd + 2, LinkEnd - LabelEnd - 2);
          Result := Result + LinkLabel;
          if LinkUrl <> LinkLabel then
            Result := Result + ' (' + LinkUrl + ')';
          Position := LinkEnd + 1;
          Continue;
        end;
      end;
    end;

    Result := Result + Value[Position];
    Inc(Position);
  end;
end;

end.

