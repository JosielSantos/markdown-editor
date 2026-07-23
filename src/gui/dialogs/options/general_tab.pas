unit General_Tab;

{$MODE objfpc}
{$H+}

interface

uses
    Classes,
    ComCtrls,
    Preferences,
    StdCtrls;

type
    TGeneralOptionsTab = class(TTabSheet)
    private
        LoadLastFileCheckBox: TCheckBox;
    public
        constructor CreateTab(
            TheOwner: TComponent;
            ThePageControl: TPageControl;
            const EditorPreferences: TEditorPreferences
        );
        procedure ApplyTo(var EditorPreferences: TEditorPreferences);
    end;

implementation

constructor TGeneralOptionsTab.CreateTab(
    TheOwner: TComponent;
    ThePageControl: TPageControl;
    const EditorPreferences: TEditorPreferences
);
begin
    inherited Create(TheOwner);
    PageControl := ThePageControl;
    Caption := 'Geral';

    LoadLastFileCheckBox := TCheckBox.Create(Self);
    LoadLastFileCheckBox.Parent := Self;
    LoadLastFileCheckBox.Left := 16;
    LoadLastFileCheckBox.Top := 20;
    LoadLastFileCheckBox.Caption := '&Reabrir o último arquivo ao iniciar o editor';
    LoadLastFileCheckBox.AccessibleName := 'Reabrir o último arquivo ao iniciar o editor';
    LoadLastFileCheckBox.Checked := EditorPreferences.LoadLastFile;
end;

procedure TGeneralOptionsTab.ApplyTo(var EditorPreferences: TEditorPreferences);
begin
    EditorPreferences.LoadLastFile := LoadLastFileCheckBox.Checked;
end;

end.
