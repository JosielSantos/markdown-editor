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
    public
        procedure PositionCursorAtLine(LineNumber: Integer);
    end;

implementation

uses
    Clipbrd,
    Clipboard_Text,
    Line_Navigation,
    Windows;

procedure TMarkdownMemo.PositionCursorAtLine(LineNumber: Integer);
var
    LineStart: LResult;
begin
    LineNumber := ClampLineNumber(LineNumber, Lines.Count);
    LineStart := Windows.SendMessage(Handle, EM_LINEINDEX, LineNumber - 1, 0);
    if LineStart < 0 then
        LineStart := 0;
    SelStart := LineStart;
end;

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
