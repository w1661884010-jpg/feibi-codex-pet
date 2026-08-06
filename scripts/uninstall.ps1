[CmdletBinding()]
param(
    [string]$CodexHome = (Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex'),
    [switch]$RestoreBackup
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Get-NormalizedFullPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return [IO.Path]::GetFullPath($Path).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
}

function Assert-NormalDirectory {
    param([Parameter(Mandatory = $true)][string]$Path, [string]$Operation = 'use')
    $item = Get-Item -LiteralPath $Path -Force
    if (-not $item.PSIsContainer) { throw "Refusing to $Operation a non-directory target: $Path" }
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Refusing to $Operation a reparse-point directory: $Path"
    }
}

function Assert-MaomaoManifest {
    param([Parameter(Mandatory = $true)][string]$Directory)
    $manifestPath = Join-Path $Directory 'pet.json'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw "Refusing to remove a pet directory without pet.json: $Directory" }
    try { $manifest = Get-Content -Raw -LiteralPath $manifestPath -Encoding UTF8 | ConvertFrom-Json }
    catch { throw "Refusing to remove a pet directory with invalid pet.json: $Directory" }
    if ([string]$manifest.id -cne 'maomao') { throw "Refusing to remove a pet whose id is not maomao: $Directory" }
}

$normalizedCodexHome = Get-NormalizedFullPath $CodexHome
$petsDirectory = Get-NormalizedFullPath (Join-Path $normalizedCodexHome 'pets')
$targetDirectory = Get-NormalizedFullPath (Join-Path $petsDirectory 'maomao')
$expectedTarget = Get-NormalizedFullPath (Join-Path (Join-Path $normalizedCodexHome 'pets') 'maomao')
if (-not [string]::Equals($targetDirectory, $expectedTarget, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing uninstall outside the expected destination: $targetDirectory"
}

if (Test-Path -LiteralPath $targetDirectory) {
    Assert-NormalDirectory -Path $targetDirectory -Operation 'remove'
    Assert-MaomaoManifest -Directory $targetDirectory
    Remove-Item -LiteralPath $targetDirectory -Recurse -Force
    Write-Host "Feibi removed from: $targetDirectory"
}
else {
    Write-Host 'Feibi is not installed.'
}

if ($RestoreBackup) {
    if (-not (Test-Path -LiteralPath $petsDirectory -PathType Container)) { throw 'No backup directory exists to restore.' }
    $backup = Get-ChildItem -LiteralPath $petsDirectory -Directory |
        Where-Object { $_.Name -match '^maomao\.backup\.\d{8}-\d{9}$' } |
        Sort-Object Name -Descending |
        Select-Object -First 1
    if ($null -eq $backup) { throw 'No maomao backup was found to restore.' }
    Assert-NormalDirectory -Path $backup.FullName -Operation 'restore'
    Assert-MaomaoManifest -Directory $backup.FullName
    Move-Item -LiteralPath $backup.FullName -Destination $targetDirectory
    Write-Host "Restored backup: $($backup.FullName)"
}
