# Purpose: Mechanically verify the items in root AGENTS.md § Agent self-check
#          that CAN be automated. PowerShell mirror of verify.sh.
# When:    Local pre-PR; CI later (after toolchain pick).
# Example: pwsh scripts/verify.ps1

$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

$fail = $false
function Fail($msg) { Write-Host "[FAIL] $msg" -ForegroundColor Red; $script:fail = $true }
function Ok($msg)   { Write-Host "[OK]   $msg" -ForegroundColor Green }
function Note($msg) { Write-Host "       $msg" -ForegroundColor DarkGray }

$unbootstrapped = Test-Path '.template-unbootstrapped'
if ($unbootstrapped) {
  Note "template-unbootstrapped sentinel present - skipping placeholder checks."
}

# 1+2. No `@OWNER` / `<project>` placeholder in any tracked file.
if (-not $unbootstrapped) {
  $tracked = git ls-files 2>$null
  # Exclude tooling that references placeholders + .pr/ (PR convention may discuss owner).
  $exclude = '^(scripts/(bootstrap|verify)\.(sh|ps1)|\.template-unbootstrapped|\.pr/.+)$'
  $candidates = $tracked | Where-Object { $_ -notmatch $exclude -and (Test-Path $_ -PathType Leaf) }
  $ownerHits = $candidates | Where-Object { Select-String -Path $_ -Pattern '(^|\s)@OWNER(\b|$)' -Quiet }
  if ($ownerHits) {
    Fail "Files still contain literal '@OWNER':"
    $ownerHits | ForEach-Object { Note "    $_" }
  } else {
    Ok "No '@OWNER' placeholder in tracked files."
  }
  $projHits = $candidates | Where-Object { Select-String -Path $_ -Pattern '<project>' -Quiet }
  if ($projHits) {
    Fail "Files still contain '<project>' placeholder:"
    $projHits | ForEach-Object { Note "    $_" }
  } else {
    Ok "No '<project>' placeholder in tracked files."
  }
}

# 3. No committed `.env*` (except `.env.example`).
$envFiles = git ls-files 2>$null | Where-Object {
  ($_ -match '(^|/)\.env(\.|$)') -and ($_ -notmatch '(^|/)\.env\.example$')
}
if ($envFiles) {
  Fail "Committed .env files detected:"
  $envFiles | ForEach-Object { Note "    $_" }
} else {
  Ok "No leaked .env* files in git."
}

# 4. Front-matter completeness.
function Check-Frontmatter($dir, $required) {
  if (-not (Test-Path $dir)) { return }
  Get-ChildItem -Path $dir -Filter *.md -File | ForEach-Object {
    if ($_.Name -in @('_TEMPLATE.md','INDEX.md')) { return }
    $content = Get-Content $_.FullName -Raw
    $m = [regex]::Match($content, '(?s)^---\s*(.*?)\s*---')
    if (-not $m.Success) {
      Fail "$($_.FullName): no front-matter block."
      return
    }
    $block = $m.Groups[1].Value
    foreach ($key in $required) {
      if ($block -notmatch "(?m)^${key}:") {
        Fail "$($_.FullName): missing required front-matter key '$key'."
      }
    }
  }
}
Check-Frontmatter 'docs/adr'         @('id','title','status','owner','date')
Check-Frontmatter 'docs/rfc'         @('id','title','status','owner','date')
Check-Frontmatter 'docs/product'     @('id','title','status','owner','date')
Check-Frontmatter 'docs/issues'      @('id','title','status','priority','parent','service','owner','date')
Check-Frontmatter 'docs/runbooks'    @('id','title','service','severity','owner','date')
Check-Frontmatter 'docs/postmortems' @('id','title','status','owner','date')
Ok "Front-matter check completed."

# 5. INDEX status sync.
function Check-IndexStatus($dir) {
  $index = Join-Path $dir 'INDEX.md'
  if (-not (Test-Path $index)) { return }
  if ($dir -eq 'docs/runbooks') { return }
  $indexText = Get-Content $index -Raw
  $indexHasOwner = $indexText -match '\| Owner '
  Get-ChildItem -Path $dir -Filter *.md -File | ForEach-Object {
    if ($_.Name -in @('_TEMPLATE.md','INDEX.md')) { return }
    $c = Get-Content $_.FullName -Raw
    $id = if ($c -match '(?m)^id:\s*(\S+)') { $matches[1] } else { return }
    $fmStatus = if ($c -match '(?m)^status:\s*(\S+)') { $matches[1] } else { $null }
    $fmOwner = if ($c -match '(?m)^owner:\s*(\S+)') { $matches[1] } else { $null }
    $row = ($indexText -split "`n") | Where-Object { $_ -match [regex]::Escape($id) } | Select-Object -First 1
    if (-not $row) {
      Fail "$($index): no row for $id (doc exists but is unindexed)."
      return
    }
    if ($fmStatus -and $row -notmatch "[\| ]$([regex]::Escape($fmStatus))[\ \|]") {
      Fail "$($index): status for $id does not match doc front-matter ($fmStatus)."
      Note "    row: $row"
    }
    if ($indexHasOwner -and $fmOwner -and ($row -notmatch [regex]::Escape($fmOwner))) {
      Fail "$($index): owner for $id does not match doc front-matter ($fmOwner)."
      Note "    row: $row"
    }
  }
}
Check-IndexStatus 'docs/adr'
Check-IndexStatus 'docs/rfc'
Check-IndexStatus 'docs/product'
Check-IndexStatus 'docs/issues'
Check-IndexStatus 'docs/postmortems'
Ok "INDEX status sync check completed."

# 6. Sub-tree AGENTS.md size sanity ("delta only").
if (Test-Path AGENTS.md) {
  $rootSize = (Get-Content AGENTS.md).Count
  $warns = 0
  Get-ChildItem -Recurse -Filter AGENTS.md -File |
    Where-Object { $_.FullName -ne (Resolve-Path AGENTS.md).Path -and $_.FullName -notmatch '\\\.git\\' } |
    ForEach-Object {
      $subSize = (Get-Content $_.FullName).Count
      if ($subSize -gt $rootSize) {
        Write-Host ("! WARN  {0} is longer than root AGENTS.md ({1} > {2}). Review for repeated rules." -f $_.FullName,$subSize,$rootSize) -ForegroundColor Yellow
        $warns++
      }
    }
  if ($warns -eq 0) { Ok "Sub-tree AGENTS.md size sanity passed." }
}

Write-Host ""
if ($fail) { Write-Host "verify: FAIL" -ForegroundColor Red; exit 1 }
Write-Host "verify: OK" -ForegroundColor Green
