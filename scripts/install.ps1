[CmdletBinding()]
param(
    [string]$CodexHome = (Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex')
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

function Get-WebPDimensions {
    param([Parameter(Mandatory = $true)][string]$Path)

    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 20) { throw "Spritesheet is too small to be a valid WebP file: $Path" }
    $ascii = [Text.Encoding]::ASCII
    if ($ascii.GetString($bytes, 0, 4) -ne 'RIFF' -or $ascii.GetString($bytes, 8, 4) -ne 'WEBP') {
        throw "Spritesheet is not a RIFF WebP file: $Path"
    }
    $declaredFileSize = [int64][BitConverter]::ToUInt32($bytes, 4) + 8
    if ($declaredFileSize -ne $bytes.Length) {
        throw "Spritesheet RIFF size does not match its file size: $Path"
    }

    $offset = 12
    while (($offset + 8) -le $bytes.Length) {
        $chunkType = $ascii.GetString($bytes, $offset, 4)
        $chunkSize = [BitConverter]::ToUInt32($bytes, $offset + 4)
        $dataOffset = $offset + 8
        $chunkEnd = [int64]$dataOffset + [int64]$chunkSize
        if ($chunkEnd -gt $bytes.Length) { throw "WebP contains a truncated $chunkType chunk: $Path" }

        if ($chunkType -eq 'VP8X') {
            if ($chunkSize -lt 10) { throw "WebP VP8X chunk is invalid: $Path" }
            $width = 1 + $bytes[$dataOffset + 4] + ($bytes[$dataOffset + 5] -shl 8) + ($bytes[$dataOffset + 6] -shl 16)
            $height = 1 + $bytes[$dataOffset + 7] + ($bytes[$dataOffset + 8] -shl 8) + ($bytes[$dataOffset + 9] -shl 16)
            return @($width, $height)
        }
        if ($chunkType -eq 'VP8L') {
            if ($chunkSize -lt 5 -or $bytes[$dataOffset] -ne 0x2F) { throw "WebP VP8L chunk is invalid: $Path" }
            $width = 1 + $bytes[$dataOffset + 1] + (($bytes[$dataOffset + 2] -band 0x3F) -shl 8)
            $height = 1 + (($bytes[$dataOffset + 2] -shr 6) -bor ($bytes[$dataOffset + 3] -shl 2) -bor (($bytes[$dataOffset + 4] -band 0x0F) -shl 10))
            return @($width, $height)
        }
        if ($chunkType -eq 'VP8 ') {
            if ($chunkSize -lt 10 -or $bytes[$dataOffset + 3] -ne 0x9D -or $bytes[$dataOffset + 4] -ne 0x01 -or $bytes[$dataOffset + 5] -ne 0x2A) {
                throw "WebP VP8 frame header is invalid: $Path"
            }
            $width = [BitConverter]::ToUInt16($bytes, $dataOffset + 6) -band 0x3FFF
            $height = [BitConverter]::ToUInt16($bytes, $dataOffset + 8) -band 0x3FFF
            return @($width, $height)
        }

        $offset = [int]($chunkEnd + ($chunkSize -band 1))
    }
    throw "WebP has no supported image data chunk: $Path"
}

function Test-SourcePackage {
    param([Parameter(Mandatory = $true)][string]$PackageDirectory)

    $manifestPath = Join-Path $PackageDirectory 'pet.json'
    $spritesheetPath = Join-Path $PackageDirectory 'spritesheet.webp'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw "Required package file is missing: $manifestPath" }
    if (-not (Test-Path -LiteralPath $spritesheetPath -PathType Leaf)) { throw "Required package file is missing: $spritesheetPath" }
    if ((Get-Item -LiteralPath $manifestPath).Length -le 0 -or (Get-Item -LiteralPath $spritesheetPath).Length -le 0) {
        throw 'Package files must not be empty.'
    }

    try { $manifest = Get-Content -Raw -LiteralPath $manifestPath -Encoding UTF8 | ConvertFrom-Json }
    catch { throw "pet.json is not valid UTF-8 JSON: $($_.Exception.Message)" }
    if ([string]$manifest.id -cne 'maomao') { throw 'pet.json id must be maomao.' }
    $expectedDisplayName = [string]::Concat([char]0x83F2, [char]0x6BD4)
    if ([string]$manifest.displayName -cne $expectedDisplayName) { throw 'pet.json displayName does not match the expected name.' }
    if ([int]$manifest.spriteVersionNumber -ne 2) { throw 'pet.json spriteVersionNumber must be 2.' }
    if ([string]$manifest.spritesheetPath -cne 'spritesheet.webp') { throw 'pet.json spritesheetPath must be spritesheet.webp.' }

    $dimensions = Get-WebPDimensions -Path $spritesheetPath
    if ($dimensions[0] -ne 1536 -or $dimensions[1] -ne 2288) {
        throw "spritesheet.webp must be 1536x2288; found $($dimensions[0])x$($dimensions[1])."
    }
}

$scriptDirectory = Split-Path -Parent $PSCommandPath
$repoRoot = Get-NormalizedFullPath (Join-Path $scriptDirectory '..')
$packageDirectory = Join-Path $repoRoot 'pet\maomao'
Test-SourcePackage -PackageDirectory $packageDirectory

$normalizedCodexHome = Get-NormalizedFullPath $CodexHome
$petsDirectory = Get-NormalizedFullPath (Join-Path $normalizedCodexHome 'pets')
$targetDirectory = Get-NormalizedFullPath (Join-Path $petsDirectory 'maomao')
$expectedTarget = Get-NormalizedFullPath (Join-Path (Join-Path $normalizedCodexHome 'pets') 'maomao')
if (-not [string]::Equals($targetDirectory, $expectedTarget, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing installation outside the expected destination: $targetDirectory"
}

if (-not (Test-Path -LiteralPath $petsDirectory)) { New-Item -ItemType Directory -Path $petsDirectory -Force | Out-Null }
$backupDirectory = $null
if (Test-Path -LiteralPath $targetDirectory) {
    Assert-NormalDirectory -Path $targetDirectory -Operation 'back up'
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmssfff'
    $backupDirectory = Join-Path $petsDirectory ("maomao.backup.$stamp")
    Move-Item -LiteralPath $targetDirectory -Destination $backupDirectory
    Write-Host "Existing installation backed up to: $backupDirectory"
}

try {
    New-Item -ItemType Directory -Path $targetDirectory | Out-Null
    Copy-Item -LiteralPath (Join-Path $packageDirectory 'pet.json') -Destination (Join-Path $targetDirectory 'pet.json')
    Copy-Item -LiteralPath (Join-Path $packageDirectory 'spritesheet.webp') -Destination (Join-Path $targetDirectory 'spritesheet.webp')
}
catch {
    if (Test-Path -LiteralPath $targetDirectory) {
        Assert-NormalDirectory -Path $targetDirectory -Operation 'clean up'
        Remove-Item -LiteralPath $targetDirectory -Recurse -Force
    }
    if ($null -ne $backupDirectory -and (Test-Path -LiteralPath $backupDirectory) -and -not (Test-Path -LiteralPath $targetDirectory)) {
        Move-Item -LiteralPath $backupDirectory -Destination $targetDirectory
    }
    throw
}

Write-Host "Feibi installed to: $targetDirectory"
