param(
    [ValidateSet('Debug', 'Release')]
    [string] $Mode = 'Release'
)

. (Join-Path $PSScriptRoot 'common.ps1')

$projectRoot = Split-Path $PSScriptRoot -Parent
$lazbuild = Resolve-Lazbuild
$lazarusDirectory = Split-Path $lazbuild -Parent
$configDirectory = Join-Path $projectRoot '.lazarus'
$markdownPackage = Join-Path $projectRoot `
    'vendor\delphi-markdown\packages\markdownengine.lpk'
$webViewPackage = Join-Path $projectRoot `
    'vendor\webview4delphi\packages\webview4delphi.lpk'
$argumentParserPackage = Join-Path $projectRoot `
    'vendor\argparser-fp\packages\lazarus\argparser_fp.lpk'
$webViewLoader = Join-Path $projectRoot `
    'vendor\webview4delphi\bin64\WebView2Loader.dll'
$webViewUnitOutput = Join-Path $projectRoot `
    'vendor\webview4delphi\packages\lib'

if (-not (Test-Path $markdownPackage) -or
    -not (Test-Path $webViewPackage) -or
    -not (Test-Path $argumentParserPackage) -or
    -not (Test-Path $webViewLoader)) {
    throw 'Dependência ausente. Execute: git submodule update --init'
}

Push-Location $projectRoot
try {
    & $lazbuild "--lazarusdir=$lazarusDirectory" `
        "--pcp=$configDirectory" '--add-package-link' $markdownPackage
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    & $lazbuild "--lazarusdir=$lazarusDirectory" `
        "--pcp=$configDirectory" '--add-package-link' $webViewPackage
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    & $lazbuild "--lazarusdir=$lazarusDirectory" `
        "--pcp=$configDirectory" '--add-package-link' $argumentParserPackage
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    & $lazbuild "--lazarusdir=$lazarusDirectory" `
        "--pcp=$configDirectory" "--build-mode=$Mode" `
        'markdown_editor.lpi'
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    Copy-Item $webViewLoader `
        (Join-Path $projectRoot 'bin\WebView2Loader.dll') -Force
} finally {
    Pop-Location
    if (Test-Path $webViewUnitOutput) {
        Remove-Item $webViewUnitOutput -Recurse -Force
    }
}
