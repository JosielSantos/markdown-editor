unit Test_File_Association;

{$MODE objfpc}
{$H+}

interface

uses
    FpcUnit;

type
    TFileAssociationServiceTests = class(TTestCase)
    published
        procedure BuildsQuotedRegistryCommands;
        procedure ProvidesFriendlyApplicationName;
    end;

implementation

uses
    File_Association,
    TestRegistry;

procedure TFileAssociationServiceTests.BuildsQuotedRegistryCommands;
const
    ExecutableFileName = 'C:\Program Files\Markdown Editor\markdown-editor.exe';
begin
    AssertEquals(
        'comando de abertura',
        '"C:\Program Files\Markdown Editor\markdown-editor.exe" "%1"',
        BuildOpenCommand(ExecutableFileName)
    );
    AssertEquals(
        'ícone',
        '"C:\Program Files\Markdown Editor\markdown-editor.exe",0',
        BuildIconReference(ExecutableFileName)
    );
end;

procedure TFileAssociationServiceTests.ProvidesFriendlyApplicationName;
begin
    AssertEquals('Markdown Editor', MarkdownEditorApplicationName);
end;

initialization
    RegisterTest(TFileAssociationServiceTests);

end.
