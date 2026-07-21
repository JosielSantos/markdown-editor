program TestRunner;

{$mode objfpc}{$H+}

uses
  SimpleTestRunner, Test_File_Service, Test_Markdown_Renderer;

var
  Runner: TTestRunner;
begin
  Runner := TTestRunner.Create(nil);
  try
    Runner.Initialize;
    Runner.Title := 'Testes do Editor Markdown Acessível';
    Runner.Run;
  finally
    Runner.Free;
  end;
end.
