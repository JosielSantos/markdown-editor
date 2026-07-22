unit Html_Export_Dialog;

{$MODE objfpc}
{$H+}

interface

uses
    Classes;

function ChooseHtmlExportFile(Owner: TComponent; const MarkdownFileName: string; out HtmlFileName: string): Boolean;

implementation

uses
    Dialogs,
    Html_Export;

function ChooseHtmlExportFile(Owner: TComponent; const MarkdownFileName: string; out HtmlFileName: string): Boolean;
var
    ExportDialog: TSaveDialog;
begin
    ExportDialog := TSaveDialog.Create(Owner);
    try
        ExportDialog.Title := 'Exportar documento como HTML';
        ExportDialog.Filter := 'Arquivo HTML|*.html;*.htm|Todos os arquivos|*.*';
        ExportDialog.DefaultExt := 'html';
        ExportDialog.Options := [ofOverwritePrompt, ofEnableSizing];
        if MarkdownFileName = '' then
            ExportDialog.FileName := 'documento.html'
        else
            ExportDialog.FileName := HtmlExportFileName(MarkdownFileName);
        Result := ExportDialog.Execute;
        if Result then
            HtmlFileName := ExportDialog.FileName;
    finally
        ExportDialog.Free;
    end;
end;

end.
