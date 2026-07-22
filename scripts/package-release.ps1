param(
    [Parameter(Mandatory)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string] $Version,

    [string] $ProjectRoot = (Split-Path $PSScriptRoot -Parent),

    [string] $IsccPath
)

$ErrorActionPreference = 'Stop'

function Resolve-Iscc {
    if ($IsccPath) {
        if (-not (Test-Path -LiteralPath $IsccPath)) {
            throw "ISCC não encontrado: $IsccPath"
        }
        return $IsccPath
    }

    $isccCommand = Get-Command 'ISCC.exe' -ErrorAction SilentlyContinue
    if ($null -ne $isccCommand) {
        return $isccCommand.Source
    }

    $programFiles = [Environment]::GetFolderPath('ProgramFilesX86')
    $installedIscc = Join-Path $programFiles 'Inno Setup 6\ISCC.exe'
    if (Test-Path -LiteralPath $installedIscc) {
        return $installedIscc
    }

    throw 'ISCC não encontrado. Instale o Inno Setup 6.'
}

$installerScript = Join-Path $ProjectRoot 'installer\markdown-editor.iss'
$installerDefinition = [System.IO.File]::ReadAllText($installerScript)
$expectedVersion = "#define AppVersion `"$Version`""
if (-not $installerDefinition.Contains($expectedVersion)) {
    throw "Execute update-version.ps1 para definir a versão $Version."
}

$releaseFiles = @(
    (Join-Path $ProjectRoot 'bin\markdown-editor.exe'),
    (Join-Path $ProjectRoot 'bin\WebView2Loader.dll'),
    (Join-Path $ProjectRoot 'THIRD_PARTY_NOTICES.md')
)
foreach ($releaseFile in $releaseFiles) {
    if (-not (Test-Path -LiteralPath $releaseFile)) {
        throw "Arquivo da distribuição não encontrado: $releaseFile"
    }
}

$distDirectory = Join-Path $ProjectRoot 'dist'
New-Item -ItemType Directory -Force $distDirectory | Out-Null

$iscc = Resolve-Iscc
& $iscc $installerScript
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$installerPath = Join-Path $distDirectory "markdown-editor-$Version-setup.exe"
if (-not (Test-Path -LiteralPath $installerPath)) {
    throw "O instalador esperado não foi gerado: $installerPath"
}

$stagingParent = Join-Path ([System.IO.Path]::GetTempPath()) "markdown-editor-$([guid]::NewGuid())"
$portableDirectory = Join-Path $stagingParent 'markdown-editor'
$portablePath = Join-Path $distDirectory "markdown-editor-$Version-portable.zip"

try {
    New-Item -ItemType Directory -Force $portableDirectory | Out-Null
    Copy-Item -LiteralPath $releaseFiles -Destination $portableDirectory
    if (Test-Path -LiteralPath $portablePath) {
        Remove-Item -LiteralPath $portablePath -Force
    }
    Compress-Archive -Path $portableDirectory -DestinationPath $portablePath -CompressionLevel Optimal
} finally {
    $resolvedStaging = [System.IO.Path]::GetFullPath($stagingParent)
    $temporaryRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    if ($resolvedStaging.StartsWith($temporaryRoot, [StringComparison]::OrdinalIgnoreCase)) {
        Remove-Item -LiteralPath $resolvedStaging -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($portablePath)
try {
    $entries = @($archive.Entries | ForEach-Object FullName | Sort-Object)
} finally {
    $archive.Dispose()
}
$expectedEntries = @(
    'markdown-editor/markdown-editor.exe',
    'markdown-editor/THIRD_PARTY_NOTICES.md',
    'markdown-editor/WebView2Loader.dll'
) | Sort-Object
if (Compare-Object $expectedEntries $entries) {
    throw 'O pacote portátil não contém exatamente os arquivos esperados.'
}

Write-Host "Instalador: $installerPath"
Write-Host "Portátil: $portablePath"
Write-Host "SHA-256 instalador: $((Get-FileHash -Algorithm SHA256 $installerPath).Hash)"
Write-Host "SHA-256 portátil: $((Get-FileHash -Algorithm SHA256 $portablePath).Hash)"
