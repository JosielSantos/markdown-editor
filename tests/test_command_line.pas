unit Test_Command_Line;

{$MODE objfpc}
{$H+}

interface

uses
    FpcUnit;

type
    TCommandLineTests = class(TTestCase)
    published
        procedure AcceptsNoArguments;
        procedure ParsesMarkdownFileArgument;
        procedure RejectsUnknownOptions;
    end;

implementation

uses
    Command_Line,
    TestRegistry;

procedure TCommandLineTests.AcceptsNoArguments;
var
    ParsedArguments: TCommandLineArguments;
begin
    ParsedArguments := ParseArguments([]);
    AssertEquals('', ParsedArguments.MarkdownFileName);
    AssertEquals('', ParsedArguments.ErrorMessage);
end;

procedure TCommandLineTests.ParsesMarkdownFileArgument;
var
    ParsedArguments: TCommandLineArguments;
begin
    ParsedArguments := ParseArguments(['C:\Meus documentos\anotações.md']);
    AssertEquals('C:\Meus documentos\anotações.md', ParsedArguments.MarkdownFileName);
    AssertEquals('', ParsedArguments.ErrorMessage);
end;

procedure TCommandLineTests.RejectsUnknownOptions;
var
    ParsedArguments: TCommandLineArguments;
begin
    ParsedArguments := ParseArguments(['--render', 'arquivo.md']);
    AssertEquals('', ParsedArguments.MarkdownFileName);
    AssertEquals('Argumento não reconhecido: --render', ParsedArguments.ErrorMessage);
end;

initialization
    RegisterTest(TCommandLineTests);

end.
