unit Language_Server_State;

{$MODE objfpc}
{$H+}

interface

type
    TLanguageServerState = (lssStopped, lssInitializing, lssReady, lssFailed);

function LanguageServerIsReady(State: TLanguageServerState): Boolean;
function LanguageServerProblemsUnavailableMessage(State: TLanguageServerState): string;

implementation

function LanguageServerIsReady(State: TLanguageServerState): Boolean;
begin
    Result := State = lssReady;
end;

function LanguageServerProblemsUnavailableMessage(State: TLanguageServerState): string;
begin
    Result := '';
    case State of
        lssStopped:
            Result :=
                'O verificador de Markdown não está em execução. Abra as opções para revisar a configuração e iniciá-lo.';
        lssInitializing:
            Result :=
                'O verificador de Markdown ainda está inicializando. Aguarde antes de consultar a lista de problemas.';
        lssFailed:
            Result :=
                'O verificador de Markdown falhou e não está disponível. Abra as opções para revisar a configuração.';
        lssReady:;
    end;
end;

end.
