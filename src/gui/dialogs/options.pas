unit Options;

{$MODE objfpc}
{$H+}

interface

uses
    Classes,
    Preferences;

type
    TOptionsApplyFailureEvent = procedure(Sender: TObject; const ErrorMessage: string) of object;
    TOptionsApplyEvent =
        procedure(
            Sender: TObject;
            const EditorPreferences: TEditorPreferences;
            SuccessHandler: TNotifyEvent;
            FailureHandler: TOptionsApplyFailureEvent
        ) of object;

function EditEditorPreferences(
    Owner: TComponent;
    var EditorPreferences: TEditorPreferences;
    ApplyHandler: TOptionsApplyEvent = nil
): Boolean;

implementation

uses
    ComCtrls,
    Controls,
    ExtCtrls,
    Focus_Preserving_Page_Control,
    Forms,
    LCLIntf,
    LCLType,
    General_Tab,
    Markdown_Checker_Tab,
    StdCtrls;

type
    TOptionsForm = class(TForm)
    private
        GeneralTab: TGeneralOptionsTab;
        MarkdownCheckerTab: TMarkdownCheckerOptionsTab;
        OptionsTabs: TPageControl;
        OriginalPreferences: TEditorPreferences;
        PendingPreferences: TEditorPreferences;
        AppliedPreferences: TEditorPreferences;
        ApplyHandler: TOptionsApplyEvent;
        Applying: Boolean;
        CancelButton: TButton;
        OkButton: TButton;
        StatusLabel: TLabel;
        procedure ApplyFailed(Sender: TObject; const ErrorMessage: string);
        procedure ApplySucceeded(Sender: TObject);
        procedure CloseDialog(Sender: TObject);
        procedure CreateControls(const EditorPreferences: TEditorPreferences);
        procedure OptionsTabChanged(Sender: TObject);
        procedure Submit(Sender: TObject);
    protected
        procedure DoShow; override;
    public
        constructor CreateDialog(
            TheOwner: TComponent;
            const EditorPreferences: TEditorPreferences;
            TheApplyHandler: TOptionsApplyEvent
        );
        procedure CanCloseDialog(Sender: TObject; var CanClose: Boolean);
        property ResultPreferences: TEditorPreferences read AppliedPreferences;
    end;

procedure TOptionsForm.CreateControls(const EditorPreferences: TEditorPreferences);
var
    ButtonPanel: TPanel;
begin
    ButtonPanel := TPanel.Create(Self);
    ButtonPanel.Parent := Self;
    ButtonPanel.Align := alBottom;
    ButtonPanel.Height := 56;
    ButtonPanel.BevelOuter := bvNone;

    OkButton := TButton.Create(Self);
    OkButton.Parent := ButtonPanel;
    OkButton.Left := 444;
    OkButton.Top := 12;
    OkButton.Width := 75;
    OkButton.Caption := '&OK';
    OkButton.AccessibleName := 'OK';
    OkButton.Default := True;
    OkButton.OnClick := @Submit;

    CancelButton := TButton.Create(Self);
    CancelButton.Parent := ButtonPanel;
    CancelButton.Left := 529;
    CancelButton.Top := 12;
    CancelButton.Width := 75;
    CancelButton.Caption := 'Cancelar';
    CancelButton.AccessibleName := 'Cancelar';
    CancelButton.Cancel := True;
    CancelButton.OnClick := @CloseDialog;

    StatusLabel := TLabel.Create(Self);
    StatusLabel.Parent := ButtonPanel;
    StatusLabel.Left := 16;
    StatusLabel.Top := 20;
    StatusLabel.Caption := '';

    OptionsTabs := TFocusPreservingPageControl.Create(Self);
    OptionsTabs.Parent := Self;
    OptionsTabs.Align := alClient;
    OptionsTabs.TabStop := True;
    OptionsTabs.OnChange := @OptionsTabChanged;

    GeneralTab := TGeneralOptionsTab.CreateTab(Self, OptionsTabs, EditorPreferences);
    MarkdownCheckerTab := TMarkdownCheckerOptionsTab.CreateTab(Self, OptionsTabs, EditorPreferences);
    OptionsTabs.ActivePage := GeneralTab;
end;

procedure TOptionsForm.DoShow;
begin
    inherited DoShow;
    OptionsTabs.SetFocus;
end;

constructor TOptionsForm.CreateDialog(
    TheOwner: TComponent;
    const EditorPreferences: TEditorPreferences;
    TheApplyHandler: TOptionsApplyEvent
);
begin
    inherited CreateNew(TheOwner, 1);
    OriginalPreferences := EditorPreferences;
    PendingPreferences := EditorPreferences;
    AppliedPreferences := EditorPreferences;
    ApplyHandler := TheApplyHandler;
    Caption := 'Opções';
    BorderStyle := bsDialog;
    Position := poOwnerFormCenter;
    ClientWidth := 620;
    ClientHeight := 320;
    OnCloseQuery := @CanCloseDialog;
    CreateControls(EditorPreferences);
end;

procedure TOptionsForm.ApplyFailed(Sender: TObject; const ErrorMessage: string);
begin
    Applying := False;
    OptionsTabs.Enabled := True;
    OkButton.Enabled := True;
    CancelButton.Enabled := True;
    StatusLabel.Caption := '';
    MarkdownCheckerTab.LoadFrom(OriginalPreferences);
    OptionsTabs.ActivePage := MarkdownCheckerTab;
    MarkdownCheckerTab.ApplyAccessibility;
    LCLIntf.MessageBox(Handle, PChar(ErrorMessage), 'Erro ao aplicar opções', MB_OK or MB_ICONERROR);
    MarkdownCheckerTab.FocusExecutable;
end;

procedure TOptionsForm.ApplySucceeded(Sender: TObject);
begin
    AppliedPreferences := PendingPreferences;
    Applying := False;
    ModalResult := mrOk;
end;

procedure TOptionsForm.CanCloseDialog(Sender: TObject; var CanClose: Boolean);
begin
    CanClose := not Applying;
end;

procedure TOptionsForm.CloseDialog(Sender: TObject);
begin
    if not Applying then
        ModalResult := mrCancel;
end;

procedure TOptionsForm.OptionsTabChanged(Sender: TObject);
begin
    if OptionsTabs.ActivePage = MarkdownCheckerTab then
        MarkdownCheckerTab.ApplyAccessibility;
end;

procedure TOptionsForm.Submit(Sender: TObject);
var
    ErrorMessage: string;
begin
    PendingPreferences := OriginalPreferences;
    GeneralTab.ApplyTo(PendingPreferences);
    MarkdownCheckerTab.ApplyTo(PendingPreferences);
    if not MarkdownCheckerTab.Validate(ErrorMessage) then
    begin
        MarkdownCheckerTab.LoadFrom(OriginalPreferences);
        OptionsTabs.ActivePage := MarkdownCheckerTab;
        MarkdownCheckerTab.ApplyAccessibility;
        LCLIntf.MessageBox(Handle, PChar(ErrorMessage), 'Opções inválidas', MB_OK or MB_ICONERROR);
        MarkdownCheckerTab.FocusExecutable;
        Exit;
    end;
    if not Assigned(ApplyHandler) then
    begin
        ApplySucceeded(Self);
        Exit;
    end;
    Applying := True;
    OptionsTabs.Enabled := False;
    OkButton.Enabled := False;
    CancelButton.Enabled := False;
    if PendingPreferences.UseMarkdownChecker then
        StatusLabel.Caption := 'Inicializando o verificador de Markdown...'
    else
        StatusLabel.Caption := 'Aplicando opções...';
    ApplyHandler(Self, PendingPreferences, @ApplySucceeded, @ApplyFailed);
end;

function EditEditorPreferences(
    Owner: TComponent;
    var EditorPreferences: TEditorPreferences;
    ApplyHandler: TOptionsApplyEvent
): Boolean;
var
    Dialog: TOptionsForm;
begin
    Dialog := TOptionsForm.CreateDialog(Owner, EditorPreferences, ApplyHandler);
    try
        Result := Dialog.ShowModal = mrOk;
        if Result then
            EditorPreferences := Dialog.ResultPreferences;
    finally
        Dialog.Free;
    end;
end;

end.
