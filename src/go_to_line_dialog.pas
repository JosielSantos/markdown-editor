unit Go_To_Line_Dialog;

{$MODE objfpc}
{$H+}

interface

uses
    Classes,
    Forms,
    StdCtrls;

function ChooseLineNumber(
    Owner: TComponent;
    CurrentLine: Integer;
    LineCount: Integer;
    out SelectedLine: Integer
): Boolean;

implementation

uses
    Controls,
    Gui_Helpers,
    LCLIntf,
    LCLType,
    Line_Navigation,
    SysUtils;

type
    TGoToLineForm = class(TForm)
    private
        AvailableLineCount: Integer;
        GoButton: TButton;
        LineEdit: TEdit;
        procedure AcceptSelection(Sender: TObject);
        procedure CreateControls(CurrentLine: Integer);
    protected
        procedure DoShow; override;
    public
        constructor CreateDialog(TheOwner: TComponent; CurrentLine, LineCount: Integer);
        function SelectedLine: Integer;
    end;

procedure TGoToLineForm.AcceptSelection(Sender: TObject);
var
    LineNumber: Integer;
begin
    if TryParseLineNumber(LineEdit.Text, AvailableLineCount, LineNumber) then
    begin
        ModalResult := mrOk;
        Exit;
    end;
    LCLIntf.MessageBox(
        Handle,
        PChar(Format('Informe um número de linha entre 1 e %d.', [AvailableLineCount])),
        'Linha inválida',
        MB_OK or MB_ICONERROR
    );
    LineEdit.SetFocus;
    LineEdit.SelectAll;
end;

procedure TGoToLineForm.CreateControls(CurrentLine: Integer);
var
    CancelButton: TButton;
    LineLabel: TLabel;
begin
    LineLabel := TLabel.Create(Self);
    LineLabel.Parent := Self;
    LineLabel.Left := 16;
    LineLabel.Top := 16;
    LineLabel.Caption := Format('&Número da linha (1 a %d):', [AvailableLineCount]);

    LineEdit := TEdit.Create(Self);
    LineEdit.Parent := Self;
    LineEdit.Left := 16;
    LineEdit.Top := 40;
    LineEdit.Width := 320;
    LineEdit.Text := IntToStr(CurrentLine);
    LineEdit.AccessibleDescription := Format('Informe um número entre 1 e %d.', [AvailableLineCount]);
    LineLabel.FocusControl := LineEdit;

    GoButton := TButton.Create(Self);
    GoButton.Parent := Self;
    GoButton.Left := 176;
    GoButton.Top := 80;
    GoButton.Width := 75;
    GoButton.Caption := '&Ir';
    GoButton.AccessibleName := 'Ir';
    GoButton.Default := True;
    GoButton.OnClick := @AcceptSelection;

    CancelButton := TButton.Create(Self);
    CancelButton.Parent := Self;
    CancelButton.Left := 261;
    CancelButton.Top := 80;
    CancelButton.Width := 75;
    CancelButton.Caption := 'Cancelar';
    CancelButton.AccessibleName := 'Cancelar';
    CancelButton.Cancel := True;
    CancelButton.ModalResult := mrCancel;
end;

procedure TGoToLineForm.DoShow;
begin
    inherited DoShow;
    SetControlAccessibleName(LineEdit, 'Número da linha');
    LineEdit.SetFocus;
    LineEdit.SelectAll;
end;

constructor TGoToLineForm.CreateDialog(TheOwner: TComponent; CurrentLine, LineCount: Integer);
begin
    inherited CreateNew(TheOwner, 1);
    AvailableLineCount := EffectiveLineCount(LineCount);
    Caption := 'Ir para a linha';
    BorderStyle := bsDialog;
    Position := poOwnerFormCenter;
    ClientWidth := 352;
    ClientHeight := 120;
    CreateControls(CurrentLine);
end;

function TGoToLineForm.SelectedLine: Integer;
begin
    TryParseLineNumber(LineEdit.Text, AvailableLineCount, Result);
end;

function ChooseLineNumber(
    Owner: TComponent;
    CurrentLine: Integer;
    LineCount: Integer;
    out SelectedLine: Integer
): Boolean;
var
    Dialog: TGoToLineForm;
begin
    Dialog := TGoToLineForm.CreateDialog(Owner, CurrentLine, LineCount);
    try
        Result := Dialog.ShowModal = mrOk;
        if Result then
            SelectedLine := Dialog.SelectedLine;
    finally
        Dialog.Free;
    end;
end;

end.
