unit Main_Form;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  Forms;

type
  TEditorForm = class(TForm)
  public
    constructor Create(TheOwner: TComponent); override;
  end;

var
  EditorForm: TEditorForm;

implementation

constructor TEditorForm.Create(TheOwner: TComponent);
begin
  inherited CreateNew(TheOwner, 1);
  Caption := 'Editor Markdown Acessível';
  Position := poScreenCenter;
  Width := 900;
  Height := 650;
end;

end.
