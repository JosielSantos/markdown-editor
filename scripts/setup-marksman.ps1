param(
    [string] $Destination = (Join-Path (Split-Path $PSScriptRoot -Parent) 'marksman.exe')
)

$ErrorActionPreference = 'Stop'
$marksmanVersion = '2026-02-08'
$downloadUri = "https://github.com/artempyanykh/marksman/releases/download/$marksmanVersion/marksman.exe"
$expectedSha256 = 'A6D05BEB08EBE41B0A9F09C98A438540421436FA5531424C22E0BB1D22529705'
$temporaryFile = Join-Path ([System.IO.Path]::GetTempPath()) "marksman-$([guid]::NewGuid()).exe"

if (Test-Path -LiteralPath $Destination) {
    $installedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $Destination).Hash
    if ($installedHash -eq $expectedSha256) {
        Write-Host "Marksman $marksmanVersion já está instalado em: $Destination"
        exit 0
    }
}

try {
    Invoke-WebRequest -Uri $downloadUri -OutFile $temporaryFile
    $downloadHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $temporaryFile).Hash
    if ($downloadHash -ne $expectedSha256) {
        throw "Hash SHA-256 inesperado para o Marksman $marksmanVersion."
    }
    Copy-Item -LiteralPath $temporaryFile -Destination $Destination -Force
    Write-Host "Marksman $marksmanVersion instalado em: $Destination"
} finally {
    Remove-Item -LiteralPath $temporaryFile -Force -ErrorAction SilentlyContinue
}
