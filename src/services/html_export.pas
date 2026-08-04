unit Html_Export;

{$MODE objfpc}
{$H+}

interface

function HtmlExportFileName(const MarkdownFileName: string): string;
procedure ExportMarkdownToHtmlFile(const Markdown, HtmlTemplate, HtmlFileName: string);

implementation

uses
    Files,
    Renderer,
    SysUtils;

function HtmlExportFileName(const MarkdownFileName: string): string;
begin
    Result := ChangeFileExt(MarkdownFileName, '.html');
end;

procedure ExportMarkdownToHtmlFile(const Markdown, HtmlTemplate, HtmlFileName: string);
begin
    WriteUtf8TextFile(HtmlFileName, MarkdownToHtml(Markdown, HtmlTemplate));
end;

end.
