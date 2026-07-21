unit Preview_Form;

{$MODE objfpc}
{$H+}

interface

uses
    ActiveX,
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
        procedure BrowserNavigationStarting(
            Sender: TObject;
            const WebView: ICoreWebView2;
            const Args: ICoreWebView2NavigationStartingEventArgs
        );
        procedure BrowserNewWindowRequested(
            Sender: TObject;
            const WebView: ICoreWebView2;
            const Args: ICoreWebView2NewWindowRequestedEventArgs
        );
        procedure BrowserWebResourceRequested(
            Sender: TObject;
            const WebView: ICoreWebView2;
            const Args: ICoreWebView2WebResourceRequestedEventArgs
        );
        procedure CheckWebViewInitialization(Sender: TObject);
        procedure CloseWithEscape(Sender: TObject; var Key: Word; Shift: TShiftState);
        procedure OpenExternalLink(const Uri: string);
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
    Link_Navigation,
    Markdown_Renderer,
    SysUtils,
    uWVCoreWebView2Args,
    uWVCoreWebView2WebResourceRequest,
    uWVLoader;

const
    PreviewDocumentUri = MarkdownEditorSchemePrefix + 'preview/';

procedure RegisterMarkdownEditorScheme(Sender: TObject; var CustomSchemes: TWVCustomSchemeInfoArray);
begin
    SetLength(CustomSchemes, 1);
    CustomSchemes[0].SchemeName := MarkdownEditorScheme;
    CustomSchemes[0].TreatAsSecure := True;
    CustomSchemes[0].AllowedDomains := '';
    CustomSchemes[0].HasAuthorityComponent := True;
end;

procedure StartWebViewRuntime;
begin
    if Assigned(GlobalWebView2Loader) then
        Exit;
    GlobalWebView2Loader := TWVLoader.Create(nil);
    GlobalWebView2Loader.UserDataFolder :=
        UTF8Decode(IncludeTrailingPathDelimiter(GetAppConfigDir(False)) + 'webview2');
    GlobalWebView2Loader.OnGetCustomSchemes := @RegisterMarkdownEditorScheme;
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
    Browser.OnNavigationStarting := @BrowserNavigationStarting;
    Browser.OnNewWindowRequested := @BrowserNewWindowRequested;
    Browser.OnWebResourceRequested := @BrowserWebResourceRequested;

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

procedure TPreviewForm.BrowserNavigationStarting(
    Sender: TObject;
    const WebView: ICoreWebView2;
    const Args: ICoreWebView2NavigationStartingEventArgs
);
var
    NavigationArgs: TCoreWebView2NavigationStartingEventArgs;
    Uri: string;
begin
    NavigationArgs := TCoreWebView2NavigationStartingEventArgs.Create(Args);
    try
        Uri := UTF8Encode(NavigationArgs.URI);
        case ClassifyNavigation(Uri) of
            lnaKeepInPreview: Exit;
            lnaOpenExternally:
            begin
                NavigationArgs.Cancel := True;
                OpenExternalLink(Uri);
            end;
            lnaBlock: NavigationArgs.Cancel := True;
        end;
    finally
        NavigationArgs.Free;
    end;
end;

procedure TPreviewForm.BrowserNewWindowRequested(
    Sender: TObject;
    const WebView: ICoreWebView2;
    const Args: ICoreWebView2NewWindowRequestedEventArgs
);
var
    NewWindowArgs: TCoreWebView2NewWindowRequestedEventArgs;
    Uri: string;
begin
    NewWindowArgs := TCoreWebView2NewWindowRequestedEventArgs.Create(Args);
    try
        NewWindowArgs.Handled := True;
        Uri := UTF8Encode(NewWindowArgs.URI);
        case ClassifyNavigation(Uri) of
            lnaKeepInPreview: Browser.Navigate(UTF8Decode(Uri));
            lnaOpenExternally: OpenExternalLink(Uri);
            lnaBlock: Exit;
        end;
    finally
        NewWindowArgs.Free;
    end;
end;

procedure TPreviewForm.BrowserWebResourceRequested(
    Sender: TObject;
    const WebView: ICoreWebView2;
    const Args: ICoreWebView2WebResourceRequestedEventArgs
);
var
    RequestArgs: TCoreWebView2WebResourceRequestedEventArgs;
    Request: TCoreWebView2WebResourceRequestRef;
    Response: ICoreWebView2WebResourceResponse;
    HtmlStream: TStringStream;
    StreamAdapter: IStream;
begin
    Response := nil;
    StreamAdapter := nil;
    RequestArgs := TCoreWebView2WebResourceRequestedEventArgs.Create(Args);
    Request := TCoreWebView2WebResourceRequestRef.Create(RequestArgs.Request);
    try
        if SameText(UTF8Encode(Request.URI), PreviewDocumentUri) then
        begin
            HtmlStream := TStringStream.Create(HtmlDocument);
            StreamAdapter := TStreamAdapter.Create(HtmlStream, soOwned);
            Browser.CoreWebView2Environment.CreateWebResourceResponse(
                StreamAdapter,
                200,
                'OK',
                'Content-Type: text/html; charset=utf-8',
                Response
            );
        end
        else
            Browser.CoreWebView2Environment.CreateWebResourceResponse(nil, 404, 'Not Found', '', Response);
        RequestArgs.Response := Response;
    finally
        StreamAdapter := nil;
        Response := nil;
        Request.Free;
        RequestArgs.Free;
    end;
end;

procedure TPreviewForm.BrowserAfterCreated(Sender: TObject);
begin
    Browser.DefaultContextMenusEnabled := False;
    Browser.DevToolsEnabled := False;
    Browser.ScriptEnabled := False;
    BrowserHost.UpdateSize;
    Browser.AddWebResourceRequestedFilterWithRequestSourceKinds(
        MarkdownEditorScheme + '*',
        COREWEBVIEW2_WEB_RESOURCE_CONTEXT_ALL,
        COREWEBVIEW2_WEB_RESOURCE_REQUEST_SOURCE_KINDS_ALL
    );
    Browser.Navigate(UTF8Decode(PreviewDocumentUri));
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

procedure TPreviewForm.OpenExternalLink(const Uri: string);
begin
    if not LCLIntf.OpenURL(Uri) then
        LCLIntf.MessageBox(
            Handle,
            'O Windows não conseguiu abrir o link no aplicativo padrão.',
            'Não foi possível abrir o link',
            MB_OK or MB_ICONERROR
        );
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
