. (Join-Path $PSScriptRoot 'common.ps1')

$projectRoot = Split-Path $PSScriptRoot -Parent
$lazbuild = Resolve-Lazbuild
$lazarusDirectory = Split-Path $lazbuild -Parent
$fpc = Resolve-Fpc $lazarusDirectory
$unitOutput = Join-Path $projectRoot 'lib\tests'
$binaryOutput = Join-Path $projectRoot 'bin'

& (Join-Path $PSScriptRoot 'build.ps1') -Mode Debug
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$markdownUnit = Get-ChildItem `
    (Join-Path $projectRoot 'vendor\delphi-markdown\packages\lib') `
    -Recurse -Filter 'markdownprocessor.ppu' -File | Select-Object -First 1
if ($null -eq $markdownUnit) {
    throw 'Unidades compiladas do MarkdownEngine não foram encontradas.'
}
$markdownUnits = $markdownUnit.DirectoryName

New-Item -ItemType Directory -Force $unitOutput, $binaryOutput | Out-Null
$tests = @('test_markdown_renderer.pas', 'test_file_service.pas')
foreach ($test in $tests) {
    $source = Join-Path $projectRoot "tests\$test"
    & $fpc '-Mobjfpc' '-Sh' "-Fu$projectRoot\src" "-Fu$markdownUnits" `
        "-FU$unitOutput" "-FE$binaryOutput" $source
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    $executable = Join-Path $binaryOutput `
        (([IO.Path]::GetFileNameWithoutExtension($test)) + '.exe')
    & $executable
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}
