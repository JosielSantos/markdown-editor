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
        procedure ParsesAssociateFilesCommand;
        procedure ParsesMarkdownFileArgument;
        procedure RejectsArgumentsAfterCommand;
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
    AssertEquals(Ord(claOpenEditor), Ord(ParsedArguments.Action));
    AssertEquals('', ParsedArguments.MarkdownFileName);
    AssertEquals('', ParsedArguments.ErrorMessage);
end;

procedure TCommandLineTests.ParsesAssociateFilesCommand;
var
    ParsedArguments: TCommandLineArguments;
begin
    ParsedArguments := ParseArguments(['associate-files']);
    AssertEquals(Ord(claAssociateFiles), Ord(ParsedArguments.Action));
    AssertEquals('', ParsedArguments.MarkdownFileName);
    AssertEquals('', ParsedArguments.ErrorMessage);
end;

procedure TCommandLineTests.ParsesMarkdownFileArgument;
var
    ParsedArguments: TCommandLineArguments;
begin
    ParsedArguments := ParseArguments(['C:\Meus documentos\anotações.md']);
    AssertEquals(Ord(claOpenEditor), Ord(ParsedArguments.Action));
    AssertEquals('C:\Meus documentos\anotações.md', ParsedArguments.MarkdownFileName);
    AssertEquals('', ParsedArguments.ErrorMessage);
end;

procedure TCommandLineTests.RejectsArgumentsAfterCommand;
var
    ParsedArguments: TCommandLineArguments;
begin
    ParsedArguments := ParseArguments(['associate-files', 'arquivo.md']);
    AssertEquals(Ord(claOpenEditor), Ord(ParsedArguments.Action));
    AssertEquals('Argumento não reconhecido: arquivo.md', ParsedArguments.ErrorMessage);
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
