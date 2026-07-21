unit Test_Line_Navigation;

{$MODE objfpc}
{$H+}

interface

uses
    FpcUnit;

type
    TLineNavigationTests = class(TTestCase)
    published
        procedure AcceptsLineWithinDocument;
        procedure RejectsInvalidLineValues;
        procedure TreatsEmptyDocumentAsOneLine;
    end;

implementation

uses
    Line_Navigation,
    TestRegistry;

procedure TLineNavigationTests.AcceptsLineWithinDocument;
var
    LineNumber: Integer;
begin
    AssertTrue(TryParseLineNumber(' 2 ', 3, LineNumber));
    AssertEquals(2, LineNumber);
end;

procedure TLineNavigationTests.RejectsInvalidLineValues;
var
    LineNumber: Integer;
begin
    AssertFalse('texto', TryParseLineNumber('segunda', 3, LineNumber));
    AssertFalse('zero', TryParseLineNumber('0', 3, LineNumber));
    AssertFalse('acima do limite', TryParseLineNumber('4', 3, LineNumber));
end;

procedure TLineNavigationTests.TreatsEmptyDocumentAsOneLine;
var
    LineNumber: Integer;
begin
    AssertTrue(TryParseLineNumber('1', 0, LineNumber));
    AssertEquals(1, LineNumber);
end;

initialization
    RegisterTest(TLineNavigationTests);

end.
