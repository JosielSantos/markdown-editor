unit Files;

{$MODE objfpc}
{$H+}

interface

uses
    Document_State,
    SysUtils;

type
    ETextEncodingError = class(Exception);

function ReadTextFile(const FileName: string; out Encoding: TDocumentEncoding): string;
procedure WriteTextFile(const FileName, Content: string; const Encoding: TDocumentEncoding);
function ReadUtf8TextFile(const FileName: string): string;
procedure WriteUtf8TextFile(const FileName, Content: string);

implementation

uses
    Classes,
    LConvEncoding;

const
    ENCODING_ISO_8859_1 = 'iso88591';
    ENCODING_WINDOWS_1252 = 'cp1252';
    UTF8_BOM = #$EF#$BB#$BF;

function ReadFileBytes(const FileName: string): string;
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

end;

function ContainsWindows1252Characters(const Content: string): Boolean;
const
    WINDOWS_1252_CHARACTERS: set of Byte =
        [
            $80,
            $82,
            $83,
            $84,
            $85,
            $86,
            $87,
            $88,
            $89,
            $8A,
            $8B,
            $8C,
            $8E,
            $91,
            $92,
            $93,
            $94,
            $95,
            $96,
            $97,
            $98,
            $99,
            $9A,
            $9B,
            $9C,
            $9E,
            $9F
        ];
var
    CharacterIndex: Integer;
begin
    for CharacterIndex := 1 to Length(Content) do
        if Byte(Content[CharacterIndex]) in WINDOWS_1252_CHARACTERS then
            Exit(True);
    Result := False;
end;

function DetectEncoding(const Content: string): string;
begin
    if Content = '' then
        Exit(DOCUMENT_ENCODING_UTF8);
    Result := NormalizeEncoding(GuessEncoding(Content));
    if (Result = ENCODING_WINDOWS_1252) and not ContainsWindows1252Characters(Content) then
        Result := ENCODING_ISO_8859_1;
end;

function ReadTextFile(const FileName: string; out Encoding: TDocumentEncoding): string;
var
    FileContent: string;
begin
    FileContent := ReadFileBytes(FileName);
    Encoding.HasUtf8Bom := Copy(FileContent, 1, Length(UTF8_BOM)) = UTF8_BOM;
    if Encoding.HasUtf8Bom then
    begin
        Encoding.Name := DOCUMENT_ENCODING_UTF8;
        Delete(FileContent, 1, Length(UTF8_BOM));
    end
    else
        Encoding.Name := DetectEncoding(FileContent);
    Result := ConvertEncoding(FileContent, Encoding.Name, DOCUMENT_ENCODING_UTF8);
end;

procedure WriteFileBytes(const FileName, Content: string);
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

procedure WriteTextFile(const FileName, Content: string; const Encoding: TDocumentEncoding);
var
    EncodedContent: string;
    NormalizedEncoding: string;
begin
    NormalizedEncoding := NormalizeEncoding(Encoding.Name);
    EncodedContent := ConvertEncoding(Content, DOCUMENT_ENCODING_UTF8, NormalizedEncoding);
    if ConvertEncoding(EncodedContent, NormalizedEncoding, DOCUMENT_ENCODING_UTF8) <> Content then
        raise ETextEncodingError
            .CreateFmt('O conteúdo possui caracteres que não podem ser representados em %s.', [Encoding.Name]);
    if Encoding.HasUtf8Bom and (NormalizedEncoding = DOCUMENT_ENCODING_UTF8) then
        EncodedContent := UTF8_BOM + EncodedContent;
    WriteFileBytes(FileName, EncodedContent);
end;

function ReadUtf8TextFile(const FileName: string): string;
var
    Encoding: TDocumentEncoding;
begin
    Result := ReadTextFile(FileName, Encoding);
end;

procedure WriteUtf8TextFile(const FileName, Content: string);
var
    Encoding: TDocumentEncoding;
begin
    Encoding.Name := DOCUMENT_ENCODING_UTF8;
    Encoding.HasUtf8Bom := False;
    WriteTextFile(FileName, Content, Encoding);
end;

end.
