unit Preview_Form;

{$mode objfpc}{$H+}

interface

uses
  Classes, Forms, IpHtml;

type
  TPreviewForm = class(TForm)
  private
    HtmlPanel: TIpHtmlPanel;
    procedure CloseWithEscape(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  public
    constructor Create(TheOwner: TComponent); override;
    procedure ShowMarkdown(const Markdown: string);
  end;

implementation

uses
  Controls, LCLType, Markdown_Renderer;

constructor TPreviewForm.Create(TheOwner: TComponent);
begin
  inherited CreateNew(TheOwner, 1);
  Caption := 'Visualização do Markdown';
  Position := poOwnerFormCenter;
  Width := 820;
  Height := 620;
  BorderStyle := bsSizeable;
  KeyPreview := True;
  OnKeyDown := @CloseWithEscape;

  HtmlPanel := TIpHtmlPanel.Create(Self);
  HtmlPanel.Parent := Self;
  HtmlPanel.Align := alClient;
  HtmlPanel.TabStop := True;
  HtmlPanel.AccessibleName := 'Documento Markdown renderizado';
  HtmlPanel.AccessibleDescription := 'Visualização formatada somente leitura.';
end;

procedure TPreviewForm.CloseWithEscape(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    ModalResult := mrCancel;
    Key := 0;
  end;
end;

procedure TPreviewForm.ShowMarkdown(const Markdown: string);
begin
  HtmlPanel.SetHtmlFromStr(MarkdownToHtml(Markdown));
  ShowModal;
end;

end.


