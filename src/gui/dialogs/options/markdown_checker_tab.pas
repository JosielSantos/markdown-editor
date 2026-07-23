unit Markdown_Checker_Tab;

{$MODE objfpc}
{$H+}

interface

uses
    Classes,
    ComCtrls,
    Controls,
    Preferences,
    StdCtrls;

type
    TMarkdownCheckerOptionsTab = class(TTabSheet)
    private
        ArgumentsEdit: TEdit;
        ArgumentsLabel: TLabel;
        BrowseButton: TButton;
        ExecutableEdit: TEdit;
        ExecutableLabel: TLabel;
        UseMarkdownCheckerCheckBox: TCheckBox;
        procedure BrowseExecutable(Sender: TObject);
        procedure CheckerEnabledChanged(Sender: TObject);
        procedure UpdateControlVisibility;
    public
        constructor CreateTab(
            TheOwner: TComponent;
            ThePageControl: TPageControl;
            const EditorPreferences: TEditorPreferences
        );
        procedure ApplyAccessibility;
        procedure ApplyTo(var EditorPreferences: TEditorPreferences);
        procedure FocusExecutable;
        procedure LoadFrom(const EditorPreferences: TEditorPreferences);
        function Validate(out ErrorMessage: string): Boolean;
    end;

implementation

uses
    Accessibility,
    Dialogs,
    SysUtils;

const
    ArgumentsAccessibleName = 'Argumentos do verificador de Markdown, opcional';
    ExecutableAccessibleName = 'Executável do verificador de Markdown';

constructor TMarkdownCheckerOptionsTab.CreateTab(
    TheOwner: TComponent;
    ThePageControl: TPageControl;
    const EditorPreferences: TEditorPreferences
);
begin
    inherited Create(TheOwner);
    PageControl := ThePageControl;
    Caption := 'Verificador de Markdown';

    UseMarkdownCheckerCheckBox := TCheckBox.Create(Self);
    UseMarkdownCheckerCheckBox.Parent := Self;
    UseMarkdownCheckerCheckBox.Left := 16;
    UseMarkdownCheckerCheckBox.Top := 20;
    UseMarkdownCheckerCheckBox.Caption := '&Usar verificador de Markdown';
    UseMarkdownCheckerCheckBox.AccessibleName := 'Usar verificador de Markdown';
    UseMarkdownCheckerCheckBox.OnChange := @CheckerEnabledChanged;

    ExecutableLabel := TLabel.Create(Self);
    ExecutableLabel.Parent := Self;
    ExecutableLabel.Left := 16;
    ExecutableLabel.Top := 60;
    ExecutableLabel.Caption := '&Executável do verificador de Markdown:';

    ExecutableEdit := TEdit.Create(Self);
    ExecutableEdit.Parent := Self;
    ExecutableEdit.Left := 16;
    ExecutableEdit.Top := 80;
    ExecutableEdit.Width := 470;
    ExecutableEdit.Anchors := [akLeft, akTop, akRight];
    ExecutableLabel.FocusControl := ExecutableEdit;

    BrowseButton := TButton.Create(Self);
    BrowseButton.Parent := Self;
    BrowseButton.Left := 496;
    BrowseButton.Top := 78;
    BrowseButton.Width := 96;
    BrowseButton.Anchors := [akTop, akRight];
    BrowseButton.Caption := '&Procurar...';
    BrowseButton.AccessibleName := 'Procurar executável do verificador de Markdown';
    BrowseButton.OnClick := @BrowseExecutable;

    ArgumentsLabel := TLabel.Create(Self);
    ArgumentsLabel.Parent := Self;
    ArgumentsLabel.Left := 16;
    ArgumentsLabel.Top := 124;
    ArgumentsLabel.Caption := '&Argumentos do verificador de Markdown (opcional):';

    ArgumentsEdit := TEdit.Create(Self);
    ArgumentsEdit.Parent := Self;
    ArgumentsEdit.Left := 16;
    ArgumentsEdit.Top := 144;
    ArgumentsEdit.Width := 576;
    ArgumentsEdit.Anchors := [akLeft, akTop, akRight];
    ArgumentsLabel.FocusControl := ArgumentsEdit;

    LoadFrom(EditorPreferences);
end;

procedure TMarkdownCheckerOptionsTab.BrowseExecutable(Sender: TObject);
var
    OpenDialog: TOpenDialog;
begin
    OpenDialog := TOpenDialog.Create(Self);
    try
        OpenDialog.Title := 'Selecionar verificador de Markdown';
        OpenDialog.Filter := 'Executáveis|*.exe;*.com;*.bat;*.cmd|Todos os arquivos|*.*';
        OpenDialog.Options := [ofFileMustExist, ofPathMustExist, ofEnableSizing];
        if ExecutableEdit.Text <> '' then
        begin
            OpenDialog.FileName := ExecutableEdit.Text;
            if DirectoryExists(ExtractFileDir(ExecutableEdit.Text)) then
                OpenDialog.InitialDir := ExtractFileDir(ExecutableEdit.Text);
        end;
        if OpenDialog.Execute then
            ExecutableEdit.Text := OpenDialog.FileName;
    finally
        OpenDialog.Free;
    end;
end;

procedure TMarkdownCheckerOptionsTab.CheckerEnabledChanged(Sender: TObject);
begin
    UpdateControlVisibility;
    if UseMarkdownCheckerCheckBox.Checked and (PageControl.ActivePage = Self) then
        ApplyAccessibility;
end;

procedure TMarkdownCheckerOptionsTab.UpdateControlVisibility;
var
    ControlsVisible: Boolean;
begin
    ControlsVisible := UseMarkdownCheckerCheckBox.Checked;
    ExecutableLabel.Visible := ControlsVisible;
    ExecutableEdit.Visible := ControlsVisible;
    BrowseButton.Visible := ControlsVisible;
    ArgumentsLabel.Visible := ControlsVisible;
    ArgumentsEdit.Visible := ControlsVisible;
end;

procedure TMarkdownCheckerOptionsTab.ApplyAccessibility;
begin
    if not UseMarkdownCheckerCheckBox.Checked then
        Exit;
    SetControlAccessibleName(ExecutableEdit, ExecutableAccessibleName);
    SetControlAccessibleName(ArgumentsEdit, ArgumentsAccessibleName);
end;

procedure TMarkdownCheckerOptionsTab.ApplyTo(var EditorPreferences: TEditorPreferences);
begin
    EditorPreferences.UseMarkdownChecker := UseMarkdownCheckerCheckBox.Checked;
    EditorPreferences.MarkdownCheckerExecutableFileName := Trim(ExecutableEdit.Text);
    EditorPreferences.MarkdownCheckerArguments := ArgumentsEdit.Text;
end;

procedure TMarkdownCheckerOptionsTab.FocusExecutable;
begin
    if UseMarkdownCheckerCheckBox.Checked and ExecutableEdit.CanFocus then
        ExecutableEdit.SetFocus
    else if UseMarkdownCheckerCheckBox.CanFocus then
        UseMarkdownCheckerCheckBox.SetFocus;
end;

procedure TMarkdownCheckerOptionsTab.LoadFrom(const EditorPreferences: TEditorPreferences);
begin
    UseMarkdownCheckerCheckBox.Checked := EditorPreferences.UseMarkdownChecker;
    ExecutableEdit.Text := EditorPreferences.MarkdownCheckerExecutableFileName;
    ArgumentsEdit.Text := EditorPreferences.MarkdownCheckerArguments;
    UpdateControlVisibility;
end;

function TMarkdownCheckerOptionsTab.Validate(out ErrorMessage: string): Boolean;
var
    ExecutableFileName: string;
begin
    ErrorMessage := '';
    if not UseMarkdownCheckerCheckBox.Checked then
        Exit(True);
    ExecutableFileName := Trim(ExecutableEdit.Text);
    if ExecutableFileName = '' then
        ErrorMessage := 'Informe o executável do verificador de Markdown.'
    else if not FileExists(ExecutableFileName) then
        ErrorMessage :=
            Format(
                'O executável do verificador de Markdown não foi encontrado:%s%s',
                [LineEnding, ExecutableFileName]
            );
    Result := ErrorMessage = '';
end;

end.
