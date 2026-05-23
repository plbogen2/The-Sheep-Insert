param(
    [switch]$RenderPng = $false,
    [switch]$Test = $false
)

$ScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent -LiteralPath $MyInvocation.MyCommand.Path }
Set-Location -LiteralPath $ScriptRoot

$global:TestFailed = $false
$baselineDir = Join-Path $ScriptRoot "tests/baselines"
$diffDir = Join-Path $ScriptRoot "tests/diffs"

if ($Test) {
    if (!(Test-Path $baselineDir)) { New-Item -ItemType Directory -Path $baselineDir -Force | Out-Null }
    if (!(Test-Path $diffDir)) { New-Item -ItemType Directory -Path $diffDir -Force | Out-Null }
}

# 1. FIND OPENSCAD INSTALLATION
# Checks common paths for both System and User-level installs
$possiblePaths = if ($IsWindows -or $env:OS -like "*Windows*") {
    @(
        "$env:LOCALAPPDATA\Programs\OpenSCAD (Nightly)",
        "C:\Program Files\OpenSCAD (Nightly)",
        "$env:LOCALAPPDATA\Programs\OpenSCAD",
        "$env:LOCALAPPDATA\OpenSCAD",
        "C:\Program Files\OpenSCAD",
        "C:\Program Files (x86)\OpenSCAD"
    )
}
else {
    @(
        "/usr/bin",
        "/usr/local/bin"
    )
}

$osPath = ""
$exeName = if ($IsWindows -or $env:OS -like "*Windows*") { "openscad.exe" } else { "openscad" }
$tempDir = [System.IO.Path]::GetTempPath()

foreach ($p in $possiblePaths) {
    $candidate = Join-Path $p $exeName
    if (Test-Path -LiteralPath $candidate) {
        $osPath = [System.IO.Path]::GetFullPath($candidate)
        break
    }
}

# If not found in paths, try simple command name (if in PATH)
if ($osPath -eq "") {
    $cmd = Get-Command $exeName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    if ($cmd) { $osPath = [System.IO.Path]::GetFullPath($cmd) }
}

if (!$osPath) {
    Write-Host "ERROR: OpenSCAD not found." -ForegroundColor Red
    return
}

# 3. DEFINE TARGETS
$allBoxes = @("LB", "LC", "LF", "MB", "MC", "MF", "RB", "RF")
$types = @("Box", "Lid")

# Determine which boxes to build based on the latest git commit message
$commitMessage = ""
try {
    $commitMessage = git log -1 --pretty=%B 2>$null
}
catch {
    # git not available or failed, ignore
}

$boxesToBuild = @()
if ($commitMessage -match "\[build:(.*?)\]") {
    $tags = $matches[1] -split ","
    foreach ($tag in $tags) {
        $t = $tag.Trim()
        if ($t -eq "all") {
            $boxesToBuild = $allBoxes
            break
        }
        if ($allBoxes -contains $t -and $boxesToBuild -notcontains $t) {
            $boxesToBuild += $t
        }
    }
}

# Default to building everything if no valid tags were found
if ($boxesToBuild.Count -eq 0) {
    $boxesToBuild = $allBoxes
}

Write-Host "Boxes to render: $($boxesToBuild -join ', ')" -ForegroundColor Yellow

$scadFile = Join-Path $ScriptRoot "the_sheep.scad"
if (!(Test-Path -LiteralPath $scadFile)) {
    Write-Host "ERROR: Missing $scadFile" -ForegroundColor Red
    return
}

# Windows: 8.3 short path so include "..." in a temp wrapper parses reliably (paths with spaces break some builds).
$isWin = ($IsWindows -or $env:OS -like "*Windows*")
$includeSheep = if ($isWin) {
    try {
        $fso = New-Object -ComObject Scripting.FileSystemObject
        (($fso.GetFile($scadFile)).ShortPath) -replace '\\', '/'
    }
    catch {
        ($scadFile -replace '\\', '/')
    }
}
else {
    $scadFile -replace '\\', '/'
}

$stlDir = Join-Path $ScriptRoot "STLs"
$pngDir = Join-Path $ScriptRoot "PNGs"

if (!(Test-Path $stlDir)) { New-Item -ItemType Directory -Path $stlDir | Out-Null }
if ($RenderPng -and !(Test-Path $pngDir)) { New-Item -ItemType Directory -Path $pngDir | Out-Null }

Write-Host "--- Starting Render Loop ---" -ForegroundColor Cyan
Write-Host "Using OpenSCAD at: $osPath"

foreach ($id in $boxesToBuild) {
    foreach ($type in $types) {
        $baseName = "sheep_${id}_${type}"
        $stlFile = Join-Path $stlDir "$baseName.stl"
        $pngFile = Join-Path $pngDir "$baseName.png"
        
        # Set booleans for OpenSCAD
        $pLid = if ($type -eq "Lid") { "true" } else { "false" }
        $pBox = if ($type -eq "Box") { "true" } else { "false" }
        
        $runFile = Join-Path $tempDir ("sheep_export_{0}_{1}_{2}.scad" -f $id, $type, [guid]::NewGuid().ToString("N"))
        $runLines = @(
            "print_lid = $pLid;",
            "print_box = $pBox;",
            "box_id = `"$id`";",
            "include <$includeSheep>"
        )
        $utf8 = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($runFile, ($runLines -join "`n"), $utf8)

        # --- STL RENDER ---
        if (Test-Path $stlFile) { Remove-Item -LiteralPath $stlFile -Force }
        try {
            & $osPath @("-o", $stlFile, "--enable", "all", $runFile)
        }
        finally {
            if (Test-Path -LiteralPath $runFile) { Remove-Item -LiteralPath $runFile -Force -ErrorAction SilentlyContinue }
        }
        if ((Test-Path $stlFile) -and (Get-Item $stlFile).Length -gt 0) {
            Write-Host "  [STL] Success" -ForegroundColor Green
        }
        else {
            Write-Host "  [STL] Failed" -ForegroundColor Red
        }

        # --- PNG RENDER ---
        if ($RenderPng) {
            if (Test-Path $pngFile) { Remove-Item -LiteralPath $pngFile -Force }
            $runFilePng = Join-Path $tempDir ("sheep_export_png_{0}_{1}_{2}.scad" -f $id, $type, [guid]::NewGuid().ToString("N"))
            [System.IO.File]::WriteAllText($runFilePng, ($runLines -join "`n"), $utf8)
            try {
                & $osPath @(
                    "-o", $pngFile,
                    "--imgsize", "1024,1024",
                    "--colorscheme", "Cornfield",
                    "--viewall", "--autocenter",
                    "--enable", "all",
                    $runFilePng
                )
            }
            finally {
                if (Test-Path -LiteralPath $runFilePng) { Remove-Item -LiteralPath $runFilePng -Force -ErrorAction SilentlyContinue }
            }
            if (Test-Path $pngFile) {
                Write-Host "  [PNG] Success" -ForegroundColor Green

                if ($Test) {
                    $baselineFile = Join-Path $baselineDir "$baseName.png"
                    $diffFile = Join-Path $diffDir "${baseName}_diff.png"
                    
                    if (!(Test-Path $baselineFile)) {
                        Write-Host "  [TEST] Baseline not found. Creating new baseline..." -ForegroundColor Yellow
                        Copy-Item -LiteralPath $pngFile -Destination $baselineFile -Force
                    }
                    else {
                        Write-Host "  [TEST] Comparing against baseline..."
                        try {
                            $output = & magick compare -metric AE -fuzz 5% $baselineFile $pngFile $diffFile 2>&1
                            if ($LASTEXITCODE -eq 0) {
                                Write-Host "  [TEST] PASSED" -ForegroundColor Green
                                if (Test-Path $diffFile) { Remove-Item $diffFile -ErrorAction SilentlyContinue }
                            }
                            else {
                                Write-Host "  [TEST] FAILED: Mismatch! (Diff score: $output)" -ForegroundColor Red
                                $global:TestFailed = $true
                            }
                        }
                        catch {
                            Write-Host "  [TEST] ERROR: ImageMagick (magick) is likely not installed or not in PATH." -ForegroundColor Red
                            $global:TestFailed = $true
                        }
                    }
                }
            }
        }
    }
}

if ($RenderPng) {
    Write-Host "Rendering: Full Assembly" -ForegroundColor Yellow
    $fullPngFile = Join-Path $pngDir "sheep_Full_Assembly.png"
    if (Test-Path $fullPngFile) { Remove-Item -LiteralPath $fullPngFile -Force }
    $runFull = Join-Path $tempDir ("sheep_export_full_{0}.scad" -f [guid]::NewGuid().ToString("N"))
    $fullLines = @(
        "print_lid = false;",
        "print_box = true;",
        "box_id = `"`";",
        "include <$includeSheep>"
    )
    $utf8f = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($runFull, ($fullLines -join "`n"), $utf8f)
    try {
        & $osPath @(
            "-o", $fullPngFile,
            "--imgsize", "1024,1024",
            "--colorscheme", "Cornfield",
            "--viewall", "--autocenter",
            "--enable", "all",
            $runFull
        )
    }
    finally {
        if (Test-Path -LiteralPath $runFull) { Remove-Item -LiteralPath $runFull -Force -ErrorAction SilentlyContinue }
    }
    if (Test-Path $fullPngFile) {
        Write-Host "  [PNG] Full Assembly Success" -ForegroundColor Green

        if ($Test) {
            $baselineFile = Join-Path $baselineDir "sheep_Full_Assembly.png"
            $diffFile = Join-Path $diffDir "sheep_Full_Assembly_diff.png"
            
            if (!(Test-Path $baselineFile)) {
                Write-Host "  [TEST] Baseline not found. Creating new baseline..." -ForegroundColor Yellow
                Copy-Item -LiteralPath $fullPngFile -Destination $baselineFile -Force
            }
            else {
                Write-Host "  [TEST] Comparing against baseline..."
                try {
                    $output = & magick compare -metric AE -fuzz 5% $baselineFile $fullPngFile $diffFile 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "  [TEST] PASSED" -ForegroundColor Green
                        if (Test-Path $diffFile) { Remove-Item $diffFile -ErrorAction SilentlyContinue }
                    }
                    else {
                        Write-Host "  [TEST] FAILED: Mismatch! (Diff score: $output)" -ForegroundColor Red
                        $global:TestFailed = $true
                    }
                }
                catch {
                    Write-Host "  [TEST] ERROR: ImageMagick (magick) is likely not installed or not in PATH." -ForegroundColor Red
                    $global:TestFailed = $true
                }
            }
        }
    }
}

Write-Host "--- All Processes Complete ---" -ForegroundColor Cyan

if ($Test -and $global:TestFailed) {
    Write-Host "ERROR: One or more visual regression tests failed." -ForegroundColor Red
    exit 1
}                   if ($isWin) {
                        $output = & magick compare -metric AE -fuzz 5% $baselineFile $fullPngFile $diffFile 2>&1
                    } else {
                        $output = & /usr/bin/compare -metric AE -fuzz 5% $baselineFile $fullPngFile $diffFile 2>&1
                    }
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "  [TEST] PASSED" -ForegroundColor Green
                        if (Test-Path $diffFile) { Remove-Item $diffFile -ErrorAction SilentlyContinue }
                    } else {
                        Write-Host "  [TEST] FAILED: Mismatch! (Diff score: $output)" -ForegroundColor Red
                        $global:TestFailed = $true
                    }
                } catch {
                    Write-Host "  [TEST] ERROR: ImageMagick (magick) is likely not installed or not in PATH." -ForegroundColor Red
                    $global:TestFailed = $true
                }
            }
        }
    }
}

Write-Host "--- All Processes Complete ---" -ForegroundColor Cyan

if ($Test -and $global:TestFailed) {
    Write-Host "ERROR: One or more visual regression tests failed." -ForegroundColor Red
    exit 1
}