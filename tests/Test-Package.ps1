[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "TEST FAILED: $Message" }
}

$repoRoot = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $PSCommandPath) '..'))
$installScript = Join-Path $repoRoot 'scripts\install.ps1'
$uninstallScript = Join-Path $repoRoot 'scripts\uninstall.ps1'
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("feibi-package-test-" + [Guid]::NewGuid().ToString('N'))
$fakeCodexHome = Join-Path $tempRoot 'fake-profile\.codex'

try {
    New-Item -ItemType Directory -Path $tempRoot | Out-Null

    # A copied installer with no sibling pet package must fail before touching the fake CodexHome.
    $missingRepo = Join-Path $tempRoot 'missing-package'
    $missingScripts = Join-Path $missingRepo 'scripts'
    New-Item -ItemType Directory -Path $missingScripts -Force | Out-Null
    Copy-Item -LiteralPath $installScript -Destination (Join-Path $missingScripts 'install.ps1')
    $missingFailed = $false
    try { & (Join-Path $missingScripts 'install.ps1') -CodexHome $fakeCodexHome }
    catch { $missingFailed = $true }
    Assert-True $missingFailed 'Installer accepted a package with required files absent.'
    Assert-True (-not (Test-Path -LiteralPath $fakeCodexHome)) 'Missing-package validation touched the destination.'

    # A file at the exact target must be rejected without replacement.
    $fileTargetHome = Join-Path $tempRoot 'file-target\.codex'
    $fileTargetPets = Join-Path $fileTargetHome 'pets'
    New-Item -ItemType Directory -Path $fileTargetPets -Force | Out-Null
    $fileTarget = Join-Path $fileTargetPets 'feibi'
    Set-Content -LiteralPath $fileTarget -Value 'do not replace' -Encoding ASCII
    $fileTargetFailed = $false
    try { & $installScript -CodexHome $fileTargetHome }
    catch { $fileTargetFailed = $true }
    Assert-True $fileTargetFailed 'Installer accepted a non-directory target.'
    Assert-True (Test-Path -LiteralPath $fileTarget -PathType Leaf) 'Installer changed the non-directory target.'

    & $installScript -CodexHome $fakeCodexHome
    $target = Join-Path $fakeCodexHome 'pets\feibi'
    Assert-True (Test-Path -LiteralPath (Join-Path $target 'pet.json') -PathType Leaf) 'pet.json was not installed.'
    Assert-True (Test-Path -LiteralPath (Join-Path $target 'spritesheet.webp') -PathType Leaf) 'spritesheet.webp was not installed.'
    Assert-True (@(Get-ChildItem -LiteralPath $target -File).Count -eq 2) 'Installer copied files other than the two package files.'

    & $installScript -CodexHome $fakeCodexHome
    $backups = @(Get-ChildItem -LiteralPath (Join-Path $fakeCodexHome 'pets') -Directory | Where-Object { $_.Name -like 'feibi.backup.*' })
    Assert-True ($backups.Count -eq 1) 'Repeat install did not create exactly one backup.'

    & $uninstallScript -CodexHome $fakeCodexHome -RestoreBackup
    Assert-True (Test-Path -LiteralPath (Join-Path $target 'pet.json') -PathType Leaf) 'Backup restore did not recreate the installation.'
    Assert-True (@(Get-ChildItem -LiteralPath (Join-Path $fakeCodexHome 'pets') -Directory | Where-Object { $_.Name -like 'feibi.backup.*' }).Count -eq 0) 'Restored backup was not consumed.'

    & $uninstallScript -CodexHome $fakeCodexHome
    Assert-True (-not (Test-Path -LiteralPath $target)) 'Uninstall did not remove the exact target.'

    Write-Host 'All package, install, backup, restore, and uninstall tests passed.'
}
finally {
    if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
}
