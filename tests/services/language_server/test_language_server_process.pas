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
        procedure ConfiguresOptionalArguments;
        procedure LeavesArgumentsEmptyByDefault;
    end;

implementation

uses
    Language_Server_Process,
    Process;

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

procedure TLanguageServerProcessTests.LeavesArgumentsEmptyByDefault;
var
    ServerProcess: TProcess;
begin
    ServerProcess := TProcess.Create(nil);
    try
        ConfigureLanguageServerProcess(ServerProcess, 'C:\Tools\marksman.exe', '');
        AssertEquals(0, ServerProcess.Parameters.Count);
    finally
        ServerProcess.Free;
    end;
end;

initialization
    RegisterTest(TLanguageServerProcessTests);

end.
