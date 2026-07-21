program MarkdownEditor;

{$MODE objfpc}
{$H+}

uses
    Command_Line in 'src/command_line.pas',
    Interfaces,
    Forms,
    LCLIntf,
    LCLType,
    Main_Form in 'src/main_form.pas';

var
    CommandLineArguments: TCommandLineArguments;
begin
    Application.Title := 'Editor Markdown Acessível';
    Application.Initialize;
    Application.CreateForm(TEditorForm, EditorForm);
    CommandLineArguments := ParseProcessArguments;
    if CommandLineArguments.ErrorMessage <> '' then
        MessageBox(0, PChar(CommandLineArguments.ErrorMessage), PChar(Application.Title), MB_OK or MB_ICONERROR)
    else if CommandLineArguments.MarkdownFileName <> '' then
        EditorForm.InitializeMarkdownDocument(CommandLineArguments.MarkdownFileName);
    Application.Run;
end.
