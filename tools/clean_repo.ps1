<--
Safe cleanup script for repository developers (moved from scripts/).
-->

Param(
    [switch]$Force
)

function Confirm-Delete($path) {
    if ($Force) { return $true }
    Write-Host "Delete: $path ? (y/N)"
    $ans = Read-Host
    return $ans -match '^[yY]'
}

$candidates = @(
    "parent_app/build",
    "parent_app/.dart_tool",
    "parent_app/.packages",
    "parent_app/.flutter-plugins",
    "build",
    "backend/__pycache__",
    "**/__pycache__",
    "**/*.pyc",
    "**/.DS_Store"
)

foreach ($p in $candidates) {
    $matches = Get-ChildItem -Path $p -ErrorAction SilentlyContinue -Recurse:$false
    if ($matches) {
        foreach ($m in $matches) {
            if (Confirm-Delete $m.FullName) {
                Remove-Item -LiteralPath $m.FullName -Recurse -Force
                Write-Host "Removed $($m.FullName)"
            }
        }
    }
}

Write-Host "Cleanup complete. Review results and commit changes if desired."
