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
        procedure CalculatesMemoLineStartIndex;
        procedure ClampsLineToDocumentBounds;
        procedure RejectsInvalidLineValues;
        procedure TreatsEmptyDocumentAsOneLine;
    end;

implementation

uses
    Classes,
    Line_Navigation,
    SysUtils,
    TestRegistry;

procedure TLineNavigationTests.AcceptsLineWithinDocument;
var
    LineNumber: Integer;
begin
    AssertTrue(TryParseLineNumber(' 2 ', 3, LineNumber));
    AssertEquals(2, LineNumber);
end;

procedure TLineNavigationTests.CalculatesMemoLineStartIndex;
var
    ExpectedIndex: Integer;
    Lines: TStringList;
begin
    Lines := TStringList.Create;
    try
        Lines.Add('Primeira linha');
        Lines.Add('ação');
        Lines.Add('Terceira linha');
        ExpectedIndex :=
            Length(UTF8Decode('Primeira linha'))
                + Length(LineEnding)
                + Length(UTF8Decode('ação'))
                + Length(LineEnding);
        AssertEquals(ExpectedIndex, MemoLineStartIndex(Lines, 3));
    finally
        Lines.Free;
    end;
end;

procedure TLineNavigationTests.ClampsLineToDocumentBounds;
begin
    AssertEquals(1, ClampLineNumber(0, 10));
    AssertEquals(5, ClampLineNumber(5, 10));
    AssertEquals(10, ClampLineNumber(15, 10));
    AssertEquals(1, ClampLineNumber(5, 0));
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
