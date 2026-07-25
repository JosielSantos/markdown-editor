unit Language_Server_Process;

{$MODE objfpc}
{$H+}

interface

uses
    Process;

const
    MaximumLanguageServerErrorOutputBytes = 4096;

procedure AppendLanguageServerErrorOutput(
    var ErrorOutput: RawByteString;
    const Chunk: RawByteString;
    var WasTruncated: Boolean
);
function BuildLanguageServerProcessExitMessage(
    ExitStatus: LongInt;
    const ErrorOutput: RawByteString;
    WasTruncated: Boolean
): string;
procedure ConfigureLanguageServerProcess(ServerProcess: TProcess; const ExecutableFileName, Arguments: string);

implementation

uses
    SysUtils;

procedure AppendLanguageServerErrorOutput(
    var ErrorOutput: RawByteString;
    const Chunk: RawByteString;
    var WasTruncated: Boolean
);
begin
    ErrorOutput := ErrorOutput + Chunk;
    if Length(ErrorOutput) <= MaximumLanguageServerErrorOutputBytes then
        Exit;
    Delete(ErrorOutput, 1, Length(ErrorOutput) - MaximumLanguageServerErrorOutputBytes);
    WasTruncated := True;
end;

function BuildLanguageServerProcessExitMessage(
    ExitStatus: LongInt;
    const ErrorOutput: RawByteString;
    WasTruncated: Boolean
): string;
var
    Details: string;
begin
    Result := Format('O servidor de linguagem foi encerrado inesperadamente (código de saída: %d).', [ExitStatus]);
    Details := Trim(string(ErrorOutput));
    if Details = '' then
        Exit;
    Result := Result + LineEnding + LineEnding + 'Detalhes do servidor:' + LineEnding;
    if WasTruncated then
        Result := Result + '[início da saída omitido]' + LineEnding;
    Result := Result + Details;
end;

procedure ConfigureLanguageServerProcess(ServerProcess: TProcess; const ExecutableFileName, Arguments: string);
begin
    ServerProcess.Executable := ExecutableFileName;
    ServerProcess.Parameters.Clear;
    CommandToList(Arguments, ServerProcess.Parameters);
    ServerProcess.Options := [poUsePipes, poNoConsole];
    ServerProcess.CurrentDirectory := ExtractFileDir(ExecutableFileName);
end;

end.
