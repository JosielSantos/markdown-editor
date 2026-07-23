unit Lsp_Diagnostics;

{$MODE objfpc}
{$H+}

interface

type
    TLspDiagnosticSeverity = (ldsNone, ldsWarning, ldsError);

    TLspDiagnostic = record
        LineNumber: Integer;
        MessageText: string;
        Severity: TLspDiagnosticSeverity;
    end;

    TLspDiagnosticArray = array of TLspDiagnostic;

function ParsePublishDiagnostics(
    const JsonText: string;
    out DocumentUri: string;
    out Diagnostics: TLspDiagnosticArray
): Boolean;
function HighestSeverityAtLine(const Diagnostics: TLspDiagnosticArray; LineNumber: Integer): TLspDiagnosticSeverity;

implementation

uses
    fpjson,
    jsonparser;

function ConvertSeverity(SeverityValue: Integer): TLspDiagnosticSeverity;
begin
    case SeverityValue of
        1: Result := ldsError;
        2: Result := ldsWarning;
    else
        Result := ldsNone;
    end;
end;

function ParseDiagnostic(Item: TJSONData; out Diagnostic: TLspDiagnostic): Boolean;
var
    LineValue: TJSONData;
    MessageValue: TJSONData;
    RangeValue: TJSONData;
    SeverityValue: TJSONData;
    StartValue: TJSONData;
begin
    Result := False;
    if Item.JSONType <> jtObject then
        Exit;
    SeverityValue := TJSONObject(Item).Find('severity');
    MessageValue := TJSONObject(Item).Find('message');
    RangeValue := TJSONObject(Item).Find('range');
    if not Assigned(SeverityValue) or not Assigned(RangeValue) or (RangeValue.JSONType <> jtObject) then
        Exit;
    Diagnostic.Severity := ConvertSeverity(SeverityValue.AsInteger);
    if Diagnostic.Severity = ldsNone then
        Exit;
    StartValue := TJSONObject(RangeValue).Find('start');
    if not Assigned(StartValue) or (StartValue.JSONType <> jtObject) then
        Exit;
    LineValue := TJSONObject(StartValue).Find('line');
    if not Assigned(LineValue) then
        Exit;
    Diagnostic.LineNumber := LineValue.AsInteger + 1;
    if Assigned(MessageValue) then
        Diagnostic.MessageText := MessageValue.AsString
    else
        Diagnostic.MessageText := '';
    Result := Diagnostic.LineNumber > 0;
end;

function ParsePublishDiagnostics(
    const JsonText: string;
    out DocumentUri: string;
    out Diagnostics: TLspDiagnosticArray
): Boolean;
var
    Diagnostic: TLspDiagnostic;
    DiagnosticItems: TJSONArray;
    ItemIndex: Integer;
    JsonData: TJSONData;
    MethodValue: TJSONData;
    Parameters: TJSONData;
    UriValue: TJSONData;
begin
    Result := False;
    DocumentUri := '';
    SetLength(Diagnostics, 0);
    JsonData := GetJSON(JsonText);
    try
        if JsonData.JSONType <> jtObject then
            Exit;
        MethodValue := TJSONObject(JsonData).Find('method');
        if not Assigned(MethodValue) or (MethodValue.AsString <> 'textDocument/publishDiagnostics') then
            Exit;
        Parameters := TJSONObject(JsonData).Find('params');
        if not Assigned(Parameters) or (Parameters.JSONType <> jtObject) then
            Exit;
        UriValue := TJSONObject(Parameters).Find('uri');
        if not Assigned(UriValue) then
            Exit;
        DocumentUri := UriValue.AsString;
        Parameters := TJSONObject(Parameters).Find('diagnostics');
        if not Assigned(Parameters) or (Parameters.JSONType <> jtArray) then
            Exit;
        DiagnosticItems := TJSONArray(Parameters);
        for ItemIndex := 0 to DiagnosticItems.Count - 1 do
            if ParseDiagnostic(DiagnosticItems.Items[ItemIndex], Diagnostic) then
            begin
                SetLength(Diagnostics, Length(Diagnostics) + 1);
                Diagnostics[High(Diagnostics)] := Diagnostic;
            end;
        Result := True;
    finally
        JsonData.Free;
    end;
end;

function HighestSeverityAtLine(const Diagnostics: TLspDiagnosticArray; LineNumber: Integer): TLspDiagnosticSeverity;
var
    Diagnostic: TLspDiagnostic;
begin
    Result := ldsNone;
    for Diagnostic in Diagnostics do
        if Diagnostic.LineNumber = LineNumber then
        begin
            if Diagnostic.Severity = ldsError then
                Exit(ldsError);
            if Diagnostic.Severity = ldsWarning then
                Result := ldsWarning;
        end;
end;

end.
