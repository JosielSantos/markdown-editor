param(
    [Parameter(Mandatory)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string] $Version,

    [string] $ProjectRoot = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
$utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)

function Update-VersionReference {
    param(
        [string] $Path,
        [string] $Pattern,
        [string] $Replacement
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Arquivo não encontrado: $Path"
    }

    $content = [System.IO.File]::ReadAllText($Path)
    $matchCount = [regex]::Matches($content, $Pattern).Count
    if ($matchCount -ne 1) {
        throw "Esperada uma referência de versão em $Path; encontradas: $matchCount"
    }

    $updatedContent = [regex]::Replace($content, $Pattern, $Replacement)
    if ($updatedContent -ne $content) {
        [System.IO.File]::WriteAllText($Path, $updatedContent, $utf8WithoutBom)
    }
}

$installerScript = Join-Path $ProjectRoot 'installer\markdown-editor.iss'
$readme = Join-Path $ProjectRoot 'README.md'

Update-VersionReference `
    -Path $installerScript `
    -Pattern '(?m)^#define AppVersion "\d+\.\d+\.\d+"$' `
    -Replacement "#define AppVersion `"$Version`""
Update-VersionReference `
    -Path $readme `
    -Pattern 'markdown-editor-\d+\.\d+\.\d+-setup\.exe' `
    -Replacement "markdown-editor-$Version-setup.exe"
Update-VersionReference `
    -Path $readme `
    -Pattern 'markdown-editor-\d+\.\d+\.\d+-portable\.zip' `
    -Replacement "markdown-editor-$Version-portable.zip"

Write-Host "Versão atualizada para $Version."
