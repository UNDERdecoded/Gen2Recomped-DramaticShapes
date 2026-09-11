param(
  [string]$Output = ""
)

$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Relative-Path([string]$FullName) {
  return $FullName.Substring($repo.Length + 1).Replace('\', '/')
}
function Test-ExcludedFolder([string]$Relative) {
  return $Relative -match '(?i)(^|/)(_source|backup)(/|$)'
}

# Derive the package name from the mod's own manifest (id + version) so the
# produced .zip matches what the in-game mod manager expects for auto-update:
# ModUpdate.pickZipAsset prefers exactly "<id>-<version>.zip". A hardcoded
# "DramaticShapeVoxelMod-battle-art" name stopped matching once the manifest
# id was renamed, which is why post-rename updates failed to resolve.
$manifest = Get-Content -Raw -LiteralPath (Join-Path $repo 'manifest.json') |
  ConvertFrom-Json
$modId = $manifest.id
$modVersion = ($manifest.version -replace '^[vV]', '')
if (-not $modId -or -not $modVersion) {
  throw "manifest.json is missing id or version"
}

if (-not $Output) {
  $Output = Join-Path (Split-Path $repo -Parent) `
    ($modId + '-' + $modVersion + '-clean.zip')
}
$Output = [System.IO.Path]::GetFullPath($Output)

# Match the installable runtime allowlist used by package_mod.ps1, then add
# the public authoring toolkit so a ZIP recipient does not need a Git clone.
$source = @()
foreach ($dir in @('data', 'lib', 'tools')) {
  $source += Get-ChildItem -LiteralPath (Join-Path $repo $dir) -Recurse -File |
    Where-Object {
      $_.Extension -ine '.pyc' -and
      $_.FullName -notmatch '(?i)[\\/]__pycache__[\\/]'
    } |
    ForEach-Object {
      $relative = Relative-Path $_.FullName
      if (-not (Test-ExcludedFolder $relative)) { $relative }
    }
}
$source += @('CHANGELOG.md', 'main.lua', 'manifest.json', 'mod.card', 'README.md')

$battleRoot = Join-Path $repo 'assets\battle'
$battleDirs = @(Get-ChildItem -LiteralPath $battleRoot -Recurse -Directory |
  ForEach-Object {
    $relative = Relative-Path $_.FullName
    if (-not (Test-ExcludedFolder $relative)) {
      $relative.TrimEnd('/') + '/'
    }
  })
$battleDirs += 'assets/battle/'

# Keep Markdown contracts while never shipping private BYO Pokemon/trainer
# collections. The folders remain visible, but all image and animation formats
# are reserved for the local package_mod.ps1 build.
$battleFiles = @(Get-ChildItem -LiteralPath $battleRoot -Recurse -File -Force |
  Where-Object {
    $relative = Relative-Path $_.FullName
    -not (Test-ExcludedFolder $relative) -and $_.Extension -ieq '.md'
  } |
  ForEach-Object { Relative-Path $_.FullName })

# The OpenXR loader DLL is read through mod:read at runtime (VRXR): tracked in
# git, so a clean checkout has it and the clean package must ship it too.
$vrFiles = @(Get-ChildItem -LiteralPath (Join-Path $repo 'assets\vr') `
  -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    Relative-Path $_.FullName
  })

$entries = @($source + $battleDirs + $battleFiles + $vrFiles | Sort-Object -Unique)
if (-not $entries.Count) { throw "no package entries found" }

if (Test-Path -LiteralPath $Output) {
  Remove-Item -LiteralPath $Output -Force
}

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::Open(
  $Output,
  [System.IO.Compression.ZipArchiveMode]::Create
)
try {
  foreach ($entry in $entries) {
    if ($entry.EndsWith('/')) {
      # A ZIP directory entry keeps an otherwise-empty BYO generation folder
      # visible without recursively collecting anything stored below it.
      [void]$archive.CreateEntry($entry)
      continue
    }
    $fullName = Join-Path $repo ($entry.Replace('/', '\'))
    if (-not (Test-Path -LiteralPath $fullName -PathType Leaf)) {
      throw "package source file is missing: $entry"
    }
    [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
      $archive,
      $fullName,
      $entry,
      [System.IO.Compression.CompressionLevel]::Optimal
    )
  }
} finally {
  $archive.Dispose()
}

$checkArchive = [System.IO.Compression.ZipFile]::OpenRead($Output)
try {
  $packed = @($checkArchive.Entries | ForEach-Object { $_.FullName })
} finally {
  $checkArchive.Dispose()
}
$privateBattleArt = @($packed | Where-Object {
  $_ -match '(?i)^assets/battle/' -and
  -not $_.EndsWith('/') -and
  $_ -notmatch '(?i)\.md$'
})
if ($packed | Where-Object { Test-ExcludedFolder $_ }) {
  throw "clean package unexpectedly contains an _source or backup folder"
}
if ($privateBattleArt.Count) {
  throw "clean package unexpectedly contains private battle art: " +
    ($privateBattleArt -join ', ')
}
$unsupportedAssets = @($packed | Where-Object {
  $_ -match '(?i)^assets/' -and
  $_ -notmatch '(?i)^assets/battle/' -and
  $_ -notmatch '(?i)^assets/vr/'
})
if ($unsupportedAssets.Count) {
  throw "clean package unexpectedly contains unsupported assets: " +
    ($unsupportedAssets -join ', ')
}

foreach ($required in @('manifest.json', 'main.lua', 'mod.card')) {
  if ($packed -notcontains $required) {
    throw "clean package is missing required install entry: $required"
  }
}
foreach ($requiredPrefix in @('data/', 'lib/')) {
  if (-not ($packed | Where-Object { $_.StartsWith($requiredPrefix) })) {
    throw "clean package is missing required install tree: $requiredPrefix"
  }
}

[PSCustomObject]@{
  Path = $Output
  Entries = $packed.Count
  PrivateBattleArt = $privateBattleArt.Count
  BattleFolders = $battleDirs.Count
  VrFiles = $vrFiles.Count
  Bytes = (Get-Item -LiteralPath $Output).Length
  SHA256 = (Get-FileHash -LiteralPath $Output -Algorithm SHA256).Hash
}
