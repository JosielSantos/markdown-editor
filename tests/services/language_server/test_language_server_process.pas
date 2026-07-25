unit Test_Language_Server_Process;

{$MODE objfpc}
{$H+}

interface

uses
    fpcunit,
    testregistry;

type
    TLanguageServerProcessTests = class(TTestCase)
    published
        procedure BuildsUnexpectedExitMessage;
        procedure ConfiguresOptionalArguments;
        procedure KeepsTailOfLongErrorOutput;
        procedure LeavesArgumentsEmptyByDefault;
    end;

implementation

uses
    Language_Server_Process,
    Process,
    SysUtils;

procedure TLanguageServerProcessTests.BuildsUnexpectedExitMessage;
begin
    AssertEquals(
        'O servidor de linguagem foi encerrado inesperadamente (código de saída: 23).'
            + LineEnding
            + LineEnding
            + 'Detalhes do servidor:'
            + LineEnding
            + 'Parâmetro inválido.',
        BuildLanguageServerProcessExitMessage(23, 'Parâmetro inválido.' + LineEnding, False)
    );
    AssertEquals(
        'O servidor de linguagem foi encerrado inesperadamente (código de saída: 0).',
        BuildLanguageServerProcessExitMessage(0, '', False)
    );
end;

procedure TLanguageServerProcessTests.ConfiguresOptionalArguments;
const
    Arguments = '"C:\Program Files\nodejs\node_modules\npm\bin\npx-cli.js" --yes remark-language-server --stdio';
    ExecutableFileName = 'C:\Program Files\nodejs\node.exe';
var
    ServerProcess: TProcess;
begin
    ServerProcess := TProcess.Create(nil);
    try
        ConfigureLanguageServerProcess(ServerProcess, ExecutableFileName, Arguments);
        AssertEquals(ExecutableFileName, ServerProcess.Executable);
        AssertEquals(4, ServerProcess.Parameters.Count);
        AssertEquals('C:\Program Files\nodejs\node_modules\npm\bin\npx-cli.js', ServerProcess.Parameters[0]);
        AssertEquals('--yes', ServerProcess.Parameters[1]);
        AssertEquals('remark-language-server', ServerProcess.Parameters[2]);
        AssertEquals('--stdio', ServerProcess.Parameters[3]);
        AssertEquals('C:\Program Files\nodejs', ServerProcess.CurrentDirectory);
        AssertTrue(poUsePipes in ServerProcess.Options);
        AssertTrue(poNoConsole in ServerProcess.Options);
    finally
        ServerProcess.Free;
    end;
end;

procedure TLanguageServerProcessTests.KeepsTailOfLongErrorOutput;
var
    ErrorOutput: RawByteString;
    WasTruncated: Boolean;
begin
    ErrorOutput := '';
    WasTruncated := False;
    AppendLanguageServerErrorOutput(
        ErrorOutput,
        RawByteString(StringOfChar('x', MaximumLanguageServerErrorOutputBytes) + 'final'),
        WasTruncated
    );
    AssertTrue(WasTruncated);
    AssertEquals(MaximumLanguageServerErrorOutputBytes, Length(ErrorOutput));
    AssertEquals('final', Copy(string(ErrorOutput), Length(ErrorOutput) - 4, 5));
    AssertTrue(
        Pos('[início da saída omitido]', BuildLanguageServerProcessExitMessage(1, ErrorOutput, WasTruncated)) > 0
    );
end;

procedure TLanguageServerProcessTests.LeavesArgumentsEmptyByDefault;
var
    ServerProcess: TProcess;
begin
    ServerProcess := TProcess.Create(nil);
    try
        ConfigureLanguageServerProcess(ServerProcess, 'C:\Tools\markdown-lsp.exe', '');
        AssertEquals(0, ServerProcess.Parameters.Count);
    finally
        ServerProcess.Free;
    end;
end;

initialization
    RegisterTest(TLanguageServerProcessTests);

end.
