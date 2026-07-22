unit Insert_Link;

{$MODE objfpc}
{$H+}

interface

uses
    Classes;

function ChooseMarkdownLink(Owner: TComponent; const InitialTitle: string; out LinkTitle, LinkAddress: string): Boolean;

implementation

uses
    Controls,
    Forms,
    Accessibility,
    LCLIntf,
    LCLType,
    StdCtrls,
    SysUtils;

type
    TLinkDialogForm = class(TForm)
    private
        AddressEdit: TEdit;
        TitleEdit: TEdit;
        procedure AcceptLink(Sender: TObject);
        procedure CreateControls(const InitialTitle: string);
    protected
        procedure DoShow; override;
    public
        constructor CreateDialog(TheOwner: TComponent; const InitialTitle: string);
        function LinkAddress: string;
        function LinkTitle: string;
    end;

procedure TLinkDialogForm.AcceptLink(Sender: TObject);
begin
    if Trim(TitleEdit.Text) = '' then
    begin
        LCLIntf.MessageBox(Handle, 'Informe o título do link.', 'Título obrigatório', MB_OK or MB_ICONERROR);
        TitleEdit.SetFocus;
        Exit;
    end;
    if Trim(AddressEdit.Text) = '' then
    begin
        LCLIntf.MessageBox(Handle, 'Informe o endereço do link.', 'Endereço obrigatório', MB_OK or MB_ICONERROR);
        AddressEdit.SetFocus;
        Exit;
    end;
    ModalResult := mrOk;
end;

procedure TLinkDialogForm.CreateControls(const InitialTitle: string);
var
    AddressLabel: TStaticText;
    CancelButton: TButton;
    InsertButton: TButton;
    TitleLabel: TStaticText;
begin
    TitleLabel := TStaticText.Create(Self);
    TitleLabel.Parent := Self;
    TitleLabel.Left := 16;
    TitleLabel.Top := 16;
    TitleLabel.Caption := '&Título:';
    TitleLabel.AccessibleName := 'Título';
    TitleLabel.AccessibleRole := larLabel;

    TitleEdit := TEdit.Create(Self);
    TitleEdit.Parent := Self;
    TitleEdit.Left := 16;
    TitleEdit.Top := 40;
    TitleEdit.Width := 400;
    TitleEdit.Text := InitialTitle;
    TitleEdit.AccessibleName := 'Título do link';
    TitleEdit.AccessibleDescription := 'Informe o texto que será exibido para o link.';
    TitleLabel.FocusControl := TitleEdit;

    AddressLabel := TStaticText.Create(Self);
    AddressLabel.Parent := Self;
    AddressLabel.Left := 16;
    AddressLabel.Top := 76;
    AddressLabel.Caption := '&Endereço:';
    AddressLabel.AccessibleName := 'Endereço';
    AddressLabel.AccessibleRole := larLabel;

    AddressEdit := TEdit.Create(Self);
    AddressEdit.Parent := Self;
    AddressEdit.Left := 16;
    AddressEdit.Top := 100;
    AddressEdit.Width := 400;
    AddressEdit.AccessibleName := 'Endereço do link';
    AddressEdit.AccessibleDescription := 'Informe o endereço de destino do link.';
    AddressLabel.FocusControl := AddressEdit;

    InsertButton := TButton.Create(Self);
    InsertButton.Parent := Self;
    InsertButton.Left := 256;
    InsertButton.Top := 140;
    InsertButton.Width := 75;
    InsertButton.Caption := '&Inserir';
    InsertButton.AccessibleName := 'Inserir link';
    InsertButton.Default := True;
    InsertButton.OnClick := @AcceptLink;

    CancelButton := TButton.Create(Self);
    CancelButton.Parent := Self;
    CancelButton.Left := 341;
    CancelButton.Top := 140;
    CancelButton.Width := 75;
    CancelButton.Caption := 'Cancelar';
    CancelButton.AccessibleName := 'Cancelar';
    CancelButton.Cancel := True;
    CancelButton.ModalResult := mrCancel;
end;

procedure TLinkDialogForm.DoShow;
begin
    inherited DoShow;
    SetControlAccessibleName(TitleEdit, 'Título do link');
    SetControlAccessibleName(AddressEdit, 'Endereço do link');
    TitleEdit.SetFocus;
    TitleEdit.SelectAll;
end;

constructor TLinkDialogForm.CreateDialog(TheOwner: TComponent; const InitialTitle: string);
begin
    inherited CreateNew(TheOwner, 1);
    Caption := 'Inserir link';
    BorderStyle := bsDialog;
    Position := poOwnerFormCenter;
    ClientWidth := 432;
    ClientHeight := 180;
    CreateControls(InitialTitle);
end;

function TLinkDialogForm.LinkAddress: string;
begin
    Result := AddressEdit.Text;
end;

function TLinkDialogForm.LinkTitle: string;
begin
    Result := TitleEdit.Text;
end;

function ChooseMarkdownLink(Owner: TComponent; const InitialTitle: string; out LinkTitle, LinkAddress: string): Boolean;
var
    Dialog: TLinkDialogForm;
begin
    Dialog := TLinkDialogForm.CreateDialog(Owner, InitialTitle);
    try
        Result := Dialog.ShowModal = mrOk;
        if Result then
        begin
            LinkTitle := Dialog.LinkTitle;
            LinkAddress := Dialog.LinkAddress;
        end;
    finally
        Dialog.Free;
    end;
end;

end.
