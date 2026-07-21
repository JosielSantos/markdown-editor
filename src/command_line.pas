unit Command_Line;

{$MODE objfpc}
{$H+}

interface

type
    TCommandLineAction = (claOpenEditor, claAssociateFiles);

    TCommandLineArguments = record
        Action: TCommandLineAction;
        MarkdownFileName: string;
        ErrorMessage: string;
    end;

    TCommandLineArgumentArray = array of string;

function ParseArguments(const Arguments: array of string): TCommandLineArguments;
function ParseProcessArguments: TCommandLineArguments;

implementation

uses
    ArgParser,
    SysUtils,
    Types;

const
    AssociateFilesCommandName = 'associate-files';
    FileArgumentName = 'file';

function CopyArguments(const Arguments: array of string): TStringDynArray;
var
    ArgumentIndex: Integer;
begin
    Result := nil;
    SetLength(Result, Length(Arguments));
    for ArgumentIndex := Low(Arguments) to High(Arguments) do
        Result[ArgumentIndex] := Arguments[ArgumentIndex];
end;

procedure ConfigureParser(var Parser: TArgParser);
begin
    Parser.Init;
    Parser.SetUsage('markdown-editor [opções] [associate-files | arquivo.md]');
    Parser.AddPositional(FileArgumentName, atString, 'Comando ou arquivo Markdown a abrir');
end;

function ParseArguments(const Arguments: array of string): TCommandLineArguments;
var
    Parser: TArgParser;
    ParserArguments: TStringDynArray;
    UnparsedArguments: TStringDynArray;
begin
    Result.Action := claOpenEditor;
    Result.MarkdownFileName := '';
    Result.ErrorMessage := '';
    FillChar(Parser, SizeOf(Parser), 0);
    ParserArguments := nil;
    UnparsedArguments := nil;
    ConfigureParser(Parser);
    try
        ParserArguments := CopyArguments(Arguments);
        Parser.ParseKnownArgs(ParserArguments, UnparsedArguments);
        if Parser.HasError then
            Result.ErrorMessage := Parser.Error
        else if Length(UnparsedArguments) > 0 then
            Result.ErrorMessage := Format('Argumento não reconhecido: %s', [UnparsedArguments[0]])
        else if SameText(Parser.GetString(FileArgumentName), AssociateFilesCommandName) then
            Result.Action := claAssociateFiles
        else
            Result.MarkdownFileName := Parser.GetString(FileArgumentName);
    finally
        Parser.Done;
    end;
end;

function ParseProcessArguments: TCommandLineArguments;
var
    ArgumentIndex: Integer;
    Arguments: TCommandLineArgumentArray;
begin
    Arguments := nil;
    SetLength(Arguments, ParamCount);
    for ArgumentIndex := 1 to ParamCount do
        Arguments[ArgumentIndex - 1] := ParamStr(ArgumentIndex);
    Result := ParseArguments(Arguments);
end;

end.
