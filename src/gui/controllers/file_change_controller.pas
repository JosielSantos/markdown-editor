unit File_Change_Controller;

{$MODE objfpc}
{$H+}

interface

uses
    Classes,
    ExtCtrls,
    File_Watcher;

type
    TFileChangeController = class
    private
        ChangeDueAt: QWord;
        ChangeHandler: TNotifyEvent;
        CheckPending: Boolean;
        Watching: Boolean;
        Timer: TTimer;
        Watcher: TFileWatcher;
        procedure TimerTick(Sender: TObject);
    public
        constructor Create(TheOwner: TComponent; TheChangeHandler: TNotifyEvent);
        destructor Destroy; override;
        procedure ScheduleCheck;
        procedure Stop;
        procedure Watch(const FileName: string);
    end;

implementation

uses
    SysUtils;

const
    ChangeDebounceMilliseconds = 350;
    ChangePollingMilliseconds = 100;

constructor TFileChangeController.Create(TheOwner: TComponent; TheChangeHandler: TNotifyEvent);
begin
    ChangeHandler := TheChangeHandler;
    Watcher := TFileWatcher.Create;
    Timer := TTimer.Create(TheOwner);
    Timer.Enabled := False;
    Timer.Interval := ChangePollingMilliseconds;
    Timer.OnTimer := @TimerTick;
end;

destructor TFileChangeController.Destroy;
begin
    Timer.Free;
    Watcher.Free;
    inherited Destroy;
end;

procedure TFileChangeController.ScheduleCheck;
begin
    Timer.Enabled := True;
    ChangeDueAt := GetTickCount64 + ChangeDebounceMilliseconds;
    CheckPending := True;
end;

procedure TFileChangeController.Stop;
begin
    Watching := False;
    Timer.Enabled := False;
    CheckPending := False;
    Watcher.Stop;
end;

procedure TFileChangeController.TimerTick(Sender: TObject);
begin
    if Watcher.ConsumeChange then
        ScheduleCheck;
    if not CheckPending or (GetTickCount64 < ChangeDueAt) then
        Exit;
    CheckPending := False;
    if Assigned(ChangeHandler) then
        ChangeHandler(Self);
    if not Watching and not CheckPending then
        Timer.Enabled := False;
end;

procedure TFileChangeController.Watch(const FileName: string);
begin
    CheckPending := False;
    try
        Watcher.Watch(FileName);
        Watching := FileName <> '';
        Timer.Enabled := Watching;
    except
        Timer.Enabled := False;
        Watching := False;
        Watcher.Stop;
    end;
end;

end.
