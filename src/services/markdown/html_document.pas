unit Html_Document;

{$MODE objfpc}
{$H+}

interface

function BuildHtmlDocument(const HtmlTemplate, Content: string): string;

implementation

uses
    fpTemplate;

function BuildHtmlDocument(const HtmlTemplate, Content: string): string;
var
    TemplateParser: TTemplateParser;
begin
    TemplateParser := TTemplateParser.Create;
    try
        TemplateParser.StartDelimiter := '{{';
        TemplateParser.EndDelimiter := '}}';
        TemplateParser.Values['content'] := Content;
        Result := TemplateParser.ParseString(HtmlTemplate);
    finally
        TemplateParser.Free;
    end;
end;

end.
