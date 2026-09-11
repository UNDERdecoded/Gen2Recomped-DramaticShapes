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
  $Output = Join-Path (Split-Path $repo -Parent) ($modId + '-' + $modVersion + '.zip')
}
$Output = [System.IO.Path]::GetFullPath($Output)

$source = @()
foreach ($dir in @('data', 'lib')) {
  $source += Get-ChildItem -LiteralPath (Join-Path $repo $dir) -Recurse -File |
    ForEach-Object {
      $relative = Relative-Path $_.FullName
      if (-not (Test-ExcludedFolder $relative)) { $relative }
    }
}
$source += @('CHANGELOG.md', 'main.lua', 'manifest.json', 'mod.card', 'README.md')
# These files are deliberately ignored by Git, but a local test build should
# include them. Only PNG is a supported packaged battle-art format; source
# animations and conversion inputs stay outside the distributable archive.
$localArt = @(Get-ChildItem -LiteralPath (Join-Path $repo 'assets\battle') `
  -Recurse -File -Filter '*.png' -ErrorAction SilentlyContinue | ForEach-Object {
    $relative = Relative-Path $_.FullName
    # Authoring drafts may live beside a collection in a folder literally
    # named "backup". They are never runtime candidates and must not inflate
    # or leak into the private test package.
    if (-not (Test-ExcludedFolder $relative)) { $relative }
  })
# The OpenXR loader DLL is read through mod:read at runtime (VRXR); without it
# every VR session fails from an installed zip even though it works from git.
$vrRuntime = @(Get-ChildItem -LiteralPath (Join-Path $repo 'assets\vr') `
  -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    Relative-Path $_.FullName
  })
$files = @($source + $localArt + $vrRuntime | Sort-Object -Unique)
if (-not $files.Count) { throw "no package files found" }

if (Test-Path -LiteralPath $Output) { Remove-Item -LiteralPath $Output -Force }
$fileList = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllLines(
  $fileList,
  [string[]]$files,
  [System.Text.UTF8Encoding]::new($false)
)
Push-Location $repo
try {
  # Passing hundreds of asset paths as individual arguments exceeds the
  # Windows command-line limit. tar's list-file option keeps the invocation
  # short while preserving repository-relative paths inside the archive.
  & tar -a -cf $Output -T $fileList
  if ($LASTEXITCODE -ne 0) { throw "tar failed: $LASTEXITCODE" }
} finally {
  Pop-Location
  Remove-Item -LiteralPath $fileList -Force -ErrorAction SilentlyContinue
}

$entries = @(tar -tf $Output)
if ($entries | Where-Object { Test-ExcludedFolder $_ }) {
  throw "package unexpectedly contains an _source or backup folder"
}
$unsupportedAssets = @($entries | Where-Object {
  $_ -match '(?i)^assets/' -and
  $_ -notmatch '(?i)^assets/battle/.*\.png$' -and
  $_ -notmatch '(?i)^assets/vr/'
})
if ($unsupportedAssets.Count) {
  throw "package unexpectedly contains unsupported assets: " +
    ($unsupportedAssets -join ', ')
}
foreach ($required in @('manifest.json', 'main.lua', 'mod.card')) {
  if ($entries -notcontains $required) {
    throw "package is missing required install entry: $required"
  }
}
foreach ($requiredPrefix in @('data/', 'lib/')) {
  if (-not ($entries | Where-Object { $_.StartsWith($requiredPrefix) })) {
    throw "package is missing required install tree: $requiredPrefix"
  }
}
[PSCustomObject]@{
  Path = $Output
  Entries = $entries.Count
  BattlePngs = $localArt.Count
  VrFiles = $vrRuntime.Count
  Bytes = (Get-Item -LiteralPath $Output).Length
  SHA256 = (Get-FileHash -LiteralPath $Output -Algorithm SHA256).Hash
}
