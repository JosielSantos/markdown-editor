unit Preview_Form;

{$MODE objfpc}
{$H+}

interface

uses
    Classes,
    ExtCtrls,
    Forms,
    Windows,
    uWVBrowser,
    uWVTypeLibrary,
    uWVTypes,
    uWVWindowParent;

type
    TPreviewForm = class(TForm)
    private
        Browser: TWVBrowser;
        BrowserHost: TWVWindowParent;
        InitializationTimer: TTimer;
        HtmlDocument: string;
        ErrorShown: Boolean;
        procedure BrowserAfterCreated(Sender: TObject);
        procedure BrowserInitializationError(Sender: TObject; ErrorCode: HRESULT; const ErrorMessage: wvstring);
        procedure BrowserAcceleratorKeyPressed(
            Sender: TObject;
            const Controller: ICoreWebView2Controller;
            const Args: ICoreWebView2AcceleratorKeyPressedEventArgs
        );
        procedure CheckWebViewInitialization(Sender: TObject);
        procedure CloseWithEscape(Sender: TObject; var Key: Word; Shift: TShiftState);
        procedure ShowWebViewError(const Details: string);
        procedure StartBrowser(Sender: TObject);
        procedure WMMove(var Message: TWMMove); message WM_MOVE;
        procedure WMMoving(var Message: TMessage); message WM_MOVING;
    public
        constructor Create(TheOwner: TComponent); override;
        procedure ShowMarkdown(const Markdown: string);
    end;

implementation

uses
    Controls,
    LCLIntf,
    LCLType,
    Markdown_Renderer,
    SysUtils,
    uWVCoreWebView2Args,
    uWVLoader;

procedure StartWebViewRuntime;
begin
    if Assigned(GlobalWebView2Loader) then
        Exit;
    GlobalWebView2Loader := TWVLoader.Create(nil);
    GlobalWebView2Loader.UserDataFolder :=
        UTF8Decode(IncludeTrailingPathDelimiter(GetAppConfigDir(False)) + 'webview2');
    GlobalWebView2Loader.StartWebView2;
end;

constructor TPreviewForm.Create(TheOwner: TComponent);
begin
    inherited CreateNew(TheOwner, 1);
    StartWebViewRuntime;
    Caption := 'Visualização do Markdown';
    Position := poOwnerFormCenter;
    Width := 820;
    Height := 620;
    BorderStyle := bsSizeable;
    KeyPreview := True;
    OnKeyDown := @CloseWithEscape;
    OnShow := @StartBrowser;

    Browser := TWVBrowser.Create(Self);
    Browser.OnAfterCreated := @BrowserAfterCreated;
    Browser.OnInitializationError := @BrowserInitializationError;
    Browser.OnAcceleratorKeyPressed := @BrowserAcceleratorKeyPressed;

    BrowserHost := TWVWindowParent.Create(Self);
    BrowserHost.Parent := Self;
    BrowserHost.Align := alClient;
    BrowserHost.TabStop := True;
    BrowserHost.Browser := Browser;

    InitializationTimer := TTimer.Create(Self);
    InitializationTimer.Enabled := False;
    InitializationTimer.Interval := 100;
    InitializationTimer.OnTimer := @CheckWebViewInitialization;
end;

procedure TPreviewForm.BrowserAfterCreated(Sender: TObject);
begin
    Browser.DefaultContextMenusEnabled := False;
    Browser.DevToolsEnabled := False;
    Browser.ScriptEnabled := False;
    BrowserHost.UpdateSize;
    Browser.NavigateToString(UTF8Decode(HtmlDocument));
    BrowserHost.SetFocus;
end;

procedure TPreviewForm.BrowserInitializationError(Sender: TObject; ErrorCode: HRESULT; const ErrorMessage: wvstring);
begin
    ShowWebViewError(UTF8Encode(ErrorMessage));
end;

procedure TPreviewForm.BrowserAcceleratorKeyPressed(
    Sender: TObject;
    const Controller: ICoreWebView2Controller;
    const Args: ICoreWebView2AcceleratorKeyPressedEventArgs
);
var
    AcceleratorArgs: TCoreWebView2AcceleratorKeyPressedEventArgs;
begin
    AcceleratorArgs := TCoreWebView2AcceleratorKeyPressedEventArgs.Create(Args);
    try
        if AcceleratorArgs.VirtualKey = VK_ESCAPE then
        begin
            AcceleratorArgs.Handled := True;
            PostMessage(Handle, WM_CLOSE, 0, 0);
        end;
    finally
        AcceleratorArgs.Free;
    end;
end;

procedure TPreviewForm.CheckWebViewInitialization(Sender: TObject);
begin
    InitializationTimer.Enabled := False;
    if GlobalWebView2Loader.InitializationError then
        ShowWebViewError(UTF8Encode(GlobalWebView2Loader.ErrorMessage))
    else if GlobalWebView2Loader.Initialized then
        Browser.CreateBrowser(BrowserHost.Handle)
    else
        InitializationTimer.Enabled := True;
end;

procedure TPreviewForm.CloseWithEscape(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
    if Key = VK_ESCAPE then
    begin
        ModalResult := mrCancel;
        Key := 0;
    end;
end;

procedure TPreviewForm.ShowWebViewError(const Details: string);
var
    ErrorText: string;
begin
    if ErrorShown then
        Exit;
    ErrorShown := True;
    InitializationTimer.Enabled := False;
    ErrorText :=
        'Não foi possível abrir a visualização HTML.'
            + LineEnding
            + 'Instale ou atualize o Microsoft Edge WebView2 Runtime.';
    if Details <> '' then
        ErrorText := ErrorText + LineEnding + LineEnding + Details;
    LCLIntf.MessageBox(Handle, PChar(ErrorText), 'Visualização indisponível', MB_OK or MB_ICONERROR);
    ModalResult := mrCancel;
end;

procedure TPreviewForm.StartBrowser(Sender: TObject);
begin
    CheckWebViewInitialization(Sender);
end;

procedure TPreviewForm.WMMove(var Message: TWMMove);
begin
    inherited;
    if Assigned(Browser) then
        Browser.NotifyParentWindowPositionChanged;
end;

procedure TPreviewForm.WMMoving(var Message: TMessage);
begin
    inherited;
    if Assigned(Browser) then
        Browser.NotifyParentWindowPositionChanged;
end;

procedure TPreviewForm.ShowMarkdown(const Markdown: string);
begin
    HtmlDocument := MarkdownToHtml(Markdown);
    ShowModal;
end;

end.
