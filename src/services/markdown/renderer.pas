unit Renderer;

{$MODE objfpc}
{$H+}

interface

function MarkdownToHtml(const Markdown, HtmlTemplate: string): string;

implementation

uses
    Heading_Anchors,
    Html_Document,
    MarkdownCommonMark,
    StrUtils,
    SysUtils;

function WithoutFrontMatter(const Markdown: string): string;
var
    ClosingDelimiter: SizeInt;
begin
    Result := StringReplace(Markdown, #13#10, #10, [rfReplaceAll]);
    Result := StringReplace(Result, #13, #10, [rfReplaceAll]);

    if Copy(Result, 1, 4) <> '---' + #10 then
        Exit;

    ClosingDelimiter := PosEx(#10 + '---' + #10, Result, 4);
    if ClosingDelimiter > 0 then
        Result := Copy(Result, ClosingDelimiter + 5, MaxInt)
    else if RightStr(Result, 4) = #10 + '---' then
        Result := '';
end;

function RenderTaskListItems(const Html: string): string;
begin
    Result := StringReplace(Html, '<li>[] ', '<li><input type="checkbox" disabled> ', [rfReplaceAll]);
    Result := StringReplace(Result, '<li>[ ] ', '<li><input type="checkbox" disabled> ', [rfReplaceAll]);
    Result :=
        StringReplace(
            Result,
            '<li>[x] ',
            '<li><input type="checkbox" checked disabled> ',
            [rfReplaceAll, rfIgnoreCase]
        );
end;

function RenderMarkdownFragment(const Markdown: string): string;
begin
    Result := AddHeadingAnchors(RenderTaskListItems(TCommonMarkEngine.Process(WithoutFrontMatter(Markdown), True)));
end;

function MarkdownToHtml(const Markdown, HtmlTemplate: string): string;
begin
    Result := BuildHtmlDocument(HtmlTemplate, RenderMarkdownFragment(Markdown));
end;

end.
