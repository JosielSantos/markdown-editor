program MarkdownEditor;

{$mode objfpc}{$H+}

uses
  Interfaces,
  Forms,
  Main_Form in 'src/main_form.pas';

begin
  Application.Title := 'Editor Markdown Acessível';
  Application.Initialize;
  Application.CreateForm(TEditorForm, EditorForm);
  Application.Run;
end.
