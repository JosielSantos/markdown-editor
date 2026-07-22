unit Files;

{$MODE objfpc}
{$H+}

interface

function ReadUtf8TextFile(const FileName: string): string;
procedure WriteUtf8TextFile(const FileName, Content: string);

implementation

uses
    Classes,
    SysUtils;

function ReadUtf8TextFile(const FileName: string): string;
var
    FileStream: TFileStream;
begin
    Result := '';
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    try
        SetLength(Result, FileStream.Size);
        if FileStream.Size > 0 then
            FileStream.ReadBuffer(Result[1], FileStream.Size);
    finally
        FileStream.Free;
    end;

    if Copy(Result, 1, 3) = #$EF#$BB#$BF then
        Delete(Result, 1, 3);
end;

procedure WriteUtf8TextFile(const FileName, Content: string);
var
    FileStream: TFileStream;
begin
    FileStream := TFileStream.Create(FileName, fmCreate);
    try
        if Content <> '' then
            FileStream.WriteBuffer(Content[1], Length(Content));
    finally
        FileStream.Free;
    end;
end;

end.
