unit Document_State;

{$MODE objfpc}
{$H+}

interface

function HasContentChanged(const CurrentContent, SavedContent: string): Boolean;

implementation

function HasContentChanged(const CurrentContent, SavedContent: string): Boolean;
begin
    Result := CurrentContent <> SavedContent;
end;

end.
