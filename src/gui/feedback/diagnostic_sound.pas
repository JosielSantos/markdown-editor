unit Diagnostic_Sound;

{$MODE objfpc}
{$H+}

interface

uses
    Lsp_Diagnostics;

procedure PlayDiagnosticSound(Severity: TLspDiagnosticSeverity);

implementation

uses
    Classes,
    Windows;

const
    ErrorFrequency = 400;
    WarningFrequency = 800;
    SoundDurationMilliseconds = 120;

type
    TDiagnosticSoundThread = class(TThread)
    private
        Frequency: Cardinal;
    protected
        procedure Execute; override;
    public
        constructor Create(Severity: TLspDiagnosticSeverity);
    end;

constructor TDiagnosticSoundThread.Create(Severity: TLspDiagnosticSeverity);
begin
    inherited Create(True);
    FreeOnTerminate := True;
    if Severity = ldsError then
        Frequency := ErrorFrequency
    else
        Frequency := WarningFrequency;
end;

procedure TDiagnosticSoundThread.Execute;
begin
    Windows.Beep(Frequency, SoundDurationMilliseconds);
end;

procedure PlayDiagnosticSound(Severity: TLspDiagnosticSeverity);
var
    SoundThread: TDiagnosticSoundThread;
begin
    if Severity in [ldsNone, ldsInformation] then
        Exit;
    SoundThread := TDiagnosticSoundThread.Create(Severity);
    SoundThread.Start;
end;

end.
