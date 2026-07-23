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

function Invoke-Lazbuild([string[]] $Arguments) {
    $output = @(& $lazbuild '--quiet' '--quiet' $Arguments 2>&1)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        foreach ($line in $output) {
            Write-Host $line
        }
        exit $exitCode
    }
}

if (-not (Test-Path $markdownPackage) -or
    -not (Test-Path $webViewPackage) -or
    -not (Test-Path $argumentParserPackage) -or
    -not (Test-Path $webViewLoader)) {
    throw 'Dependência ausente. Execute: git submodule update --init'
}

Push-Location $projectRoot
try {
    Invoke-Lazbuild @(
        "--lazarusdir=$lazarusDirectory",
        "--pcp=$configDirectory",
        '--add-package-link',
        $markdownPackage
    )
    Invoke-Lazbuild @(
        "--lazarusdir=$lazarusDirectory",
        "--pcp=$configDirectory",
        '--add-package-link',
        $webViewPackage
    )
    Invoke-Lazbuild @(
        "--lazarusdir=$lazarusDirectory",
        "--pcp=$configDirectory",
        '--add-package-link',
        $argumentParserPackage
    )
    Invoke-Lazbuild @(
        "--lazarusdir=$lazarusDirectory",
        "--pcp=$configDirectory",
        "--build-mode=$Mode",
        'markdown_editor.lpi'
    )

    Copy-Item $webViewLoader `
        (Join-Path $projectRoot 'bin\WebView2Loader.dll') -Force
    Write-Host "Build $Mode concluido."
} finally {
    Pop-Location
    if (Test-Path $webViewUnitOutput) {
        Remove-Item $webViewUnitOutput -Recurse -Force
    }
}
