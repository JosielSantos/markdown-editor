program TestRunner;

{$MODE objfpc}
{$H+}

uses
    SimpleTestRunner,
    Test_Command_Line,
    Test_Document_State,
    Test_File_Association,
    Test_File_Position_History,
    Test_Files,
    Test_Html_Export,
    Test_Link_Navigation,
    Test_Line_Navigation,
    Test_Link,
    Test_Lsp_Client_Thread,
    Test_Lsp_Diagnostics,
    Test_Lsp_Protocol,
    Test_Preferences,
    Test_Renderer,
    Test_Recent_Files,
    Test_Session;

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
