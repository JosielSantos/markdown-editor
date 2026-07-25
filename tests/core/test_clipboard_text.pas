unit Test_Clipboard_Text;

{$MODE objfpc}
{$H+}

interface

uses
    FpcUnit;

type
    TClipboardTextTests = class(TTestCase)
    published
        procedure KeepsTextWithoutLineBreaks;
        procedure NormalizesCarriageReturns;
        procedure NormalizesLineFeeds;
        procedure NormalizesMixedLineBreaks;
        procedure PreservesCrLfLineBreaks;
    end;

implementation

uses
    Clipboard_Text,
    TestRegistry;

procedure TClipboardTextTests.KeepsTextWithoutLineBreaks;
begin
    AssertEquals('ação', NormalizeClipboardLineBreaks('ação'));
end;

procedure TClipboardTextTests.NormalizesCarriageReturns;
begin
    AssertEquals('primeira' + #13#10 + 'segunda', NormalizeClipboardLineBreaks('primeira' + #13 + 'segunda'));
end;

procedure TClipboardTextTests.NormalizesLineFeeds;
begin
    AssertEquals('primeira' + #13#10 + 'segunda', NormalizeClipboardLineBreaks('primeira' + #10 + 'segunda'));
end;

procedure TClipboardTextTests.NormalizesMixedLineBreaks;
begin
    AssertEquals(
        'um' + #13#10 + 'dois' + #13#10 + 'três' + #13#10 + 'quatro',
        NormalizeClipboardLineBreaks('um' + #10 + 'dois' + #13 + 'três' + #13#10 + 'quatro')
    );
end;

procedure TClipboardTextTests.PreservesCrLfLineBreaks;
begin
    AssertEquals('primeira' + #13#10 + 'segunda', NormalizeClipboardLineBreaks('primeira' + #13#10 + 'segunda'));
end;

initialization
    RegisterTest(TClipboardTextTests);

end.
