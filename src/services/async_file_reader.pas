unit Async_File_Reader;

{$MODE objfpc}
{$H+}

interface

uses
    Classes,
    Document_State,
    Windows;

type
    TAsyncFileReadStatus = (afrsSuccess, afrsMissing, afrsError);

    TAsyncFileReadResult = record
        Changed: Boolean;
        Content: string;
        Encoding: TDocumentEncoding;
        FileName: string;
        RequestId: QWord;
        Status: TAsyncFileReadStatus;
    end;

    TAsyncFileReadRequest = record
        FileName: string;
        RequestId: QWord;
        SavedContent: string;
    end;

    TAsyncFileReader = class(TThread)
    private
        LatestRequestId: QWord;
        LatestResult: TAsyncFileReadResult;
        Lock: TRTLCriticalSection;
        PendingRequest: TAsyncFileReadRequest;
        RequestPending: Boolean;
        ResultReady: Boolean;
        WakeEvent: THandle;
        function ReadRequest(const Request: TAsyncFileReadRequest): TAsyncFileReadResult;
        function TakePendingRequest(out Request: TAsyncFileReadRequest): Boolean;
        procedure PublishResult(const ReadResult: TAsyncFileReadResult);
    protected
        procedure Execute; override;
    public
        constructor Create;
        destructor Destroy; override;
        procedure Cancel;
        function Request(const FileName, SavedContent: string): QWord;
        function TryTakeResult(out ReadResult: TAsyncFileReadResult): Boolean;
    end;

implementation

uses
    Files,
    SysUtils;

constructor TAsyncFileReader.Create;
begin
    inherited Create(True);
    FreeOnTerminate := False;
    InitCriticalSection(Lock);
    WakeEvent := CreateEvent(nil, False, False, nil);
    if WakeEvent = 0 then
        RaiseLastOSError;
    Start;
end;

destructor TAsyncFileReader.Destroy;
begin
    Terminate;
    if WakeEvent <> 0 then
    begin
        SetEvent(WakeEvent);
        WaitFor;
        CloseHandle(WakeEvent);
    end;
    DoneCriticalSection(Lock);
    inherited Destroy;
end;

procedure TAsyncFileReader.Cancel;
begin
    EnterCriticalSection(Lock);
    try
        Inc(LatestRequestId);
        PendingRequest.FileName := '';
        PendingRequest.SavedContent := '';
        RequestPending := False;
        LatestResult.Content := '';
        LatestResult.FileName := '';
        ResultReady := False;
    finally
        LeaveCriticalSection(Lock);
    end;
end;

procedure TAsyncFileReader.Execute;
var
    ReadRequestData: TAsyncFileReadRequest;
    ReadResult: TAsyncFileReadResult;
begin
    while not Terminated do
    begin
        if WaitForSingleObject(WakeEvent, INFINITE) <> WAIT_OBJECT_0 then
            Exit;
        if Terminated then
            Exit;
        while TakePendingRequest(ReadRequestData) do
        begin
            ReadResult := ReadRequest(ReadRequestData);
            PublishResult(ReadResult);
            if Terminated then
                Exit;
        end;
    end;
end;

procedure TAsyncFileReader.PublishResult(const ReadResult: TAsyncFileReadResult);
begin
    EnterCriticalSection(Lock);
    try
        if not Terminated and (ReadResult.RequestId = LatestRequestId) then
        begin
            LatestResult := ReadResult;
            ResultReady := True;
        end;
    finally
        LeaveCriticalSection(Lock);
    end;
end;

function TAsyncFileReader.ReadRequest(const Request: TAsyncFileReadRequest): TAsyncFileReadResult;
begin
    Result.Changed := False;
    Result.Content := '';
    Result.Encoding.Name := '';
    Result.Encoding.HasUtf8Bom := False;
    Result.FileName := Request.FileName;
    Result.RequestId := Request.RequestId;
    if not FileExists(Request.FileName) then
    begin
        Result.Status := afrsMissing;
        Exit;
    end;
    try
        Result.Content := AdjustLineBreaks(ReadTextFile(Request.FileName, Result.Encoding), tlbsCRLF);
        Result.Changed := Result.Content <> Request.SavedContent;
        Result.Status := afrsSuccess;
    except
        Result.Content := '';
        Result.Status := afrsError;
    end;
end;

function TAsyncFileReader.Request(const FileName, SavedContent: string): QWord;
begin
    EnterCriticalSection(Lock);
    try
        Inc(LatestRequestId);
        Result := LatestRequestId;
        PendingRequest.FileName := FileName;
        PendingRequest.RequestId := Result;
        PendingRequest.SavedContent := SavedContent;
        RequestPending := True;
        LatestResult.Content := '';
        LatestResult.FileName := '';
        ResultReady := False;
    finally
        LeaveCriticalSection(Lock);
    end;
    SetEvent(WakeEvent);
end;

function TAsyncFileReader.TakePendingRequest(out Request: TAsyncFileReadRequest): Boolean;
begin
    EnterCriticalSection(Lock);
    try
        Result := RequestPending;
        if Result then
        begin
            Request := PendingRequest;
            PendingRequest.FileName := '';
            PendingRequest.SavedContent := '';
            RequestPending := False;
        end;
    finally
        LeaveCriticalSection(Lock);
    end;
end;

function TAsyncFileReader.TryTakeResult(out ReadResult: TAsyncFileReadResult): Boolean;
begin
    EnterCriticalSection(Lock);
    try
        Result := ResultReady;
        if Result then
        begin
            ReadResult := LatestResult;
            LatestResult.Content := '';
            LatestResult.FileName := '';
            ResultReady := False;
        end;
    finally
        LeaveCriticalSection(Lock);
    end;
end;

end.
