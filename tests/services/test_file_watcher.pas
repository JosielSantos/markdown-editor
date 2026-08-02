unit Test_File_Watcher;

{$MODE objfpc}
{$H+}

interface

uses
    FpcUnit,
    TestRegistry;

type
    TFileWatcherTests = class(TTestCase)
    published
        procedure DetectsDirectoryChange;
        procedure DetectsFileRemoval;
    end;

implementation

uses
    File_Watcher,
    Files,
    SysUtils,
    Windows;

procedure TFileWatcherTests.DetectsDirectoryChange;
var
    ChangeDetected: Boolean;
    Deadline: QWord;
    FileName: string;
    Watcher: TFileWatcher;
begin
    FileName := SysUtils.GetTempFileName(GetTempDir, 'mdw');
    Watcher := TFileWatcher.Create;
    try
        Watcher.Watch(FileName);
        WriteUtf8TextFile(FileName, 'conteúdo alterado');
        Deadline := GetTickCount64 + 3000;
        repeat
            ChangeDetected := Watcher.ConsumeChange;
            if not ChangeDetected then
                Sleep(20);
        until ChangeDetected or (GetTickCount64 >= Deadline);
        AssertTrue('O watcher não detectou a alteração no diretório', ChangeDetected);
    finally
        Watcher.Free;
        SysUtils.DeleteFile(FileName);
    end;
end;

procedure TFileWatcherTests.DetectsFileRemoval;
var
    ChangeDetected: Boolean;
    Deadline: QWord;
    FileName: string;
    Watcher: TFileWatcher;
begin
    FileName := SysUtils.GetTempFileName(GetTempDir, 'mdw');
    Watcher := TFileWatcher.Create;
    try
        WriteUtf8TextFile(FileName, 'conteúdo inicial');
        Watcher.Watch(FileName);
        if not SysUtils.DeleteFile(FileName) then
            Fail('Não foi possível remover o arquivo temporário: ' + SysErrorMessage(Windows.GetLastError));
        Deadline := GetTickCount64 + 3000;
        repeat
            ChangeDetected := Watcher.ConsumeChange;
            if not ChangeDetected then
                Sleep(20);
        until ChangeDetected or (GetTickCount64 >= Deadline);
        AssertTrue('O watcher não detectou a remoção no diretório', ChangeDetected);
    finally
        Watcher.Free;
        if FileExists(FileName) then
            SysUtils.DeleteFile(FileName);
    end;
end;

initialization
    RegisterTest(TFileWatcherTests);

end.
