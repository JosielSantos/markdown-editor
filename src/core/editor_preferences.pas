unit Editor_Preferences;

{$MODE objfpc}
{$H+}

interface

type
    TFileMonitoringMode = (fmmAutomatic, fmmAskBeforeUpdating, fmmDisabled);

    TEditorPreferences = record
        FileMonitoringMode: TFileMonitoringMode;
        LoadLastFile: Boolean;
        MarkdownCheckerArguments: string;
        MarkdownCheckerExecutableFileName: string;
        UseMarkdownChecker: Boolean;
    end;

function DefaultEditorPreferences(const DefaultMarkdownCheckerExecutableFileName: string = ''): TEditorPreferences;

implementation

function DefaultEditorPreferences(const DefaultMarkdownCheckerExecutableFileName: string): TEditorPreferences;
begin
    Result.FileMonitoringMode := fmmAskBeforeUpdating;
    Result.LoadLastFile := True;
    Result.MarkdownCheckerArguments := '';
    Result.MarkdownCheckerExecutableFileName := DefaultMarkdownCheckerExecutableFileName;
    Result.UseMarkdownChecker := False;
end;

end.
