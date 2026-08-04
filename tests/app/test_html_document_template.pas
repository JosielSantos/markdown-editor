unit Test_Html_Document_Template;

{$MODE objfpc}
{$H+}

interface

uses
    FpcUnit;

type
    THtmlDocumentTemplateTests = class(TTestCase)
    published
        procedure ApplicationExecutableEmbedsDefaultTemplate;
        procedure LoadsEmbeddedDefaultTemplate;
    end;

implementation

uses
    Classes,
    Html_Document_Template,
    StrUtils,
    SysUtils,
    TestRegistry,
    Windows;

procedure THtmlDocumentTemplateTests.ApplicationExecutableEmbedsDefaultTemplate;
var
    ApplicationExecutable: string;
    HtmlTemplate: string;
    ModuleHandle: HMODULE;
    ResourceStream: TResourceStream;
begin
    ApplicationExecutable := IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0))) + 'markdown-editor.exe';
    ModuleHandle := LoadLibraryEx(PChar(ApplicationExecutable), 0, LOAD_LIBRARY_AS_DATAFILE);
    AssertTrue('application executable could not be loaded', ModuleHandle <> 0);
    try
        ResourceStream := TResourceStream.Create(ModuleHandle, 'HTML_DOCUMENT_TEMPLATE', RT_RCDATA);
        try
            SetLength(HtmlTemplate, ResourceStream.Size);
            if ResourceStream.Size > 0 then
                ResourceStream.ReadBuffer(HtmlTemplate[1], ResourceStream.Size);
        finally
            ResourceStream.Free;
        end;
    finally
        FreeLibrary(ModuleHandle);
    end;

    AssertTrue('doctype missing from application resource', ContainsStr(HtmlTemplate, '<!doctype html>'));
    AssertTrue('content placeholder missing from application resource', ContainsStr(HtmlTemplate, '{{content}}'));
end;

procedure THtmlDocumentTemplateTests.LoadsEmbeddedDefaultTemplate;
var
    HtmlTemplate: string;
begin
    HtmlTemplate := LoadDefaultHtmlDocumentTemplate;
    AssertTrue('doctype missing', ContainsStr(HtmlTemplate, '<!doctype html>'));
    AssertTrue('fixed title missing', ContainsStr(HtmlTemplate, '<title>Documento Markdown</title>'));
    AssertTrue('content placeholder missing', ContainsStr(HtmlTemplate, '{{content}}'));
end;

initialization
    RegisterTest(THtmlDocumentTemplateTests);

end.
