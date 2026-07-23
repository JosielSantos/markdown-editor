unit Options;

{$MODE objfpc}
{$H+}

interface

uses
    Classes,
    Preferences;

function EditEditorPreferences(Owner: TComponent; var EditorPreferences: TEditorPreferences): Boolean;

implementation

uses
    ComCtrls,
    Controls,
    ExtCtrls,
    Forms,
    LCLType,
    General_Tab,
    StdCtrls;

type
    TOptionsForm = class(TForm)
    private
        GeneralTab: TGeneralOptionsTab;
        OptionsTabs: TPageControl;
        procedure CreateControls(const EditorPreferences: TEditorPreferences);
    protected
        procedure DoShow; override;
    public
        constructor CreateDialog(TheOwner: TComponent; const EditorPreferences: TEditorPreferences);
        procedure ApplyTo(var EditorPreferences: TEditorPreferences);
    end;

procedure TOptionsForm.CreateControls(const EditorPreferences: TEditorPreferences);
var
    ButtonPanel: TPanel;
    CancelButton: TButton;
    OkButton: TButton;
begin
    ButtonPanel := TPanel.Create(Self);
    ButtonPanel.Parent := Self;
    ButtonPanel.Align := alBottom;
    ButtonPanel.Height := 56;
    ButtonPanel.BevelOuter := bvNone;

    OkButton := TButton.Create(Self);
    OkButton.Parent := ButtonPanel;
    OkButton.Left := 336;
    OkButton.Top := 12;
    OkButton.Width := 75;
    OkButton.Caption := '&OK';
    OkButton.AccessibleName := 'OK';
    OkButton.Default := True;
    OkButton.ModalResult := mrOk;

    CancelButton := TButton.Create(Self);
    CancelButton.Parent := ButtonPanel;
    CancelButton.Left := 421;
    CancelButton.Top := 12;
    CancelButton.Width := 75;
    CancelButton.Caption := 'Cancelar';
    CancelButton.AccessibleName := 'Cancelar';
    CancelButton.Cancel := True;
    CancelButton.ModalResult := mrCancel;

    OptionsTabs := TPageControl.Create(Self);
    OptionsTabs.Parent := Self;
    OptionsTabs.Align := alClient;
    OptionsTabs.TabStop := True;

    GeneralTab := TGeneralOptionsTab.CreateTab(Self, OptionsTabs, EditorPreferences);
    OptionsTabs.ActivePage := GeneralTab;
end;

procedure TOptionsForm.DoShow;
begin
    inherited DoShow;
    OptionsTabs.SetFocus;
end;

constructor TOptionsForm.CreateDialog(TheOwner: TComponent; const EditorPreferences: TEditorPreferences);
begin
    inherited CreateNew(TheOwner, 1);
    Caption := 'Opções';
    BorderStyle := bsDialog;
    Position := poOwnerFormCenter;
    ClientWidth := 512;
    ClientHeight := 320;
    CreateControls(EditorPreferences);
end;

procedure TOptionsForm.ApplyTo(var EditorPreferences: TEditorPreferences);
begin
    GeneralTab.ApplyTo(EditorPreferences);
end;

function EditEditorPreferences(Owner: TComponent; var EditorPreferences: TEditorPreferences): Boolean;
var
    Dialog: TOptionsForm;
begin
    Dialog := TOptionsForm.CreateDialog(Owner, EditorPreferences);
    try
        Result := Dialog.ShowModal = mrOk;
        if Result then
            Dialog.ApplyTo(EditorPreferences);
    finally
        Dialog.Free;
    end;
end;

end.
