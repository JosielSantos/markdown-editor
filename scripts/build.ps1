param(
    [ValidateSet('Debug', 'Release')]
    [string] $Mode = 'Release'
)

. (Join-Path $PSScriptRoot 'common.ps1')

$projectRoot = Split-Path $PSScriptRoot -Parent
$lazbuild = Resolve-Lazbuild
$lazarusDirectory = Split-Path $lazbuild -Parent
$configDirectory = Join-Path $projectRoot '.lazarus'

Push-Location $projectRoot
try {
    & $lazbuild "--lazarusdir=$lazarusDirectory" `
        "--pcp=$configDirectory" "--build-mode=$Mode" `
        'markdown_editor.lpi'
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}

