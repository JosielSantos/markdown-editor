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

if (-not (Test-Path $markdownPackage)) {
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
        "--pcp=$configDirectory" "--build-mode=$Mode" `
        'markdown_editor.lpi'
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}
