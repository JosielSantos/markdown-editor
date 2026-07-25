unit Clipboard_Text;

{$MODE objfpc}
{$H+}

interface

function NormalizeClipboardLineBreaks(const Text: string): string;

implementation

uses
    SysUtils;

function NormalizeClipboardLineBreaks(const Text: string): string;
begin
    Result := AdjustLineBreaks(Text, tlbsCRLF);
end;

end.
