program MarkdownEditor;

{$MODE objfpc}
{$H+}

uses
    Interfaces,
    Forms,
    Main_Form in 'src/main_form.pas';

begin
    Application.Title := 'Editor Markdown Acessível';
    Application.Initialize;
    Application.CreateForm(TEditorForm, EditorForm);
    if ParamCount > 0 then
        EditorForm.LoadMarkdownDocument(ParamStr(1));
    Application.Run;
end.
