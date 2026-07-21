program MarkdownEditor;

{$MODE objfpc}
{$H+}

uses
    Command_Line in 'src/command_line.pas',
    File_Association_Service in 'src/file_association_service.pas',
    Interfaces,
    Forms,
    LCLIntf,
    LCLType,
    Main_Form in 'src/main_form.pas',
    SysUtils;

var
    CommandLineArguments: TCommandLineArguments;
begin
    Application.Title := 'Markdown Editor';
    Application.Initialize;
    CommandLineArguments := ParseProcessArguments;
    if CommandLineArguments.ErrorMessage <> '' then
    begin
        MessageBox(0, PChar(CommandLineArguments.ErrorMessage), PChar(Application.Title), MB_OK or MB_ICONERROR);
        ExitCode := 2;
        Exit;
    end;
    if CommandLineArguments.Action = claAssociateFiles then
    begin
        try
            AssociateMarkdownFiles(ExpandFileName(ParamStr(0)));
            if not CommandLineArguments.Quiet then
                MessageBox(
                    0,
                    'As extensões .md e .markdown foram associadas com sucesso para este usuário.',
                    PChar(Application.Title),
                    MB_OK or MB_ICONINFORMATION
                );
        except
            on Error: Exception do
            begin
                MessageBox(0, PChar(Error.Message), 'Erro ao associar arquivos', MB_OK or MB_ICONERROR);
                ExitCode := 1;
                Exit;
            end;
        end;
        if not CommandLineArguments.StartApplication then
            Exit;
    end;
    Application.CreateForm(TEditorForm, EditorForm);
    if CommandLineArguments.MarkdownFileName <> '' then
        EditorForm.InitializeMarkdownDocument(CommandLineArguments.MarkdownFileName)
    else
        EditorForm.RestoreLastSession;
    Application.Run;
end.
