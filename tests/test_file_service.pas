program TestFileService;

{$mode objfpc}{$H+}

uses
  File_Service, SysUtils;

const
  TestContent = '# Olá' + LineEnding + 'Texto em UTF-8: ação.';
  TestFileName = 'bin' + DirectorySeparator + 'file-service-test.md';

begin
  WriteUtf8TextFile(TestFileName, TestContent);
  if ReadUtf8TextFile(TestFileName) <> TestContent then
  begin
    WriteLn(StdErr, 'FALHOU: conteúdo salvo difere do conteúdo lido.');
    Halt(1);
  end;
  if not DeleteFile(TestFileName) then
  begin
    WriteLn(StdErr, 'FALHOU: arquivo temporário não pôde ser removido.');
    Halt(1);
  end;
  WriteLn('Todos os testes de arquivo passaram.');
end.

