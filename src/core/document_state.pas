unit Document_State;

{$MODE objfpc}
{$H+}

interface

const
    DOCUMENT_ENCODING_UTF8 = 'utf8';

type
    TDocumentEncoding = record
        Name: string;
        HasUtf8Bom: Boolean;
    end;

    TDocumentState = record
        Encoding: TDocumentEncoding;
        FileName: string;
        SavedContent: string;
    end;

function CreateDocumentState(const FileName: string = ''): TDocumentState;
function HasContentChanged(const CurrentContent, SavedContent: string): Boolean;

implementation

function CreateDocumentState(const FileName: string): TDocumentState;
begin
    Result.Encoding.Name := DOCUMENT_ENCODING_UTF8;
    Result.Encoding.HasUtf8Bom := False;
    Result.FileName := FileName;
    Result.SavedContent := '';
end;

function HasContentChanged(const CurrentContent, SavedContent: string): Boolean;
begin
    Result := CurrentContent <> SavedContent;
end;

end.
