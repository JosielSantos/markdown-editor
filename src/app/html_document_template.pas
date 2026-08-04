unit Html_Document_Template;

{$MODE objfpc}
{$H+}

interface

function LoadDefaultHtmlDocumentTemplate: string;

implementation

uses
    Classes,
    Windows;

const
    HTML_DOCUMENT_TEMPLATE_RESOURCE = 'HTML_DOCUMENT_TEMPLATE';

function LoadDefaultHtmlDocumentTemplate: string;
var
    ResourceStream: TResourceStream;
begin
    ResourceStream := TResourceStream.Create(HInstance, HTML_DOCUMENT_TEMPLATE_RESOURCE, RT_RCDATA);
    try
        SetLength(Result, ResourceStream.Size);
        if ResourceStream.Size > 0 then
            ResourceStream.ReadBuffer(Result[1], ResourceStream.Size);
    finally
        ResourceStream.Free;
    end;
end;

end.
