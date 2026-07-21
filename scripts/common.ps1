function Resolve-Lazbuild {
    if ($env:LazarusDir) {
        $candidate = Join-Path $env:LazarusDir 'lazbuild.exe'
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    $lazbuildCommand = Get-Command lazbuild -ErrorAction SilentlyContinue
    if ($null -ne $lazbuildCommand) {
        $shimFile = [System.IO.Path]::ChangeExtension(
            $lazbuildCommand.Source, '.shim')
        if (Test-Path $shimFile) {
            $shimDefinition = Get-Content $shimFile -Raw
            if ($shimDefinition -match 'path\s*=\s*"([^"]+)"') {
                return $Matches[1]
            }
        }
        return $lazbuildCommand.Source
    }

    throw 'lazbuild não encontrado. Instale o Lazarus e adicione-o ao PATH.'
}

function Resolve-Fpc([string] $LazarusDirectory) {
    $bundledCompiler = Get-ChildItem (Join-Path $LazarusDirectory 'fpc') `
        -Recurse -Filter 'fpc.exe' -File -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($null -ne $bundledCompiler) {
        return $bundledCompiler.FullName
    }

    $fpcCommand = Get-Command fpc -ErrorAction SilentlyContinue
    if ($null -ne $fpcCommand) {
        return $fpcCommand.Source
    }

    throw 'fpc não encontrado. Instale o Free Pascal 3.2.2 ou posterior.'
}
