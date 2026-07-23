unit Test_Document_State;

{$MODE objfpc}
{$H+}

interface

uses
    FpcUnit;

type
    TDocumentStateTests = class(TTestCase)
    published
        procedure CreatesUtf8DocumentState;
        procedure DetectsContentChanges;
        procedure ClearsModifiedStateWhenContentIsRestored;
    end;

implementation

uses
    Document_State,
    TestRegistry;

procedure TDocumentStateTests.CreatesUtf8DocumentState;
var
    Document: TDocumentState;
begin
    Document := CreateDocumentState('documento.md');
    AssertEquals('documento.md', Document.FileName);
    AssertEquals(DOCUMENT_ENCODING_UTF8, Document.Encoding.Name);
    AssertFalse(Document.Encoding.HasUtf8Bom);
    AssertEquals('', Document.SavedContent);
end;

procedure TDocumentStateTests.DetectsContentChanges;
begin
    AssertTrue(HasContentChanged('Conteúdo', 'Conteúdo original'));
end;

procedure TDocumentStateTests.ClearsModifiedStateWhenContentIsRestored;
var
    CurrentContent: string;
    SavedContent: string;
begin
    SavedContent := 'Conteúdo original';
    CurrentContent := 'Conteúdo origina';
    AssertTrue('caractere apagado', HasContentChanged(CurrentContent, SavedContent));
    CurrentContent := CurrentContent + 'l';
    AssertFalse('caractere restaurado', HasContentChanged(CurrentContent, SavedContent));
end;

initialization
    RegisterTest(TDocumentStateTests);

end.
