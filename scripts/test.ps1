. (Join-Path $PSScriptRoot 'common.ps1')

$projectRoot = Split-Path $PSScriptRoot -Parent
$lazbuild = Resolve-Lazbuild
$lazarusDirectory = Split-Path $lazbuild -Parent
$fpc = Resolve-Fpc $lazarusDirectory
$unitOutput = Join-Path $projectRoot 'lib\tests'
$binaryOutput = Join-Path $projectRoot 'bin'
$sourceRoot = Join-Path $projectRoot 'src'
$testRoot = Join-Path $projectRoot 'tests'
$fakeLanguageServerSource = Join-Path $testRoot 'fixtures\fake_lsp\fake_lsp.pas'
$fakeLanguageServer = Join-Path $binaryOutput 'fake_lsp.exe'
$fakeLanguageServerDependencies = @(
    $fakeLanguageServerSource
    (Join-Path $sourceRoot 'services\language_server\lsp_protocol.pas')
)
$sourceUnitArguments = @("-Fu$sourceRoot") + @(
    Get-ChildItem $sourceRoot -Directory -Recurse |
        ForEach-Object { "-Fu$($_.FullName)" }
)
$testUnitArguments = @('-gl', "-Fu$testRoot") + @(
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

$lazUtilsSearchPath = Join-Path $lazarusDirectory 'components\lazutils\lib'
$lazUtilsUnit = Get-ChildItem $lazUtilsSearchPath -Recurse -Filter 'lconvencoding.ppu' -File |
    Select-Object -First 1
if ($null -eq $lazUtilsUnit) {
    throw 'Unidades compiladas do LazUtils não foram encontradas.'
}
$lazUtilsUnits = $lazUtilsUnit.DirectoryName
$testUnitArguments += ('-Fu' + $lazUtilsUnits)

New-Item -ItemType Directory -Force $unitOutput, $binaryOutput | Out-Null
$compileFakeLanguageServer = -not (Test-Path $fakeLanguageServer)
if (-not $compileFakeLanguageServer) {
    $fakeLanguageServerTimestamp = (Get-Item $fakeLanguageServer).LastWriteTimeUtc
    $compileFakeLanguageServer = $null -ne (
        $fakeLanguageServerDependencies |
            Where-Object { (Get-Item $_).LastWriteTimeUtc -gt $fakeLanguageServerTimestamp } |
            Select-Object -First 1
    )
}
if ($compileFakeLanguageServer) {
    & $fpc '-l-' '-v0' '-ve' '-Mobjfpc' '-Sh' $sourceUnitArguments `
        $testUnitArguments "-FU$unitOutput" "-FE$binaryOutput" $fakeLanguageServerSource
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

$testRunnerSource = Join-Path $projectRoot 'tests\test_runner.pas'
& $fpc '-l-' '-v0' '-ve' '-Mobjfpc' '-Sh' $sourceUnitArguments `
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
