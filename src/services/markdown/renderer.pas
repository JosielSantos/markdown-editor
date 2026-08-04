unit Renderer;

{$MODE objfpc}
{$H+}

interface

function MarkdownToHtml(const Markdown: string): string;

implementation

uses
    Heading_Anchors,
    MarkdownCommonMark,
    StrUtils,
    SysUtils;

const
    DocumentStart =
        '<!doctype html>'
            + LineEnding
            + '<html lang="pt-BR"><head><meta charset="utf-8">'
            + LineEnding
            + '<meta name="viewport" content="width=device-width, initial-scale=1">'
            + LineEnding
            + '<title>Documento Markdown</title>'
            + LineEnding
            + '<style>body{font-family:Segoe UI,sans-serif;line-height:1.6;'
            + 'max-width:75ch;margin:2rem auto;padding:0 1rem}'
            + 'pre,code{font-family:Consolas,monospace}pre{padding:1rem;'
            + 'overflow:auto;background:#eee}blockquote{border-left:.25rem solid #777;'
            + 'margin-left:0;padding-left:1rem}a{color:#0645ad}</style></head><body>'
            + LineEnding;

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

function MarkdownToHtml(const Markdown: string): string;
begin
    Result := DocumentStart + RenderMarkdownFragment(Markdown) + LineEnding + '</body></html>' + LineEnding;
end;

end.
