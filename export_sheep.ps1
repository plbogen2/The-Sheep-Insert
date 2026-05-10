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
        
        Write-Host "Rendering: $baseName" -ForegroundColor Yellow
        
        # --- STL RENDER ---
        if (Test-Path $stlFile) { Remove-Item $stlFile }
        $stlArgs = @(
            "-o", $stlFile,
            "-D", ('box_id=\"' + $id + '\"'),
            "-D", "print_lid=$pLid",
            "-D", "print_box=$pBox",
            "--enable", "all",
            $scadFile
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
                "-D", ('box_id=\"' + $id + '\"'),
                "-D", "print_lid=$pLid",
                "-D", "print_box=$pBox",
                "--imgsize", "1024,1024",
                "--colorscheme", "Cornfield",
                "--viewall", "--autocenter",
                "--enable", "all",
                $scadFile
            )
            & $osPath $pngArgs
            if (Test-Path $pngFile) {
                Write-Host "  [PNG] Success" -ForegroundColor Green
            }
        }
    }
}

Write-Host "--- All Processes Complete ---" -ForegroundColor Cyan