unit Markdown_Renderer;

{$mode objfpc}{$H+}

interface

function MarkdownToHtml(const Markdown: string): string;

implementation

uses
  MarkdownProcessor;

const
  DocumentStart = '<!doctype html>' + LineEnding +
    '<html lang="pt-BR"><head><meta charset="utf-8">' + LineEnding +
    '<meta name="viewport" content="width=device-width, initial-scale=1">' +
    LineEnding + '<title>Documento Markdown</title>' + LineEnding +
    '<style>body{font-family:Segoe UI,sans-serif;line-height:1.6;' +
    'max-width:75ch;margin:2rem auto;padding:0 1rem}' +
    'pre,code{font-family:Consolas,monospace}pre{padding:1rem;' +
    'overflow:auto;background:#eee}blockquote{border-left:.25rem solid #777;' +
    'margin-left:0;padding-left:1rem}a{color:#0645ad}</style></head><body>' +
    LineEnding;

function RenderMarkdownFragment(const Markdown: string): string;
var
  Processor: TMarkdownProcessor;
begin
  Processor := TMarkdownProcessor.CreateDialect(mdCommonMark);
  try
    Processor.AllowUnsafe := False;
    Result := Processor.Process(Markdown);
  finally
    Processor.Free;
  end;
end;

function MarkdownToHtml(const Markdown: string): string;
begin
  Result := DocumentStart + RenderMarkdownFragment(Markdown) + LineEnding +
    '</body></html>' + LineEnding;
end;

end.


