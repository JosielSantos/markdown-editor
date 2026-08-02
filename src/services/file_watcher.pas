unit File_Watcher;

{$MODE objfpc}
{$H+}

interface

uses
    Classes,
    Windows;

type
    TDirectoryChangeThread = class(TThread)
    private
        ChangeHandle: THandle;
        ChangedFlag: PLongInt;
        StopEvent: THandle;
    protected
        procedure Execute; override;
    public
        constructor Create(const DirectoryName: string; TheChangedFlag: PLongInt);
        destructor Destroy; override;
    end;

    TFileWatcher = class
    private
        Changed: LongInt;
        Thread: TDirectoryChangeThread;
    public
        destructor Destroy; override;
        function ConsumeChange: Boolean;
        procedure Stop;
        procedure Watch(const FileName: string);
    end;

implementation

uses
    SysUtils;

const
    WatchFilter = FILE_NOTIFY_CHANGE_FILE_NAME or FILE_NOTIFY_CHANGE_SIZE or FILE_NOTIFY_CHANGE_LAST_WRITE;

constructor TDirectoryChangeThread.Create(const DirectoryName: string; TheChangedFlag: PLongInt);
begin
    inherited Create(True);
    FreeOnTerminate := False;
    ChangedFlag := TheChangedFlag;
    ChangeHandle := FindFirstChangeNotificationW(PWideChar(UTF8Decode(DirectoryName)), False, WatchFilter);
    if ChangeHandle = INVALID_HANDLE_VALUE then
        RaiseLastOSError;
    StopEvent := CreateEvent(nil, True, False, nil);
    if StopEvent = 0 then
        RaiseLastOSError;
    Start;
end;

destructor TDirectoryChangeThread.Destroy;
begin
    if StopEvent <> 0 then
    begin
        SetEvent(StopEvent);
        WaitFor;
        CloseHandle(StopEvent);
    end;
    if (ChangeHandle <> 0) and (ChangeHandle <> INVALID_HANDLE_VALUE) then
        FindCloseChangeNotification(ChangeHandle);
    inherited Destroy;
end;

procedure TDirectoryChangeThread.Execute;
var
    Handles: array[0..1] of THandle;
    WaitResult: DWORD;
begin
    Handles[0] := ChangeHandle;
    Handles[1] := StopEvent;
    while not Terminated do
    begin
        WaitResult := WaitForMultipleObjects(Length(Handles), @Handles, False, INFINITE);
        if WaitResult = WAIT_OBJECT_0 + 1 then
            Exit;
        if WaitResult <> WAIT_OBJECT_0 then
            Exit;
        InterlockedExchange(ChangedFlag^, 1);
        if not FindNextChangeNotification(ChangeHandle) then
            Exit;
    end;
end;

destructor TFileWatcher.Destroy;
begin
    Stop;
    inherited Destroy;
end;

function TFileWatcher.ConsumeChange: Boolean;
begin
    Result := InterlockedExchange(Changed, 0) <> 0;
end;

procedure TFileWatcher.Stop;
begin
    FreeAndNil(Thread);
    InterlockedExchange(Changed, 0);
end;

procedure TFileWatcher.Watch(const FileName: string);
var
    DirectoryName: string;
begin
    Stop;
    if FileName = '' then
        Exit;
    DirectoryName := ExtractFileDir(ExpandFileName(FileName));
    if not DirectoryExists(DirectoryName) then
        Exit;
    Thread := TDirectoryChangeThread.Create(DirectoryName, @Changed);
end;

end.
