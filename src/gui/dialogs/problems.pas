unit Problems;

{$MODE objfpc}
{$H+}

interface

uses
    Forms,
    Lsp_Diagnostics;

function ChooseProblemLine(
    OwnerForm: TCustomForm;
    const Diagnostics: TLspDiagnosticArray;
    out LineNumber: Integer
): Boolean;

implementation

uses
    Accessibility,
    Classes,
    ComCtrls,
    Controls,
    LCLType,
    SysUtils;

type
    TProblemsForm = class(TForm)
    private
        ProblemsList: TListView;
        SelectedLineNumber: Integer;
        procedure ActivateSelectedProblem;
        procedure AddColumn(const ColumnTitle: string; ColumnWidth: Integer);
        procedure AddDiagnostic(const Diagnostic: TLspDiagnostic);
        procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
        procedure ProblemDoubleClick(Sender: TObject);
        procedure ProblemKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
        procedure Populate(const Diagnostics: TLspDiagnosticArray);
    protected
        procedure DoShow; override;
    public
        constructor Create(TheOwner: TComponent); override;
        function ChooseLine(const Diagnostics: TLspDiagnosticArray; out LineNumber: Integer): Boolean;
    end;

function SeverityText(Severity: TLspDiagnosticSeverity): string;
begin
    if Severity = ldsError then
        Result := 'Erro'
    else
        Result := 'Aviso';
end;

constructor TProblemsForm.Create(TheOwner: TComponent);
begin
    inherited CreateNew(TheOwner, 1);
    Caption := 'Problemas';
    Position := poOwnerFormCenter;
    Width := 800;
    Height := 400;
    Constraints.MinWidth := 500;
    Constraints.MinHeight := 250;
    KeyPreview := True;
    OnKeyDown := @FormKeyDown;

    ProblemsList := TListView.Create(Self);
    ProblemsList.Parent := Self;
    ProblemsList.Align := alClient;
    ProblemsList.ViewStyle := vsReport;
    ProblemsList.ReadOnly := True;
    ProblemsList.RowSelect := True;
    ProblemsList.HideSelection := False;
    ProblemsList.AccessibleName := 'Lista de problemas';
    ProblemsList.AccessibleDescription := 'Pressione Enter para ir até a linha selecionada.';
    ProblemsList.OnDblClick := @ProblemDoubleClick;
    ProblemsList.OnKeyDown := @ProblemKeyDown;
    AddColumn('Nível', 100);
    AddColumn('Linha', 80);
    AddColumn('Mensagem', 580);
end;

procedure TProblemsForm.DoShow;
begin
    inherited DoShow;
    SetControlAccessibleName(ProblemsList, 'Lista de problemas');
end;

procedure TProblemsForm.AddColumn(const ColumnTitle: string; ColumnWidth: Integer);
var
    Column: TListColumn;
begin
    Column := ProblemsList.Columns.Add;
    Column.Caption := ColumnTitle;
    Column.Width := ColumnWidth;
end;

procedure TProblemsForm.AddDiagnostic(const Diagnostic: TLspDiagnostic);
var
    ListItem: TListItem;
begin
    ListItem := ProblemsList.Items.Add;
    ListItem.Caption := SeverityText(Diagnostic.Severity);
    ListItem.SubItems.Add(IntToStr(Diagnostic.LineNumber));
    ListItem.SubItems.Add(Diagnostic.MessageText);
end;

procedure TProblemsForm.Populate(const Diagnostics: TLspDiagnosticArray);
var
    Diagnostic: TLspDiagnostic;
    ListItem: TListItem;
begin
    ProblemsList.Items.BeginUpdate;
    try
        ProblemsList.Items.Clear;
        for Diagnostic in Diagnostics do
            AddDiagnostic(Diagnostic);
        if ProblemsList.Items.Count = 0 then
        begin
            ListItem := ProblemsList.Items.Add;
            ListItem.Caption := 'Nenhum problema';
        end;
    finally
        ProblemsList.Items.EndUpdate;
    end;
    ProblemsList.ItemFocused := ProblemsList.Items[0];
    ProblemsList.Selected := ProblemsList.Items[0];
end;

procedure TProblemsForm.ActivateSelectedProblem;
begin
    if not Assigned(ProblemsList.Selected) then
        Exit;
    if (ProblemsList.Selected.SubItems.Count > 0)
        and TryStrToInt(ProblemsList.Selected.SubItems[0], SelectedLineNumber) then
        ModalResult := mrOk;
end;

procedure TProblemsForm.ProblemKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
    if Key <> VK_RETURN then
        Exit;
    ActivateSelectedProblem;
    Key := 0;
end;

procedure TProblemsForm.ProblemDoubleClick(Sender: TObject);
begin
    ActivateSelectedProblem;
end;

procedure TProblemsForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
    if Key <> VK_ESCAPE then
        Exit;
    ModalResult := mrCancel;
    Key := 0;
end;

function TProblemsForm.ChooseLine(const Diagnostics: TLspDiagnosticArray; out LineNumber: Integer): Boolean;
begin
    SelectedLineNumber := 0;
    Populate(Diagnostics);
    ActiveControl := ProblemsList;
    Result := ShowModal = mrOk;
    LineNumber := SelectedLineNumber;
end;

function ChooseProblemLine(
    OwnerForm: TCustomForm;
    const Diagnostics: TLspDiagnosticArray;
    out LineNumber: Integer
): Boolean;
var
    ProblemsForm: TProblemsForm;
begin
    ProblemsForm := TProblemsForm.Create(OwnerForm);
    try
        Result := ProblemsForm.ChooseLine(Diagnostics, LineNumber);
    finally
        ProblemsForm.Free;
    end;
end;

end.
