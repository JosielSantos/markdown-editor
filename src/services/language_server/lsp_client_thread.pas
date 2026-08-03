unit Lsp_Client_Thread;

{$MODE objfpc}
{$H+}

interface

uses
    Classes,
    Lsp_Diagnostics,
    Lsp_Protocol,
    Process,
    Windows;

type
    TLspDiagnosticsEvent =
        procedure(Sender: TObject; const DocumentUri: string; const Diagnostics: TLspDiagnosticArray) of object;
    TLspErrorEvent = procedure(Sender: TObject; const ErrorMessage: string) of object;
    TLspOutgoingMessageTransform = function(const JsonText: string): string of object;

    TLspClientThread = class(TThread)
    private
        CurrentDocumentText: string;
        CurrentDocumentUri: string;
        CurrentDocumentVersion: Integer;
        DiagnosticsDeliveryQueued: Boolean;
        ErrorOutput: RawByteString;
        ErrorOutputTruncated: Boolean;
        ErrorDeliveryQueued: Boolean;
        ExitNotificationQueued: Boolean;
        Initialized: Boolean;
        Lock: TRTLCriticalSection;
        ServerArguments: string;
        ServerExecutableFileName: string;
        OnDiagnostics: TLspDiagnosticsEvent;
        OnError: TLspErrorEvent;
        OutgoingMessageTransform: TLspOutgoingMessageTransform;
        OnReady: TNotifyEvent;
        OutgoingMessages: TStringList;
        PendingDiagnostics: TLspDiagnosticArray;
        PendingDiagnosticsUri: string;
        PendingErrorMessage: string;
        ShutdownRequested: Boolean;
        ShutdownRequestSent: Boolean;
        WakeEvent: THandle;
        MessageBuffer: TLspMessageBuffer;
        ServerProcess: TProcess;
        procedure DeliverDiagnostics;
        procedure DeliverError;
        procedure DeliverReady;
        procedure CaptureErrorOutput;
        procedure BeginGracefulShutdown;
        procedure HandleIncomingMessage(const JsonText: string);
        procedure MarkInitialized;
        procedure QueueJsonLocked(const JsonText: string);
        procedure QueueDiagnostics(const DocumentUri: string; const Diagnostics: TLspDiagnosticArray);
        procedure QueueError(const ErrorMessage: string);
        procedure QueueJson(const JsonText: string);
        procedure ReadServerOutput;
        function RequestGracefulShutdown: Boolean;
        function GracefulShutdownRequested: Boolean;
        function TakeOutgoingMessage(out Message: RawByteString): Boolean;
        procedure WriteOutgoingMessages;
    protected
        procedure Execute; override;
    public
        constructor Create(
            const TheServerExecutableFileName, TheServerArguments: string;
            TheDiagnosticsHandler: TLspDiagnosticsEvent;
            TheErrorHandler: TLspErrorEvent;
            TheReadyHandler: TNotifyEvent = nil;
            TheOutgoingMessageTransform: TLspOutgoingMessageTransform = nil
        );
        destructor Destroy; override;
        procedure ChangeDocument(const Text: string);
        procedure CloseDocument;
        procedure OpenDocument(const DocumentUri, Text: string);
        procedure SaveDocument;
    end;

implementation

uses
    Language_Server_Process,
    Math,
    SysUtils;

const
    PipeReadSize = 8192;
    PipePollingMilliseconds = 50;
    GracefulShutdownTimeoutMilliseconds = 1000;

constructor TLspClientThread.Create(
    const TheServerExecutableFileName, TheServerArguments: string;
    TheDiagnosticsHandler: TLspDiagnosticsEvent;
    TheErrorHandler: TLspErrorEvent;
    TheReadyHandler: TNotifyEvent;
    TheOutgoingMessageTransform: TLspOutgoingMessageTransform
);
begin
    inherited Create(True);
    ServerExecutableFileName := TheServerExecutableFileName;
    ServerArguments := TheServerArguments;
    OnDiagnostics := TheDiagnosticsHandler;
    OnError := TheErrorHandler;
    OnReady := TheReadyHandler;
    OutgoingMessageTransform := TheOutgoingMessageTransform;
    OutgoingMessages := TStringList.Create;
    InitCriticalSection(Lock);
    WakeEvent := CreateEvent(nil, False, False, nil);
    if WakeEvent = 0 then
        RaiseLastOSError;
    Start;
end;

destructor TLspClientThread.Destroy;
begin
    if not Finished and RequestGracefulShutdown then
        WaitForSingleObject(Handle, GracefulShutdownTimeoutMilliseconds);
    if not Finished then
    begin
        Terminate;
        if WakeEvent <> 0 then
            SetEvent(WakeEvent);
    end;
    inherited Destroy;
    if WakeEvent <> 0 then
        CloseHandle(WakeEvent);
    DoneCriticalSection(Lock);
    OutgoingMessages.Free;
end;

function TLspClientThread.RequestGracefulShutdown: Boolean;
begin
    EnterCriticalSection(Lock);
    try
        Result := Initialized;
        if Result then
            ShutdownRequested := True;
    finally
        LeaveCriticalSection(Lock);
    end;
    if Result and (WakeEvent <> 0) then
        SetEvent(WakeEvent);
end;

function TLspClientThread.GracefulShutdownRequested: Boolean;
begin
    EnterCriticalSection(Lock);
    try
        Result := ShutdownRequested;
    finally
        LeaveCriticalSection(Lock);
    end;
end;

procedure TLspClientThread.BeginGracefulShutdown;
begin
    EnterCriticalSection(Lock);
    try
        if ShutdownRequested and not ShutdownRequestSent then
        begin
            ShutdownRequestSent := True;
            QueueJsonLocked(BuildShutdownRequest);
        end;
    finally
        LeaveCriticalSection(Lock);
    end;
end;

procedure TLspClientThread.QueueJson(const JsonText: string);
begin
    EnterCriticalSection(Lock);
    try
        QueueJsonLocked(JsonText);
    finally
        LeaveCriticalSection(Lock);
    end;
end;

procedure TLspClientThread.QueueJsonLocked(const JsonText: string);
var
    OutgoingJsonText: string;
begin
    OutgoingJsonText := JsonText;
    if Assigned(OutgoingMessageTransform) then
        OutgoingJsonText := OutgoingMessageTransform(OutgoingJsonText);
    OutgoingMessages.Add(string(FrameLspMessage(OutgoingJsonText)));
    if WakeEvent <> 0 then
        SetEvent(WakeEvent);
end;

function TLspClientThread.TakeOutgoingMessage(out Message: RawByteString): Boolean;
begin
    EnterCriticalSection(Lock);
    try
        Result := OutgoingMessages.Count > 0;
        if Result then
        begin
            Message := RawByteString(OutgoingMessages[0]);
            OutgoingMessages.Delete(0);
        end;
    finally
        LeaveCriticalSection(Lock);
    end;
end;

procedure TLspClientThread.WriteOutgoingMessages;
var
    Message: RawByteString;
begin
    while TakeOutgoingMessage(Message) do
        if Length(Message) > 0 then
            ServerProcess.Input.WriteBuffer(Message[1], Length(Message));
end;

procedure TLspClientThread.QueueDiagnostics(const DocumentUri: string; const Diagnostics: TLspDiagnosticArray);
var
    ShouldQueue: Boolean;
begin
    EnterCriticalSection(Lock);
    try
        PendingDiagnosticsUri := DocumentUri;
        PendingDiagnostics := Copy(Diagnostics, 0, Length(Diagnostics));
        ShouldQueue := not DiagnosticsDeliveryQueued;
        DiagnosticsDeliveryQueued := True;
    finally
        LeaveCriticalSection(Lock);
    end;
    if ShouldQueue then
        TThread.Queue(Self, @DeliverDiagnostics);
end;

procedure TLspClientThread.DeliverDiagnostics;
var
    Diagnostics: TLspDiagnosticArray;
    DocumentUri: string;
begin
    EnterCriticalSection(Lock);
    try
        DocumentUri := PendingDiagnosticsUri;
        Diagnostics := Copy(PendingDiagnostics, 0, Length(PendingDiagnostics));
        DiagnosticsDeliveryQueued := False;
    finally
        LeaveCriticalSection(Lock);
    end;
    if Assigned(OnDiagnostics) then
        OnDiagnostics(Self, DocumentUri, Diagnostics);
end;

procedure TLspClientThread.QueueError(const ErrorMessage: string);
var
    ShouldQueue: Boolean;
begin
    EnterCriticalSection(Lock);
    try
        PendingErrorMessage := ErrorMessage;
        ShouldQueue := not ErrorDeliveryQueued;
        ErrorDeliveryQueued := True;
    finally
        LeaveCriticalSection(Lock);
    end;
    if ShouldQueue then
        TThread.Queue(Self, @DeliverError);
end;

procedure TLspClientThread.DeliverError;
var
    ErrorMessage: string;
begin
    EnterCriticalSection(Lock);
    try
        ErrorMessage := PendingErrorMessage;
        ErrorDeliveryQueued := False;
    finally
        LeaveCriticalSection(Lock);
    end;
    if Assigned(OnError) then
        OnError(Self, ErrorMessage);
end;

procedure TLspClientThread.DeliverReady;
begin
    if Assigned(OnReady) then
        OnReady(Self);
end;

procedure TLspClientThread.MarkInitialized;
begin
    EnterCriticalSection(Lock);
    try
        QueueJsonLocked(BuildInitializedNotification);
        if CurrentDocumentUri <> '' then
            QueueJsonLocked(BuildDidOpenNotification(CurrentDocumentUri, CurrentDocumentText, CurrentDocumentVersion));
        Initialized := True;
    finally
        LeaveCriticalSection(Lock);
    end;
    TThread.Queue(Self, @DeliverReady);
end;

procedure TLspClientThread.HandleIncomingMessage(const JsonText: string);
var
    Diagnostics: TLspDiagnosticArray;
    DocumentUri: string;
    InitializationError: string;
    InitializationStatus: TLspInitializeResponseStatus;
begin
    if ShutdownRequestSent then
    begin
        if not ExitNotificationQueued and IsShutdownResponse(JsonText) then
        begin
            ExitNotificationQueued := True;
            QueueJson(BuildExitNotification);
        end;
        Exit;
    end;
    if not Initialized then
    begin
        InitializationStatus := ParseInitializeResponse(JsonText, InitializationError);
        case InitializationStatus of
            lirsSuccess: MarkInitialized;
            lirsError:
            begin
                QueueError(InitializationError);
                Terminate;
                Exit;
            end;
        end;
    end;
    if ParsePublishDiagnostics(JsonText, DocumentUri, Diagnostics) then
        QueueDiagnostics(DocumentUri, Diagnostics);
end;

procedure TLspClientThread.ReadServerOutput;
var
    AvailableBytes: Integer;
    Chunk: RawByteString;
    JsonText: string;
    ReadCount: LongInt;
begin
    AvailableBytes := ServerProcess.Output.NumBytesAvailable;
    while AvailableBytes > 0 do
    begin
        SetLength(Chunk, Min(AvailableBytes, PipeReadSize));
        ReadCount := ServerProcess.Output.Read(Chunk[1], Length(Chunk));
        if ReadCount <= 0 then
            Exit;
        SetLength(Chunk, ReadCount);
        MessageBuffer.Append(Chunk);
        while not Terminated and MessageBuffer.TryReadMessage(JsonText) do
            HandleIncomingMessage(JsonText);
        AvailableBytes := ServerProcess.Output.NumBytesAvailable;
    end;
end;

procedure TLspClientThread.CaptureErrorOutput;
var
    AvailableBytes: Integer;
    Chunk: RawByteString;
    ReadCount: LongInt;
begin
    AvailableBytes := ServerProcess.Stderr.NumBytesAvailable;
    while AvailableBytes > 0 do
    begin
        SetLength(Chunk, Min(AvailableBytes, PipeReadSize));
        ReadCount := ServerProcess.Stderr.Read(Chunk[1], Length(Chunk));
        if ReadCount <= 0 then
            Exit;
        SetLength(Chunk, ReadCount);
        AppendLanguageServerErrorOutput(ErrorOutput, Chunk, ErrorOutputTruncated);
        AvailableBytes := ServerProcess.Stderr.NumBytesAvailable;
    end;
end;

procedure TLspClientThread.Execute;
var
    Handles: array[0..1] of THandle;
    WaitResult: DWORD;
begin
    ServerProcess := TProcess.Create(nil);
    MessageBuffer := TLspMessageBuffer.Create;
    try
        ConfigureLanguageServerProcess(ServerProcess, ServerExecutableFileName, ServerArguments);
        ServerProcess.Execute;
        Handles[0] := WakeEvent;
        Handles[1] := ServerProcess.ProcessHandle;
        QueueJson(BuildInitializeRequest(GetProcessID, ''));
        while not Terminated do
        begin
            BeginGracefulShutdown;
            WriteOutgoingMessages;
            ReadServerOutput;
            CaptureErrorOutput;
            if Terminated then
                Break;
            WaitResult := WaitForMultipleObjects(Length(Handles), @Handles[0], False, PipePollingMilliseconds);
            case WaitResult of
                WAIT_OBJECT_0: Continue;
                WAIT_OBJECT_0 + 1: Break;
                WAIT_TIMEOUT: Continue;
                WAIT_FAILED: RaiseLastOSError;
            else
                raise Exception.CreateFmt('Falha inesperada ao aguardar o servidor de linguagem (%d).', [WaitResult]);
            end;
        end;
        if not Terminated and not GracefulShutdownRequested then
        begin
            ReadServerOutput;
            CaptureErrorOutput;
            QueueError(
                BuildLanguageServerProcessExitMessage(ServerProcess.ExitStatus, ErrorOutput, ErrorOutputTruncated)
            );
        end;
    except
        on Error: Exception do
            if not GracefulShutdownRequested then
                QueueError(Error.Message);
    end;
    if ServerProcess.Running then
        ServerProcess.Terminate(0);
    MessageBuffer.Free;
    ServerProcess.Free;
    MessageBuffer := nil;
    ServerProcess := nil;
end;

procedure TLspClientThread.OpenDocument(const DocumentUri, Text: string);
var
    PreviousUri: string;
    Ready: Boolean;
begin
    EnterCriticalSection(Lock);
    try
        PreviousUri := CurrentDocumentUri;
        CurrentDocumentUri := DocumentUri;
        CurrentDocumentText := Text;
        CurrentDocumentVersion := 1;
        Ready := Initialized;
    finally
        LeaveCriticalSection(Lock);
    end;
    if Ready and (PreviousUri <> '') and (PreviousUri <> DocumentUri) then
        QueueJson(BuildDidCloseNotification(PreviousUri));
    if Ready then
        QueueJson(BuildDidOpenNotification(DocumentUri, Text, 1));
end;

procedure TLspClientThread.ChangeDocument(const Text: string);
var
    DocumentUri: string;
    DocumentVersion: Integer;
    Ready: Boolean;
begin
    EnterCriticalSection(Lock);
    try
        CurrentDocumentText := Text;
        Inc(CurrentDocumentVersion);
        DocumentUri := CurrentDocumentUri;
        DocumentVersion := CurrentDocumentVersion;
        Ready := Initialized and (DocumentUri <> '');
    finally
        LeaveCriticalSection(Lock);
    end;
    if Ready then
        QueueJson(BuildDidChangeNotification(DocumentUri, Text, DocumentVersion));
end;

procedure TLspClientThread.SaveDocument;
var
    DocumentUri: string;
    Ready: Boolean;
begin
    EnterCriticalSection(Lock);
    try
        DocumentUri := CurrentDocumentUri;
        Ready := Initialized and (DocumentUri <> '');
    finally
        LeaveCriticalSection(Lock);
    end;
    if Ready then
        QueueJson(BuildDidSaveNotification(DocumentUri));
end;

procedure TLspClientThread.CloseDocument;
var
    DocumentUri: string;
    Ready: Boolean;
begin
    EnterCriticalSection(Lock);
    try
        DocumentUri := CurrentDocumentUri;
        CurrentDocumentUri := '';
        CurrentDocumentText := '';
        Ready := Initialized and (DocumentUri <> '');
    finally
        LeaveCriticalSection(Lock);
    end;
    if Ready then
        QueueJson(BuildDidCloseNotification(DocumentUri));
end;

end.
