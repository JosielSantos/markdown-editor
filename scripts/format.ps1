param(
    [switch] $Check,
    [string] $PasfmtPath = 'pasfmt'
)

$pasfmtCommand = Get-Command $PasfmtPath -ErrorAction SilentlyContinue
if ($null -eq $pasfmtCommand) {
    throw 'pasfmt não encontrado. Instale a versão 0.7.0 ou posterior.'
}

$projectRoot = Split-Path $PSScriptRoot -Parent
$mode = if ($Check) { 'check' } else { 'files' }
$sourcePaths = @('markdown_editor.lpr', 'src', 'tests')

Push-Location $projectRoot
try {
    & $pasfmtCommand.Source '--mode' $mode $sourcePaths
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}
