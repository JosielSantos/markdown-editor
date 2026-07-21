unit Preview_Form;

{$mode objfpc}{$H+}

interface

uses
  Classes, ComCtrls, Forms, IpHtml, StdCtrls;

type
  TPreviewForm = class(TForm)
  private
    AccessibleMemo: TMemo;
    HtmlPanel: TIpHtmlPanel;
    PreviewPages: TPageControl;
    procedure CloseWithEscape(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure CreateAccessibleView;
    procedure CreateVisualView;
  public
    constructor Create(TheOwner: TComponent); override;
    procedure ShowMarkdown(const Markdown: string);
  end;

implementation

uses
  Controls, LCLType, Markdown_Renderer;

procedure TPreviewForm.CreateVisualView;
var
  VisualTab: TTabSheet;
begin
  VisualTab := TTabSheet.Create(Self);
  VisualTab.Caption := 'Visualização';
  VisualTab.PageControl := PreviewPages;

  HtmlPanel := TIpHtmlPanel.Create(Self);
  HtmlPanel.Parent := VisualTab;
  HtmlPanel.Align := alClient;
  HtmlPanel.TabStop := True;
  HtmlPanel.AccessibleName := 'Documento Markdown renderizado';
  HtmlPanel.AccessibleDescription :=
    'Visualização formatada. Use a guia Texto acessível com leitor de tela.';
end;

procedure TPreviewForm.CreateAccessibleView;
var
  AccessibleTab: TTabSheet;
begin
  AccessibleTab := TTabSheet.Create(Self);
  AccessibleTab.Caption := 'Texto acessível';
  AccessibleTab.PageControl := PreviewPages;

  AccessibleMemo := TMemo.Create(Self);
  AccessibleMemo.Parent := AccessibleTab;
  AccessibleMemo.Align := alClient;
  AccessibleMemo.ReadOnly := True;
  AccessibleMemo.ScrollBars := ssAutoBoth;
  AccessibleMemo.WordWrap := True;
  AccessibleMemo.AccessibleName := 'Conteúdo Markdown em texto estruturado';
  AccessibleMemo.AccessibleDescription :=
    'Versão somente leitura otimizada para leitor de tela.';
  AccessibleMemo.AccessibleRole := larTextEditorMultiline;
end;

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

  PreviewPages := TPageControl.Create(Self);
  PreviewPages.Parent := Self;
  PreviewPages.Align := alClient;
  PreviewPages.AccessibleName := 'Modos de visualização';
  PreviewPages.AccessibleDescription :=
    'Use Control mais Tab para alternar entre visual e texto acessível.';
  CreateVisualView;
  CreateAccessibleView;
  PreviewPages.ActivePageIndex := 0;
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
  AccessibleMemo.Text := MarkdownToAccessibleText(Markdown);
  ShowModal;
end;

end.
