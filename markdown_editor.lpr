program MarkdownEditor;

{$MODE objfpc}
{$H+}

{$R resources/markdown_editor_resources.rc}

uses
    Command_Line,
    Editor,
    Editor_Coordinator,
    Editor_Preferences,
    File_Association,
    Interfaces,
    Forms,
    Html_Document_Template,
    LCLIntf,
    LCLType,
    Language_Server_Controller,
    Main_Form,
    Preferences_Ini,
    SysUtils;

var
    CommandLineArguments: TCommandLineArguments;
    EditorCoordinator: TEditorCoordinator;
    EditorPreferences: TEditorPreferences;
    SettingsFileName: string;
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
    SettingsFileName := DefaultSettingsFileName;
    EditorPreferences := LoadEditorPreferences(SettingsFileName, DefaultLanguageServerExecutableFileName);
    Application.CreateForm(TEditorForm, EditorForm);
    EditorCoordinator :=
        TEditorCoordinator.Create(EditorForm, EditorPreferences, SettingsFileName, LoadDefaultHtmlDocumentTemplate);
    try
        if CommandLineArguments.MarkdownFileName <> '' then
            EditorCoordinator.InitializeMarkdownDocument(CommandLineArguments.MarkdownFileName)
        else
            EditorCoordinator.RestoreLastSession;
        Application.Run;
    finally
        EditorCoordinator.Free;
    end;
end.
