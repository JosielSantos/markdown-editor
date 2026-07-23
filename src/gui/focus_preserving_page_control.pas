unit Focus_Preserving_Page_Control;

{$MODE objfpc}
{$H+}

interface

uses
    ComCtrls,
    Controls;

type
    TFocusPreservingPageControl = class(TPageControl)
    private
        RestoreQueued: Boolean;
        SuspendedTabStops: array of TWinControl;
        procedure RestoreTabStops(Data: PtrInt);
        procedure SuspendTabStops(ParentControl: TWinControl);
    public
        function CanChangePageIndex: Boolean; override;
        destructor Destroy; override;
    end;

implementation

uses
    Forms;

destructor TFocusPreservingPageControl.Destroy;
begin
    Application.RemoveAsyncCalls(Self);
    RestoreTabStops(0);
    inherited Destroy;
end;

function TFocusPreservingPageControl.CanChangePageIndex: Boolean;
begin
    Result := inherited CanChangePageIndex;
    if not Result then
        Exit;
    if not RestoreQueued then
    begin
        RestoreQueued := True;
        SuspendTabStops(Self);
        Application.QueueAsyncCall(@RestoreTabStops, 0);
    end;
    if CanFocus then
        SetFocus;
end;

procedure TFocusPreservingPageControl.RestoreTabStops(Data: PtrInt);
var
    ControlIndex: Integer;
begin
    for ControlIndex := 0 to High(SuspendedTabStops) do
        SuspendedTabStops[ControlIndex].TabStop := True;
    SetLength(SuspendedTabStops, 0);
    RestoreQueued := False;
end;

procedure TFocusPreservingPageControl.SuspendTabStops(ParentControl: TWinControl);
var
    ChildControl: TControl;
    ControlIndex: Integer;
begin
    for ControlIndex := 0 to ParentControl.ControlCount - 1 do
    begin
        ChildControl := ParentControl.Controls[ControlIndex];
        if not (ChildControl is TWinControl) then
            Continue;
        if TWinControl(ChildControl).TabStop then
        begin
            SetLength(SuspendedTabStops, Length(SuspendedTabStops) + 1);
            SuspendedTabStops[High(SuspendedTabStops)] := TWinControl(ChildControl);
            TWinControl(ChildControl).TabStop := False;
        end;
        SuspendTabStops(TWinControl(ChildControl));
    end;
end;

end.
