unit Language_Server_Process;

{$MODE objfpc}
{$H+}

interface

uses
    Process;

procedure ConfigureLanguageServerProcess(ServerProcess: TProcess; const ExecutableFileName, Arguments: string);

implementation

uses
    SysUtils;

procedure ConfigureLanguageServerProcess(ServerProcess: TProcess; const ExecutableFileName, Arguments: string);
begin
    ServerProcess.Executable := ExecutableFileName;
    ServerProcess.Parameters.Clear;
    CommandToList(Arguments, ServerProcess.Parameters);
    ServerProcess.Options := [poUsePipes, poNoConsole];
    ServerProcess.CurrentDirectory := ExtractFileDir(ExecutableFileName);
end;

end.
