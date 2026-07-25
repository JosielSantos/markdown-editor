unit Markdown_Memo;

{$MODE objfpc}
{$H+}

interface

uses
    LMessages,
    StdCtrls;

type
    TMarkdownMemo = class(TMemo)
    protected
        procedure WndProc(var Message: TLMessage); override;
    end;

implementation

uses
    Clipbrd,
    Clipboard_Text;

procedure TMarkdownMemo.WndProc(var Message: TLMessage);
begin
    if (Message.Msg = LM_PASTE) and not ReadOnly and Clipboard.HasFormat(CF_TEXT) then
    begin
        SelText := NormalizeClipboardLineBreaks(Clipboard.AsText);
        Message.Result := 1;
        Exit;
    end;
    inherited WndProc(Message);
end;

end.
