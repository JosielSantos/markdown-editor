unit Link;

{$MODE objfpc}
{$H+}

interface

function BuildMarkdownLink(const LinkTitle, LinkAddress: string): string;

implementation

function BuildMarkdownLink(const LinkTitle, LinkAddress: string): string;
begin
    Result := '[' + LinkTitle + '](' + LinkAddress + ')';
end;

end.
