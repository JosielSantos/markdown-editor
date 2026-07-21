unit Link_Navigation;

{$MODE objfpc}
{$H+}

interface

const
    MarkdownEditorScheme = 'mdeditor';
    MarkdownEditorSchemePrefix = MarkdownEditorScheme + '://';

type
    TLinkNavigationAction = (lnaKeepInPreview, lnaOpenExternally, lnaBlock);

function ClassifyNavigation(const Uri: string): TLinkNavigationAction;

implementation

uses
    StrUtils,
    SysUtils;

function ClassifyNavigation(const Uri: string): TLinkNavigationAction;
var
    NormalizedUri: string;
begin
    NormalizedUri := Trim(Uri);
    if StartsText(MarkdownEditorSchemePrefix, NormalizedUri)
        or StartsText('#', NormalizedUri)
        or StartsText('about:blank#', NormalizedUri) then
        Exit(lnaKeepInPreview);
    if StartsText('http://', NormalizedUri)
        or StartsText('https://', NormalizedUri)
        or StartsText('mailto:', NormalizedUri) then
        Exit(lnaOpenExternally);
    Result := lnaBlock;
end;

end.
