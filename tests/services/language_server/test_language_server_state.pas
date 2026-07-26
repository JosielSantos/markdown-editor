unit Test_Language_Server_State;

{$MODE objfpc}
{$H+}

interface

uses
    FpcUnit,
    Language_Server_State,
    TestRegistry;

type
    TLanguageServerStateTests = class(TTestCase)
    published
        procedure OnlyReadyStateIsRunning;
        procedure ExplainsUnavailableStates;
    end;

implementation

procedure TLanguageServerStateTests.OnlyReadyStateIsRunning;
begin
    AssertFalse(LanguageServerIsReady(lssStopped));
    AssertFalse(LanguageServerIsReady(lssInitializing));
    AssertTrue(LanguageServerIsReady(lssReady));
    AssertFalse(LanguageServerIsReady(lssFailed));
end;

procedure TLanguageServerStateTests.ExplainsUnavailableStates;
begin
    AssertEquals(
        'O verificador de Markdown não está em execução. Abra as opções para revisar a configuração e iniciá-lo.',
        LanguageServerProblemsUnavailableMessage(lssStopped)
    );
    AssertEquals(
        'O verificador de Markdown ainda está inicializando. Aguarde antes de consultar a lista de problemas.',
        LanguageServerProblemsUnavailableMessage(lssInitializing)
    );
    AssertEquals(
        'O verificador de Markdown falhou e não está disponível. Abra as opções para revisar a configuração.',
        LanguageServerProblemsUnavailableMessage(lssFailed)
    );
    AssertEquals('', LanguageServerProblemsUnavailableMessage(lssReady));
end;

initialization
    RegisterTest(TLanguageServerStateTests);

end.
