param(
  [int]$MaxFileMB = 95,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = (Resolve-Path (Join-Path $scriptDir "..")).Path
Set-Location $root

if (-not (Test-Path ".git")) {
  git init | Out-Null
  git branch -M main
}

$courses = Get-Content -Raw -Encoding UTF8 -LiteralPath "course-branches.json" | ConvertFrom-Json
$maxBytes = $MaxFileMB * 1MB

$excludedExtensions = @(
  ".zip", ".rar", ".7z", ".gz",
  ".mp4", ".mov", ".avi", ".mpg", ".mpeg",
  ".pyc", ".pyo", ".o", ".d", ".obj", ".exe", ".dll", ".elf", ".axf",
  ".bit", ".bin", ".hex", ".map", ".jou", ".log", ".rpt", ".bak", ".lock"
)

$excludedDirNames = @(
  ".git", ".obsidian", "__pycache__", "node_modules", ".venv", "venv",
  "Debug", "Release", "build", "dist", ".Xil", "xsim.dir", "ip_user_files",
  ".metadata"
)

$excludedFileNames = @(
  ".DS_Store", "Thumbs.db", "desktop.ini"
)

function Get-RelativePathString {
  param([string]$Path)
  $rootPath = $root
  if (-not $rootPath.EndsWith([IO.Path]::DirectorySeparatorChar)) {
    $rootPath += [IO.Path]::DirectorySeparatorChar
  }
  $rootUri = New-Object System.Uri($rootPath)
  $pathUri = New-Object System.Uri((Resolve-Path -LiteralPath $Path).Path)
  return [System.Uri]::UnescapeDataString($rootUri.MakeRelativeUri($pathUri).ToString()).Replace("/", [IO.Path]::DirectorySeparatorChar)
}

function ConvertTo-GitPath {
  param([string]$Path)
  return ((Get-RelativePathString $Path) -replace "\\", "/")
}

function Test-ExcludedPath {
  param([IO.FileInfo]$File)
  if ($File.Length -gt $maxBytes) { return $true }
  if ($excludedFileNames -contains $File.Name) { return $true }
  if ($excludedExtensions -contains $File.Extension.ToLowerInvariant()) { return $true }
  $relativeParts = (Get-RelativePathString $File.FullName) -split '[\\/]'
  foreach ($part in $relativeParts) {
    if ($excludedDirNames -contains $part) { return $true }
    if ($part.EndsWith(".runs") -or $part.EndsWith(".cache") -or $part.EndsWith(".hw") -or $part.EndsWith(".sim") -or $part.EndsWith(".ip_user_files")) {
      return $true
    }
  }
  return $false
}

function Get-CourseFiles {
  param([object]$Course)
  $files = New-Object System.Collections.Generic.List[string]
  foreach ($coursePath in $Course.paths) {
    $fullPath = Join-Path $root $coursePath
    if (-not (Test-Path -LiteralPath $fullPath)) {
      Write-Warning "Missing path for $($Course.name): $coursePath"
      continue
    }
    Get-ChildItem -LiteralPath $fullPath -Recurse -File -Force -ErrorAction SilentlyContinue |
      Where-Object { -not (Test-ExcludedPath $_) } |
      ForEach-Object { $files.Add((ConvertTo-GitPath $_.FullName)) }
  }
  return $files
}

foreach ($course in $courses) {
  $courseFiles = Get-CourseFiles $course
  $baseFiles = @(".gitignore", "README.md", "index.html", "课程总览.html", "course-branches.json")
  $allFiles = @($baseFiles + $courseFiles) | Where-Object { Test-Path -LiteralPath (Join-Path $root $_) } | Sort-Object -Unique

  if ($DryRun) {
    $totalBytes = 0
    foreach ($rel in $courseFiles) {
      $item = Get-Item -LiteralPath (Join-Path $root $rel) -ErrorAction SilentlyContinue
      if ($item) { $totalBytes += $item.Length }
    }
    "{0,-42} {1,6} files {2,8:N1} MB -> {3}" -f $course.name, $courseFiles.Count, ($totalBytes / 1MB), $course.branch
    continue
  }

  $tempIndex = Join-Path ([IO.Path]::GetTempPath()) ("course-index-" + [guid]::NewGuid().ToString("N"))
  $pathspec = Join-Path ([IO.Path]::GetTempPath()) ("course-paths-" + [guid]::NewGuid().ToString("N") + ".txt")
  try {
    $env:GIT_INDEX_FILE = $tempIndex
    git read-tree --empty
    $allFiles | Set-Content -LiteralPath $pathspec -Encoding UTF8
    git add -f --pathspec-from-file="$pathspec"
    $tree = git write-tree
    $commitMessage = "Course branch: $($course.name)"
    $commit = git commit-tree $tree -m $commitMessage
    git update-ref "refs/heads/$($course.branch)" $commit
    Write-Host "Updated $($course.branch) ($($courseFiles.Count) files)"
  }
  finally {
    Remove-Item Env:GIT_INDEX_FILE -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tempIndex -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $pathspec -Force -ErrorAction SilentlyContinue
  }
}
