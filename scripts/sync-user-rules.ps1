# Synchronizuje fundament/ z GitHub do ~/.cursor/rules + patch skanera User Rules (Windows).
# Uruchom ponownie po aktualizacji Cursora (patch może zostać nadpisany).

$ErrorActionPreference = "Stop"

$rulesDir = Join-Path $env:USERPROFILE ".cursor\rules"
$tempRepo = Join-Path $env:TEMP "cursor-rules-import"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Klonowanie Syntance/cursor-rules..."
if (Test-Path $tempRepo) { Remove-Item $tempRepo -Recurse -Force }
git clone --depth 1 https://github.com/Syntance/cursor-rules.git $tempRepo | Out-Null

New-Item -ItemType Directory -Force -Path $rulesDir | Out-Null
Copy-Item (Join-Path $tempRepo "fundament\*.mdc") $rulesDir -Force

Get-ChildItem $rulesDir -Filter *.mdc | ForEach-Object {
    $text = [IO.File]::ReadAllText($_.FullName) -replace "`r`n", "`n"
    [IO.File]::WriteAllText($_.FullName, $text)
}

$count = (Get-ChildItem $rulesDir -Filter *.mdc).Count
Write-Host "Skopiowano $count plikow do $rulesDir"

node (Join-Path $scriptDir "patch-cursor-user-rules.js")
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Patch nieudany — reguly sa w $rulesDir, ale UI User Rules moze byc puste."
    exit $LASTEXITCODE
}

Write-Host "Patch skanera user rules: OK"
Write-Host "Zrob Reload Window w Cursorze (Ctrl+Shift+P -> Developer: Reload Window)"
