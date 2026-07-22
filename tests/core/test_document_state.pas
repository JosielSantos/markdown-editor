unit Test_Document_State;

{$MODE objfpc}
{$H+}

interface

uses
    FpcUnit;

type
    TDocumentStateTests = class(TTestCase)
    published
        procedure DetectsContentChanges;
        procedure ClearsModifiedStateWhenContentIsRestored;
    end;

implementation

uses
    Document_State,
    TestRegistry;

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
