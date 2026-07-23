unit Options_Controller;

{$MODE objfpc}
{$H+}

interface

uses
    Classes,
    Forms,
    Language_Server_Controller,
    Options,
    Preferences,
    StdCtrls;

type
    TOptionsController = class
    private
        CurrentFileName: string;
        EditorMemo: TMemo;
        FailureHandler: TOptionsApplyFailureEvent;
        LanguageServer: TLanguageServerController;
        OriginalPreferences: TEditorPreferences;
        OriginalServerRunning: Boolean;
        OwnerForm: TCustomForm;
        PendingPreferences: TEditorPreferences;
        SettingsFileName: string;
        SuccessHandler: TNotifyEvent;
        procedure ApplyPreferences(
            Sender: TObject;
            const EditorPreferences: TEditorPreferences;
            TheSuccessHandler: TNotifyEvent;
            TheFailureHandler: TOptionsApplyFailureEvent
        );
        procedure ApplySucceeded;
        procedure LanguageServerReady(Sender: TObject);
        procedure LanguageServerStartFailed(Sender: TObject; const ErrorMessage: string);
        procedure RestorePreviousLanguageServer;
        procedure SavePendingPreferences;
    public
        constructor Create(
            TheOwnerForm: TCustomForm;
            TheEditorMemo: TMemo;
            TheLanguageServer: TLanguageServerController;
            const TheSettingsFileName: string
        );
        function Edit(var EditorPreferences: TEditorPreferences; const TheCurrentFileName: string): Boolean;
    end;

implementation

uses
    SysUtils;

constructor TOptionsController.Create(
    TheOwnerForm: TCustomForm;
    TheEditorMemo: TMemo;
    TheLanguageServer: TLanguageServerController;
    const TheSettingsFileName: string
);
begin
    OwnerForm := TheOwnerForm;
    EditorMemo := TheEditorMemo;
    LanguageServer := TheLanguageServer;
    SettingsFileName := TheSettingsFileName;
end;

function TOptionsController.Edit(var EditorPreferences: TEditorPreferences; const TheCurrentFileName: string): Boolean;
begin
    OriginalPreferences := EditorPreferences;
    OriginalServerRunning := LanguageServer.IsRunning;
    CurrentFileName := TheCurrentFileName;
    Result := EditEditorPreferences(OwnerForm, EditorPreferences, @ApplyPreferences);
end;

procedure TOptionsController.ApplyPreferences(
    Sender: TObject;
    const EditorPreferences: TEditorPreferences;
    TheSuccessHandler: TNotifyEvent;
    TheFailureHandler: TOptionsApplyFailureEvent
);
begin
    PendingPreferences := EditorPreferences;
    SuccessHandler := TheSuccessHandler;
    FailureHandler := TheFailureHandler;

    if not PendingPreferences.UseMarkdownChecker then
    begin
        LanguageServer.Stop;
        SavePendingPreferences;
        Exit;
    end;

    if LanguageServer.IsRunning
        and LanguageServer.UsesConfiguration(
            PendingPreferences.MarkdownCheckerExecutableFileName,
            PendingPreferences.MarkdownCheckerArguments) then
    begin
        SavePendingPreferences;
        Exit;
    end;

    LanguageServer.Start(
        PendingPreferences.MarkdownCheckerExecutableFileName,
        PendingPreferences.MarkdownCheckerArguments,
        @LanguageServerReady,
        @LanguageServerStartFailed
    );
    if CurrentFileName <> '' then
        LanguageServer.OpenDocument(CurrentFileName, EditorMemo.Text);
end;

procedure TOptionsController.ApplySucceeded;
var
    Handler: TNotifyEvent;
begin
    Handler := SuccessHandler;
    SuccessHandler := nil;
    FailureHandler := nil;
    if Assigned(Handler) then
        Handler(Self);
end;

procedure TOptionsController.LanguageServerReady(Sender: TObject);
begin
    SavePendingPreferences;
end;

procedure TOptionsController.LanguageServerStartFailed(Sender: TObject; const ErrorMessage: string);
var
    Handler: TOptionsApplyFailureEvent;
begin
    RestorePreviousLanguageServer;
    Handler := FailureHandler;
    SuccessHandler := nil;
    FailureHandler := nil;
    if Assigned(Handler) then
        Handler(Self, Format('Não foi possível iniciar o verificador de Markdown:%s%s', [LineEnding, ErrorMessage]));
end;

procedure TOptionsController.RestorePreviousLanguageServer;
begin
    LanguageServer.Stop;
    if not OriginalServerRunning or not OriginalPreferences.UseMarkdownChecker then
        Exit;
    LanguageServer
        .Start(OriginalPreferences.MarkdownCheckerExecutableFileName, OriginalPreferences.MarkdownCheckerArguments);
    if CurrentFileName <> '' then
        LanguageServer.OpenDocument(CurrentFileName, EditorMemo.Text);
end;

procedure TOptionsController.SavePendingPreferences;
var
    Handler: TOptionsApplyFailureEvent;
begin
    try
        SaveEditorPreferences(SettingsFileName, PendingPreferences);
        ApplySucceeded;
    except
        on Error: Exception do
        begin
            RestorePreviousLanguageServer;
            Handler := FailureHandler;
            SuccessHandler := nil;
            FailureHandler := nil;
            if Assigned(Handler) then
                Handler(Self, 'Não foi possível salvar as opções:' + LineEnding + Error.Message);
        end;
    end;
end;

end.
