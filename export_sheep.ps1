param(
    [switch]$RenderPng = $false
)

# 1. FIND OPENSCAD INSTALLATION
# Checks common paths for both System and User-level installs
$possiblePaths = @(
    "$env:LOCALAPPDATA\Programs\OpenSCAD",
    "$env:LOCALAPPDATA\OpenSCAD",
    "C:\Program Files\OpenSCAD",
    "C:\Program Files (x86)\OpenSCAD",
    "/usr/bin", # For Linux (GitHub Actions)
    "/usr/local/bin"
)

$osPath = ""
$exeName = if ($IsWindows -or $env:OS -like "*Windows*") { "openscad.exe" } else { "openscad" }

foreach ($p in $possiblePaths) {
    if (Test-Path "$p/$exeName") {
        $osPath = "$p/$exeName"
        break
    }
}

# If not found in paths, try simple command name (if in PATH)
if ($osPath -eq "") {
    $osPath = Get-Command $exeName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
}

if (!$osPath) {
    Write-Host "ERROR: OpenSCAD not found." -ForegroundColor Red
    return
}

# 3. DEFINE TARGETS
$boxes = @("LB", "LC", "LF", "MB", "MC", "MF", "RB", "RF")
$types = @("Box", "Lid")

$scadFile = "the_sheep.scad"
$stlDir = "./STLs"
$pngDir = "./PNGs"

if (!(Test-Path $stlDir)) { New-Item -ItemType Directory -Path $stlDir }
if ($RenderPng -and !(Test-Path $pngDir)) { New-Item -ItemType Directory -Path $pngDir }

Write-Host "--- Starting Render Loop ---" -ForegroundColor Cyan
Write-Host "Using OpenSCAD at: $osPath"

foreach ($id in $boxes) {
    foreach ($type in $types) {
        $baseName = "sheep_${id}_${type}"
        $stlFile = "$stlDir/$baseName.stl"
        $pngFile = "$pngDir/$baseName.png"
        
        # Set booleans for OpenSCAD
        $pLid = if ($type -eq "Lid") { "true" } else { "false" }
        $pBox = if ($type -eq "Box") { "true" } else { "false" }
        
        # Avoid cross-platform quoting issues by generating a temporary wrapper script
        $runFile = "run.scad"
        $runContent = "print_lid = $pLid; print_box = $pBox; box_id = `"$id`"; include <$scadFile>;"
        Set-Content -Path $runFile -Value $runContent

        # --- STL RENDER ---
        if (Test-Path $stlFile) { Remove-Item $stlFile }
        $stlArgs = @(
            "-o", $stlFile,
            "--enable", "all",
            $runFile
        )
        & $osPath $stlArgs

        if (Test-Path $stlFile -and (Get-Item $stlFile).Length -gt 0) {
            Write-Host "  [STL] Success" -ForegroundColor Green
        } else {
            Write-Host "  [STL] Failed" -ForegroundColor Red
        }

        # --- PNG RENDER ---
        if ($RenderPng) {
            if (Test-Path $pngFile) { Remove-Item $pngFile }
            $pngArgs = @(
                "-o", $pngFile,
                "--imgsize", "1024,1024",
                "--colorscheme", "Cornfield",
                "--viewall", "--autocenter",
                "--enable", "all",
                $runFile
            )
            & $osPath $pngArgs
            if (Test-Path $pngFile) {
                Write-Host "  [PNG] Success" -ForegroundColor Green
            }
        }
        
        if (Test-Path $runFile) { Remove-Item $runFile }
    }
}

Write-Host "--- All Processes Complete ---" -ForegroundColor Cyan