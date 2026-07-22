unit Test_Lsp_Diagnostics;

{$MODE objfpc}
{$H+}

interface

uses
    fpcunit,
    testregistry;

type
    TLspDiagnosticsTests = class(TTestCase)
    published
        procedure IgnoresNonDiagnosticMessages;
        procedure ParsesWarningsAndErrors;
        procedure PrefersErrorOnSharedLine;
    end;

implementation

uses
    Lsp_Diagnostics;

const
    DiagnosticsMessage =
        '{"jsonrpc":"2.0","method":"textDocument/publishDiagnostics","params":{'
            + '"uri":"file:///C:/livro.md","diagnostics":['
            + '{"severity":2,"range":{"start":{"line":4,"character":0},"end":{"line":4,"character":2}}},'
            + '{"severity":1,"range":{"start":{"line":8,"character":1},"end":{"line":8,"character":3}}},'
            + '{"severity":3,"range":{"start":{"line":10,"character":0},"end":{"line":10,"character":1}}}'
            + ']}}';

procedure TLspDiagnosticsTests.ParsesWarningsAndErrors;
var
    Diagnostics: TLspDiagnosticArray;
    DocumentUri: string;
begin
    AssertTrue(ParsePublishDiagnostics(DiagnosticsMessage, DocumentUri, Diagnostics));
    AssertEquals('file:///C:/livro.md', DocumentUri);
    AssertEquals(2, Length(Diagnostics));
    AssertEquals(Ord(ldsWarning), Ord(HighestSeverityAtLine(Diagnostics, 5)));
    AssertEquals(Ord(ldsError), Ord(HighestSeverityAtLine(Diagnostics, 9)));
    AssertEquals(Ord(ldsNone), Ord(HighestSeverityAtLine(Diagnostics, 11)));
end;

procedure TLspDiagnosticsTests.PrefersErrorOnSharedLine;
var
    Diagnostics: TLspDiagnosticArray;
begin
    SetLength(Diagnostics, 2);
    Diagnostics[0].LineNumber := 3;
    Diagnostics[0].Severity := ldsWarning;
    Diagnostics[1].LineNumber := 3;
    Diagnostics[1].Severity := ldsError;
    AssertEquals(Ord(ldsError), Ord(HighestSeverityAtLine(Diagnostics, 3)));
end;

procedure TLspDiagnosticsTests.IgnoresNonDiagnosticMessages;
var
    Diagnostics: TLspDiagnosticArray;
    DocumentUri: string;
begin
    AssertFalse(ParsePublishDiagnostics('{"jsonrpc":"2.0","id":1,"result":{}}', DocumentUri, Diagnostics));
end;

initialization
    RegisterTest(TLspDiagnosticsTests);

end.
