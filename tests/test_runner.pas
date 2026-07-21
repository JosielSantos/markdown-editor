program TestRunner;

{$MODE objfpc}
{$H+}

uses
    SimpleTestRunner,
    Test_Command_Line,
    Test_Document_State,
    Test_File_Association_Service,
    Test_File_Service,
    Test_Link_Navigation,
    Test_Line_Navigation,
    Test_Markdown_Renderer,
    Test_Recent_Files;

var
    Runner: TTestRunner;
begin
    Runner := TTestRunner.Create(nil);
    try
        Runner.Initialize;
        Runner.Title := 'Testes do Markdown Editor';
        Runner.Run;
    finally
        Runner.Free;
    end;
end.
