unit Heading_Anchor_Service;

{$MODE objfpc}
{$H+}

interface

function AddHeadingAnchors(const Html: string): string;

implementation

uses
    Classes,
    StrUtils,
    SysUtils;

function FindHeading(
    const Html: string;
    StartPosition: SizeInt;
    out HeadingStart, ContentStart, ClosingStart: SizeInt;
    out Level: Char
): Boolean;
var
    SearchPosition: SizeInt;
begin
    SearchPosition := StartPosition;
    repeat
        HeadingStart := PosEx('<h', Html, SearchPosition);
        if HeadingStart = 0 then
            Exit(False);
        if (HeadingStart + 3 <= Length(Html))
            and (Html[HeadingStart + 2] in ['1'..'6'])
            and (Html[HeadingStart + 3] = '>') then
        begin
            Level := Html[HeadingStart + 2];
            ContentStart := HeadingStart + 4;
            ClosingStart := PosEx('</h' + Level + '>', Html, ContentStart);
            Exit(ClosingStart > 0);
        end;
        SearchPosition := HeadingStart + 2;
    until SearchPosition > Length(Html);
    Result := False;
end;

function HeadingSlug(const HeadingHtml: string): string;
var
    Character: Char;
    Index: SizeInt;
    InsideEntity: Boolean;
    InsideTag: Boolean;
begin
    Result := '';
    InsideEntity := False;
    InsideTag := False;
    for Index := 1 to Length(HeadingHtml) do
    begin
        Character := HeadingHtml[Index];
        if InsideTag then
        begin
            InsideTag := Character <> '>';
            Continue;
        end;
        if InsideEntity then
        begin
            InsideEntity := Character <> ';';
            Continue;
        end;
        if Character = '<' then
            InsideTag := True
        else if Character = '&' then
            InsideEntity := True
        else if Character in ['A'..'Z'] then
            Result := Result + Chr(Ord(Character) + Ord('a') - Ord('A'))
        else if Character in ['a'..'z', '0'..'9', '-', '_'] then
            Result := Result + Character
        else if Character in [#9, #10, #13, ' '] then
            Result := Result + '-'
        else if Ord(Character) >= 128 then
            Result := Result + Character;
    end;
end;

function ReserveUniqueSlug(const BaseSlug: string; UsedSlugs: TStrings): string;
var
    Suffix: Integer;
begin
    Result := BaseSlug;
    Suffix := 0;
    while UsedSlugs.IndexOf(Result) >= 0 do
    begin
        Inc(Suffix);
        Result := BaseSlug + '-' + IntToStr(Suffix);
    end;
    UsedSlugs.Add(Result);
end;

function AddHeadingAnchors(const Html: string): string;
var
    Builder: TStringBuilder;
    ClosingStart: SizeInt;
    ClosingTag: string;
    ContentStart: SizeInt;
    Cursor: SizeInt;
    HeadingStart: SizeInt;
    Level: Char;
    Slug: string;
    UsedSlugs: TStringList;
begin
    Builder := TStringBuilder.Create(Length(Html));
    UsedSlugs := TStringList.Create;
    try
        UsedSlugs.CaseSensitive := True;
        Cursor := 1;
        while FindHeading(Html, Cursor, HeadingStart, ContentStart, ClosingStart, Level) do
        begin
            Builder.Append(Copy(Html, Cursor, HeadingStart - Cursor));
            Slug := HeadingSlug(Copy(Html, ContentStart, ClosingStart - ContentStart));
            if Slug <> '' then
            begin
                Slug := ReserveUniqueSlug(Slug, UsedSlugs);
                Builder.Append('<h' + Level + ' id="' + Slug + '">');
            end
            else
                Builder.Append('<h' + Level + '>');
            ClosingTag := '</h' + Level + '>';
            Builder.Append(Copy(Html, ContentStart, ClosingStart - ContentStart + Length(ClosingTag)));
            Cursor := ClosingStart + Length(ClosingTag);
        end;
        Builder.Append(Copy(Html, Cursor, Length(Html) - Cursor + 1));
        Result := Builder.ToString;
    finally
        UsedSlugs.Free;
        Builder.Free;
    end;
end;

end.
