unit Link_Navigation;

{$MODE objfpc}
{$H+}

interface

type
    TLinkNavigationAction = (lnaKeepInPreview, lnaOpenExternally, lnaBlock);

function ClassifyNavigation(const Uri: string; IsPreviewDocument: Boolean): TLinkNavigationAction;

implementation

uses
    StrUtils,
    SysUtils;

function ClassifyNavigation(const Uri: string; IsPreviewDocument: Boolean): TLinkNavigationAction;
var
    NormalizedUri: string;
begin
    if IsPreviewDocument then
        Exit(lnaKeepInPreview);
    NormalizedUri := Trim(Uri);
    if StartsText('#', NormalizedUri) or StartsText('about:blank#', NormalizedUri) then
        Exit(lnaKeepInPreview);
    if StartsText('http://', NormalizedUri)
        or StartsText('https://', NormalizedUri)
        or StartsText('mailto:', NormalizedUri) then
        Exit(lnaOpenExternally);
    Result := lnaBlock;
end;

end.
