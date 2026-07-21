unit Markdown_Renderer;

{$mode objfpc}{$H+}

interface

function MarkdownToHtml(const Markdown: string): string;
function MarkdownToAccessibleText(const Markdown: string): string;

implementation

uses
  Classes, Markdown_Inline, StrUtils, SysUtils;

type
  TListKind = (lkNone, lkUnordered, lkOrdered);

function HeadingLevel(const Line: string): Integer;
begin
  Result := 0;
  while (Result < Length(Line)) and (Line[Result + 1] = '#') do
    Inc(Result);
  if (Result > 6) or (Result = Length(Line)) or
    (Line[Result + 1] <> ' ') then
    Result := 0;
end;

function OrderedItemStart(const Line: string): SizeInt;
var
  Position: SizeInt;
begin
  Result := 0;
  Position := 1;
  while (Position <= Length(Line)) and (Line[Position] in ['0'..'9']) do
    Inc(Position);
  if (Position > 1) and (Copy(Line, Position, 2) = '. ') then
    Result := Position + 2;
end;

function IsHorizontalRule(const Line: string): Boolean;
var
  TrimmedLine: string;
begin
  TrimmedLine := Trim(Line);
  Result := (TrimmedLine = '---') or (TrimmedLine = '***') or
    (TrimmedLine = '___');
end;

function SafeLanguageName(const Value: string): string;
var
  Character: Char;
begin
  Result := '';
  for Character in Value do
    if Character in ['a'..'z', 'A'..'Z', '0'..'9', '-', '_'] then
      Result := Result + Character;
end;

function RenderBlocks(const Markdown: string; AsHtml: Boolean): string;
var
  CodeBuffer: TStringList;
  CodeLanguage: string;
  CurrentList: TListKind;
  Heading: Integer;
  InCodeBlock: Boolean;
  Line: string;
  LineIndex: Integer;
  Lines: TStringList;
  ListItemStart: SizeInt;
  Output: TStringList;
  Paragraph: string;

  procedure CloseList;
  begin
    if AsHtml then
      case CurrentList of
        lkUnordered: Output.Add('</ul>');
        lkOrdered: Output.Add('</ol>');
      end;
    CurrentList := lkNone;
  end;

  procedure FlushParagraph;
  begin
    if Paragraph = '' then
      Exit;
    if AsHtml then
      Output.Add('<p>' + RenderInlineHtml(Paragraph) + '</p>')
    else
    begin
      Output.Add(RenderInlineText(Paragraph));
      Output.Add('');
    end;
    Paragraph := '';
  end;

  procedure StartList(NewKind: TListKind);
  begin
    FlushParagraph;
    if CurrentList = NewKind then
      Exit;
    CloseList;
    CurrentList := NewKind;
    if AsHtml then
      if NewKind = lkUnordered then
        Output.Add('<ul>')
      else
        Output.Add('<ol>');
  end;

  procedure FinishCodeBlock;
  var
    LanguageAttribute: string;
  begin
    if AsHtml then
    begin
      LanguageAttribute := SafeLanguageName(CodeLanguage);
      if LanguageAttribute <> '' then
        LanguageAttribute := ' class="language-' + LanguageAttribute + '"';
      Output.Add('<pre><code' + LanguageAttribute + '>' +
        EscapeHtml(CodeBuffer.Text) + '</code></pre>');
    end
    else
    begin
      Output.Add('Bloco de código:');
      Output.Add(CodeBuffer.Text);
    end;
    CodeBuffer.Clear;
    CodeLanguage := '';
    InCodeBlock := False;
  end;

begin
  Lines := TStringList.Create;
  Output := TStringList.Create;
  CodeBuffer := TStringList.Create;
  try
    Lines.Text := StringReplace(Markdown, #13#10, #10, [rfReplaceAll]);
    CurrentList := lkNone;
    InCodeBlock := False;
    Paragraph := '';

    for LineIndex := 0 to Lines.Count - 1 do
    begin
      Line := Lines[LineIndex];
      if StartsStr('```', TrimLeft(Line)) then
      begin
        if InCodeBlock then
          FinishCodeBlock
        else
        begin
          FlushParagraph;
          CloseList;
          InCodeBlock := True;
          CodeLanguage := Trim(Copy(TrimLeft(Line), 4, MaxInt));
        end;
        Continue;
      end;

      if InCodeBlock then
      begin
        CodeBuffer.Add(Line);
        Continue;
      end;

      if Trim(Line) = '' then
      begin
        FlushParagraph;
        CloseList;
        Continue;
      end;

      Heading := HeadingLevel(Line);
      if Heading > 0 then
      begin
        FlushParagraph;
        CloseList;
        if AsHtml then
          Output.Add(Format('<h%d>%s</h%d>', [Heading,
            RenderInlineHtml(Copy(Line, Heading + 2, MaxInt)), Heading]))
        else
        begin
          Output.Add(Format('Título nível %d: %s', [Heading,
            RenderInlineText(Copy(Line, Heading + 2, MaxInt))]));
          Output.Add('');
        end;
        Continue;
      end;

      if IsHorizontalRule(Line) then
      begin
        FlushParagraph;
        CloseList;
        if AsHtml then
          Output.Add('<hr>')
        else
          Output.Add('Separador');
        Continue;
      end;

      if StartsStr('> ', Line) then
      begin
        FlushParagraph;
        CloseList;
        if AsHtml then
          Output.Add('<blockquote><p>' +
            RenderInlineHtml(Copy(Line, 3, MaxInt)) + '</p></blockquote>')
        else
          Output.Add('Citação: ' + RenderInlineText(Copy(Line, 3, MaxInt)));
        Continue;
      end;

      if (Length(Line) >= 2) and (Line[1] in ['-', '*', '+']) and
        (Line[2] = ' ') then
      begin
        StartList(lkUnordered);
        if AsHtml then
          Output.Add('<li>' + RenderInlineHtml(Copy(Line, 3, MaxInt)) + '</li>')
        else
          Output.Add('Item: ' + RenderInlineText(Copy(Line, 3, MaxInt)));
        Continue;
      end;

      ListItemStart := OrderedItemStart(Line);
      if ListItemStart > 0 then
      begin
        StartList(lkOrdered);
        if AsHtml then
          Output.Add('<li>' + RenderInlineHtml(
            Copy(Line, ListItemStart, MaxInt)) + '</li>')
        else
          Output.Add('Item numerado: ' + RenderInlineText(
            Copy(Line, ListItemStart, MaxInt)));
        Continue;
      end;

      CloseList;
      if Paragraph <> '' then
        Paragraph := Paragraph + ' ';
      Paragraph := Paragraph + Trim(Line);
    end;

    if InCodeBlock then
      FinishCodeBlock;
    FlushParagraph;
    CloseList;
    Result := Output.Text;
  finally
    CodeBuffer.Free;
    Output.Free;
    Lines.Free;
  end;
end;

function MarkdownToHtml(const Markdown: string): string;
const
  DocumentStart = '<!doctype html>' + LineEnding +
    '<html lang="pt-BR"><head><meta charset="utf-8">' + LineEnding +
    '<meta name="viewport" content="width=device-width, initial-scale=1">' +
    LineEnding + '<title>Documento Markdown</title>' + LineEnding +
    '<style>body{font-family:Segoe UI,sans-serif;line-height:1.6;' +
    'max-width:75ch;margin:2rem auto;padding:0 1rem}' +
    'pre,code{font-family:Consolas,monospace}pre{padding:1rem;' +
    'overflow:auto;background:#eee}blockquote{border-left:.25rem solid #777;' +
    'margin-left:0;padding-left:1rem}a{color:#0645ad}</style></head><body>' +
    LineEnding;
begin
  Result := DocumentStart + RenderBlocks(Markdown, True) +
    '</body></html>' + LineEnding;
end;

function MarkdownToAccessibleText(const Markdown: string): string;
begin
  Result := TrimRight(RenderBlocks(Markdown, False));
end;

end.

