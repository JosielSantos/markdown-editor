program TestRunner;

{$MODE objfpc}
{$H+}

uses
    Classes,
    SysUtils,
    FPCUnit,
    TestRegistry,
    Test_Async_File_Reader,
    Test_Clipboard_Text,
    Test_Command_Line,
    Test_Document_State,
    Test_File_Association,
    Test_File_Watcher,
    Test_Recent_File_Positions,
    Test_Files,
    Test_Html_Export,
    Test_Language_Server_Process,
    Test_Language_Server_State,
    Test_Link_Navigation,
    Test_Line_Navigation,
    Test_Link,
    Test_Lsp_Client_Thread,
    Test_Lsp_Diagnostics,
    Test_Lsp_Protocol,
    Test_Preferences,
    Test_Renderer,
    Test_Recent_Files;

function FormatProblemText(AFailure: TTestFailure; AShowExceptionClass: Boolean): string;
var
    MessageText: string;
    SeparatorPosition: SizeInt;
begin
    SeparatorPosition := Pos(': ', AFailure.AsString);
    if SeparatorPosition = 0 then
    begin
        Result := AFailure.AsString;
        Exit;
    end;

    MessageText := TrimLeft(Copy(AFailure.AsString, SeparatorPosition + 2, MaxInt));
    Result := Copy(AFailure.AsString, 1, SeparatorPosition - 1);
    if AShowExceptionClass then
        Result := Result + ' [' + AFailure.ExceptionClassName + ']';
    Result := Result + ': ' + MessageText;
end;

function ProblemLocation(AFailure: TTestFailure): string;
var
    FileName: string;
    LineNumberText: string;
    LinePosition: SizeInt;
    LowerLocationInfo: string;
    LocationInfo: string;
    OfPosition: SizeInt;
    RelativeOfPosition: SizeInt;
begin
    if AFailure.SourceUnitName <> '' then
    begin
        Result := AFailure.SourceUnitName;
        if AFailure.LineNumber > 0 then
            Result := Result + ':' + IntToStr(AFailure.LineNumber);
        Exit;
    end;

    if AFailure.LineNumber > 0 then
    begin
        Result := 'linha ' + IntToStr(AFailure.LineNumber);
        Exit;
    end;

    LocationInfo := Trim(AFailure.LocationInfo);
    LowerLocationInfo := LowerCase(LocationInfo);
    LinePosition := Pos('line ', LowerLocationInfo);
    if LinePosition > 0 then
    begin
        RelativeOfPosition := Pos(' of ', Copy(LowerLocationInfo, LinePosition + 5, MaxInt));
        if RelativeOfPosition > 0 then
        begin
            OfPosition := LinePosition + 5 + RelativeOfPosition - 1;
            LineNumberText := Trim(Copy(LocationInfo, LinePosition + 5, OfPosition - LinePosition - 5));
            FileName := Trim(Copy(LocationInfo, OfPosition + 4, MaxInt));
            if (FileName <> '') and (LineNumberText <> '') then
            begin
                Result := FileName + ':' + LineNumberText;
                Exit;
            end;
        end;
    end;

    if (LocationInfo = '')
        or (CompareText(LocationInfo, 'n/a') = 0)
        or (Pos('<no map file>', LowerCase(LocationInfo)) > 0)
        or (Copy(LocationInfo, 1, 1) = '$') then
        Result := ''
    else
        Result := LocationInfo;
end;

procedure WriteProblem(AFailure: TTestFailure; AShowExceptionClass: Boolean);
var
    Index: Integer;
    Lines: TStringList;
    Location: string;
begin
    Lines := TStringList.Create;
    try
        Lines.Text := AdjustLineBreaks(FormatProblemText(AFailure, AShowExceptionClass), tlbsLF);
        WriteLn('  - ', Lines[0]);
        for Index := 1 to Lines.Count - 1 do
            WriteLn('    ', Lines[Index]);

        Location := ProblemLocation(AFailure);
        if Location <> '' then
            WriteLn('    Em: ', Location);
    finally
        Lines.Free;
    end;
end;

procedure WriteProblems(const ATitle: string; AProblems: TFPList; AShowExceptionClass: Boolean);
var
    Failure: TTestFailure;
    Index: Integer;
begin
    if AProblems.Count = 0 then
        Exit;

    WriteLn;
    WriteLn(ATitle, ':');
    for Index := 0 to AProblems.Count - 1 do
    begin
        Failure := TTestFailure(AProblems[Index]);
        WriteProblem(Failure, AShowExceptionClass);
    end;
end;

procedure WriteSummary(ATestResult: TTestResult);
var
    PassedTests: Integer;
begin
    PassedTests :=
        ATestResult.RunTests
            - ATestResult.NumberOfFailures
            - ATestResult.NumberOfErrors
            - ATestResult.NumberOfIgnoredTests;

    WriteLn('Total: ', ATestResult.RunTests);
    WriteLn('Passaram: ', PassedTests);
    WriteLn('Falharam: ', ATestResult.NumberOfFailures);
    WriteLn('Erros: ', ATestResult.NumberOfErrors);
    WriteLn('Ignorados: ', ATestResult.NumberOfIgnoredTests);

    WriteProblems('Falhas', ATestResult.Failures, False);
    WriteProblems('Erros', ATestResult.Errors, True);
    WriteProblems('Ignorados', ATestResult.IgnoredTests, False);
end;

var
    TestResult: TTestResult;
    TestsPassed: Boolean;
begin
    TestResult := TTestResult.Create;
    try
        GetTestRegistry.Run(TestResult);
        WriteSummary(TestResult);
        TestsPassed := TestResult.WasSuccessful;
    finally
        TestResult.Free;
    end;

    if not TestsPassed then
        Halt(1);
end.
