unit General_Tab;

{$MODE objfpc}
{$H+}

interface

uses
    Classes,
    ComCtrls,
    ExtCtrls,
    Editor_Preferences,
    StdCtrls;

type
    TGeneralOptionsTab = class(TTabSheet)
    private
        FileMonitoringRadioGroup: TRadioGroup;
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

    FileMonitoringRadioGroup := TRadioGroup.Create(Self);
    FileMonitoringRadioGroup.Parent := Self;
    FileMonitoringRadioGroup.Left := 16;
    FileMonitoringRadioGroup.Top := 60;
    FileMonitoringRadioGroup.Width := 430;
    FileMonitoringRadioGroup.Height := 120;
    FileMonitoringRadioGroup.Caption := 'Alterações externas no arquivo aberto';
    FileMonitoringRadioGroup.AccessibleName := 'Alterações externas no arquivo aberto';
    FileMonitoringRadioGroup.Items.Add('Atualizar &automaticamente');
    FileMonitoringRadioGroup.Items.Add('&Perguntar antes de atualizar');
    FileMonitoringRadioGroup.Items.Add('&Não monitorar');
    FileMonitoringRadioGroup.ItemIndex := Ord(EditorPreferences.FileMonitoringMode);
end;

procedure TGeneralOptionsTab.ApplyTo(var EditorPreferences: TEditorPreferences);
begin
    EditorPreferences.FileMonitoringMode := TFileMonitoringMode(FileMonitoringRadioGroup.ItemIndex);
    EditorPreferences.LoadLastFile := LoadLastFileCheckBox.Checked;
end;

end.
