unit Test_Async_File_Reader;

{$MODE objfpc}
{$H+}

interface

uses
    FpcUnit,
    TestRegistry;

type
    TAsyncFileReaderTests = class(TTestCase)
    published
        procedure CancelDiscardsResult;
        procedure LatestRequestWins;
        procedure ReadsChangedContent;
        procedure ReportsMissingFile;
        procedure ReportsReadError;
        procedure ReportsUnchangedContent;
    end;

implementation

uses
    Async_File_Reader,
    Classes,
    Files,
    SysUtils,
    Windows;

function WaitForResult(Reader: TAsyncFileReader; out ReadResult: TAsyncFileReadResult): Boolean;
var
    Deadline: QWord;
begin
    Deadline := GetTickCount64 + 3000;
    repeat
        Result := Reader.TryTakeResult(ReadResult);
        if not Result then
            Sleep(10);
    until Result or (GetTickCount64 >= Deadline);
end;

procedure TAsyncFileReaderTests.CancelDiscardsResult;
var
    FileName: string;
    ReadResult: TAsyncFileReadResult;
    Reader: TAsyncFileReader;
begin
    FileName := SysUtils.GetTempFileName(GetTempDir, 'mdr');
    Reader := TAsyncFileReader.Create;
    try
        WriteUtf8TextFile(FileName, 'conteúdo');
        Reader.Request(FileName, 'anterior');
        Reader.Cancel;
        Sleep(100);
        AssertFalse('Uma solicitação cancelada publicou resultado', Reader.TryTakeResult(ReadResult));
    finally
        Reader.Free;
        SysUtils.DeleteFile(FileName);
    end;
end;

procedure TAsyncFileReaderTests.LatestRequestWins;
var
    FirstFileName: string;
    LatestRequestId: QWord;
    ReadResult: TAsyncFileReadResult;
    Reader: TAsyncFileReader;
    SecondFileName: string;
begin
    FirstFileName := SysUtils.GetTempFileName(GetTempDir, 'mdr');
    SecondFileName := SysUtils.GetTempFileName(GetTempDir, 'mdr');
    Reader := TAsyncFileReader.Create;
    try
        WriteUtf8TextFile(FirstFileName, 'primeiro');
        WriteUtf8TextFile(SecondFileName, 'segundo');
        Reader.Request(FirstFileName, '');
        LatestRequestId := Reader.Request(SecondFileName, '');
        AssertTrue('O reader não publicou a solicitação mais recente', WaitForResult(Reader, ReadResult));
        AssertEquals(Int64(LatestRequestId), Int64(ReadResult.RequestId));
        AssertEquals(SecondFileName, ReadResult.FileName);
        AssertEquals('segundo', ReadResult.Content);
    finally
        Reader.Free;
        SysUtils.DeleteFile(FirstFileName);
        SysUtils.DeleteFile(SecondFileName);
    end;
end;

procedure TAsyncFileReaderTests.ReadsChangedContent;
var
    FileName: string;
    ReadResult: TAsyncFileReadResult;
    Reader: TAsyncFileReader;
begin
    FileName := SysUtils.GetTempFileName(GetTempDir, 'mdr');
    Reader := TAsyncFileReader.Create;
    try
        WriteUtf8TextFile(FileName, 'novo conteúdo');
        Reader.Request(FileName, 'conteúdo anterior');
        AssertTrue('O reader não publicou o resultado', WaitForResult(Reader, ReadResult));
        AssertEquals(Ord(afrsSuccess), Ord(ReadResult.Status));
        AssertTrue(ReadResult.Changed);
        AssertEquals('novo conteúdo', ReadResult.Content);
    finally
        Reader.Free;
        SysUtils.DeleteFile(FileName);
    end;
end;

procedure TAsyncFileReaderTests.ReportsMissingFile;
var
    FileName: string;
    ReadResult: TAsyncFileReadResult;
    Reader: TAsyncFileReader;
begin
    FileName := SysUtils.GetTempFileName(GetTempDir, 'mdr');
    SysUtils.DeleteFile(FileName);
    Reader := TAsyncFileReader.Create;
    try
        Reader.Request(FileName, '');
        AssertTrue('O reader não publicou o resultado', WaitForResult(Reader, ReadResult));
        AssertEquals(Ord(afrsMissing), Ord(ReadResult.Status));
    finally
        Reader.Free;
    end;
end;

procedure TAsyncFileReaderTests.ReportsReadError;
var
    ExclusiveStream: TFileStream;
    FileName: string;
    ReadResult: TAsyncFileReadResult;
    Reader: TAsyncFileReader;
begin
    FileName := SysUtils.GetTempFileName(GetTempDir, 'mdr');
    WriteUtf8TextFile(FileName, 'conteúdo bloqueado');
    ExclusiveStream := TFileStream.Create(FileName, fmOpenReadWrite or fmShareExclusive);
    Reader := TAsyncFileReader.Create;
    try
        Reader.Request(FileName, '');
        AssertTrue('O reader não publicou o erro', WaitForResult(Reader, ReadResult));
        AssertEquals(Ord(afrsError), Ord(ReadResult.Status));
    finally
        ExclusiveStream.Free;
        Reader.Free;
        SysUtils.DeleteFile(FileName);
    end;
end;

procedure TAsyncFileReaderTests.ReportsUnchangedContent;
var
    FileName: string;
    ReadResult: TAsyncFileReadResult;
    Reader: TAsyncFileReader;
begin
    FileName := SysUtils.GetTempFileName(GetTempDir, 'mdr');
    Reader := TAsyncFileReader.Create;
    try
        WriteUtf8TextFile(FileName, 'sem alteração');
        Reader.Request(FileName, 'sem alteração');
        AssertTrue('O reader não publicou o resultado', WaitForResult(Reader, ReadResult));
        AssertEquals(Ord(afrsSuccess), Ord(ReadResult.Status));
        AssertFalse(ReadResult.Changed);
    finally
        Reader.Free;
        SysUtils.DeleteFile(FileName);
    end;
end;

initialization
    RegisterTest(TAsyncFileReaderTests);

end.
