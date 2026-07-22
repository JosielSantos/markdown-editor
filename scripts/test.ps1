. (Join-Path $PSScriptRoot 'common.ps1')

$projectRoot = Split-Path $PSScriptRoot -Parent
$lazbuild = Resolve-Lazbuild
$lazarusDirectory = Split-Path $lazbuild -Parent
$fpc = Resolve-Fpc $lazarusDirectory
$unitOutput = Join-Path $projectRoot 'lib\tests'
$binaryOutput = Join-Path $projectRoot 'bin'
$sourceRoot = Join-Path $projectRoot 'src'
$testRoot = Join-Path $projectRoot 'tests'
$sourceUnitArguments = @("-Fu$sourceRoot") + @(
    Get-ChildItem $sourceRoot -Directory -Recurse |
        ForEach-Object { "-Fu$($_.FullName)" }
)
$testUnitArguments = @("-Fu$testRoot") + @(
    Get-ChildItem $testRoot -Directory -Recurse |
        ForEach-Object { "-Fu$($_.FullName)" }
)

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

$argumentParserUnit = Get-ChildItem `
    (Join-Path $projectRoot 'vendor\argparser-fp\packages\lazarus\lib') `
    -Recurse -Filter 'argparser.ppu' -File | Select-Object -First 1
if ($null -eq $argumentParserUnit) {
    throw 'Unidades compiladas do argparser-fp não foram encontradas.'
}
$argumentParserUnits = $argumentParserUnit.DirectoryName

New-Item -ItemType Directory -Force $unitOutput, $binaryOutput | Out-Null
$testRunnerSource = Join-Path $projectRoot 'tests\test_runner.pas'
& $fpc '-Mobjfpc' '-Sh' $sourceUnitArguments `
    $testUnitArguments "-Fu$markdownUnits" "-Fu$argumentParserUnits" `
    "-FU$unitOutput" "-FE$binaryOutput" $testRunnerSource
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$testRunner = Join-Path $binaryOutput 'test_runner.exe'
& $testRunner
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
