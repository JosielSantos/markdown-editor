unit Document_State;

{$MODE objfpc}
{$H+}

interface

const
    DOCUMENT_ENCODING_ISO_8859_1 = 'iso88591';
    DOCUMENT_ENCODING_UTF8 = 'utf8';
    DOCUMENT_ENCODING_WINDOWS_1252 = 'cp1252';

type
    TDocumentEncoding = record
        Name: string;
        HasUtf8Bom: Boolean;
    end;

    TDocumentState = record
        Encoding: TDocumentEncoding;
        FileName: string;
        MissingOnDisk: Boolean;
        SavedContent: string;
    end;

function CreateDocumentState(const FileName: string = ''): TDocumentState;
function HasContentChanged(const CurrentContent, SavedContent: string): Boolean;
function HasUnsavedChanges(const CurrentContent: string; const Document: TDocumentState): Boolean;

implementation

function CreateDocumentState(const FileName: string): TDocumentState;
begin
    Result.Encoding.Name := DOCUMENT_ENCODING_UTF8;
    Result.Encoding.HasUtf8Bom := False;
    Result.FileName := FileName;
    Result.MissingOnDisk := False;
    Result.SavedContent := '';
end;

function HasContentChanged(const CurrentContent, SavedContent: string): Boolean;
begin
    Result := CurrentContent <> SavedContent;
end;

function HasUnsavedChanges(const CurrentContent: string; const Document: TDocumentState): Boolean;
begin
    Result := Document.MissingOnDisk or HasContentChanged(CurrentContent, Document.SavedContent);
end;

end.
