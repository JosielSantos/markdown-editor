unit Lsp_Client_Thread;

{$MODE objfpc}
{$H+}

interface

uses
    Classes,
    Lsp_Diagnostics,
    Lsp_Protocol,
    Process;

type
    TLspDiagnosticsEvent =
        procedure(Sender: TObject; const DocumentUri: string; const Diagnostics: TLspDiagnosticArray) of object;
    TLspErrorEvent = procedure(Sender: TObject; const ErrorMessage: string) of object;

    TLspClientThread = class(TThread)
    private
        CurrentDocumentText: string;
        CurrentDocumentUri: string;
        CurrentDocumentVersion: Integer;
        DiagnosticsDeliveryQueued: Boolean;
        ErrorDeliveryQueued: Boolean;
        Initialized: Boolean;
        Lock: TRTLCriticalSection;
        MarksmanFileName: string;
        OnDiagnostics: TLspDiagnosticsEvent;
        OnError: TLspErrorEvent;
        OutgoingMessages: TStringList;
        PendingDiagnostics: TLspDiagnosticArray;
        PendingDiagnosticsUri: string;
        PendingErrorMessage: string;
        MessageBuffer: TLspMessageBuffer;
        ServerProcess: TProcess;
        procedure DeliverDiagnostics;
        procedure DeliverError;
        procedure DrainErrorOutput;
        procedure HandleIncomingMessage(const JsonText: string);
        procedure MarkInitialized;
        procedure QueueJsonLocked(const JsonText: string);
        procedure QueueDiagnostics(const DocumentUri: string; const Diagnostics: TLspDiagnosticArray);
        procedure QueueError(const ErrorMessage: string);
        procedure QueueJson(const JsonText: string);
        procedure ReadServerOutput;
        function TakeOutgoingMessage(out Message: RawByteString): Boolean;
        procedure WriteOutgoingMessages;
    protected
        procedure Execute; override;
    public
        constructor Create(
            const TheMarksmanFileName: string;
            TheDiagnosticsHandler: TLspDiagnosticsEvent;
            TheErrorHandler: TLspErrorEvent
        );
        destructor Destroy; override;
        procedure ChangeDocument(const Text: string);
        procedure CloseDocument;
        procedure OpenDocument(const DocumentUri, Text: string);
        procedure SaveDocument;
    end;

implementation

uses
    Math,
    SysUtils;

const
    PipeReadSize = 8192;
    WorkerPauseMilliseconds = 10;

constructor TLspClientThread.Create(
    const TheMarksmanFileName: string;
    TheDiagnosticsHandler: TLspDiagnosticsEvent;
    TheErrorHandler: TLspErrorEvent
);
begin
    inherited Create(True);
    MarksmanFileName := TheMarksmanFileName;
    OnDiagnostics := TheDiagnosticsHandler;
    OnError := TheErrorHandler;
    OutgoingMessages := TStringList.Create;
    InitCriticalSection(Lock);
    Start;
end;

destructor TLspClientThread.Destroy;
begin
    Terminate;
    inherited Destroy;
    DoneCriticalSection(Lock);
    OutgoingMessages.Free;
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
begin
    OutgoingMessages.Add(string(FrameLspMessage(JsonText)));
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
end;

procedure TLspClientThread.HandleIncomingMessage(const JsonText: string);
var
    Diagnostics: TLspDiagnosticArray;
    DocumentUri: string;
begin
    if IsInitializeResponse(JsonText) then
        MarkInitialized;
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
        while MessageBuffer.TryReadMessage(JsonText) do
            HandleIncomingMessage(JsonText);
        AvailableBytes := ServerProcess.Output.NumBytesAvailable;
    end;
end;

procedure TLspClientThread.DrainErrorOutput;
var
    AvailableBytes: Integer;
    Chunk: RawByteString;
begin
    AvailableBytes := ServerProcess.Stderr.NumBytesAvailable;
    while AvailableBytes > 0 do
    begin
        SetLength(Chunk, Min(AvailableBytes, PipeReadSize));
        ServerProcess.Stderr.Read(Chunk[1], Length(Chunk));
        AvailableBytes := ServerProcess.Stderr.NumBytesAvailable;
    end;
end;

procedure TLspClientThread.Execute;
begin
    ServerProcess := TProcess.Create(nil);
    MessageBuffer := TLspMessageBuffer.Create;
    try
        ServerProcess.Executable := MarksmanFileName;
        ServerProcess.Parameters.Add('server');
        ServerProcess.Options := [poUsePipes, poNoConsole];
        ServerProcess.CurrentDirectory := ExtractFileDir(MarksmanFileName);
        ServerProcess.Execute;
        QueueJson(BuildInitializeRequest(GetProcessID, ''));
        while not Terminated and ServerProcess.Running do
        begin
            WriteOutgoingMessages;
            ReadServerOutput;
            DrainErrorOutput;
            Sleep(WorkerPauseMilliseconds);
        end;
        if not Terminated then
            QueueError('O servidor Marksman foi encerrado inesperadamente.');
    except
        on Error: Exception do
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
