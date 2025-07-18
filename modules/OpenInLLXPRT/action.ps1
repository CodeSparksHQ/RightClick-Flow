# Action Script: Resolves folder paths from direct folders, backgrounds, or shortcuts, then opens LLXPRT.
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$PathL, # Corresponds to %L (long file name for files/folders)
    [Parameter(Mandatory = $false)]
    [string]$PathV # Corresponds to %V (directory for background clicks)
)

# If PathL is the literal string "%L", it means we're in a context (like FolderBackground)
# where %L was not expanded. In this case, the real path is in PathV. Otherwise, PathL is the target.
$workingPath = if ($PathL -ne "%L" -and -not [string]::IsNullOrEmpty($PathL)) { $PathL } else { $PathV }
$targetFolderPath = $null

if (-not [string]::IsNullOrEmpty($workingPath)) {
    # Priority 1: Check if it's a directory. This handles "Folder" and "FolderBackground" contexts.
    if (Test-Path -Path $workingPath -PathType Container) {
        $targetFolderPath = $workingPath
    }
    # Priority 2: If not a directory, check if it's a file. This handles .lnk files or other file types.
    elseif (Test-Path -Path $workingPath -PathType Leaf) {
        # Specifically handle .lnk shortcut files
        if ($workingPath.EndsWith(".lnk", [System.StringComparison]::OrdinalIgnoreCase)) {
            try {
                $shell = New-Object -ComObject WScript.Shell
                $shortcut = $shell.CreateShortcut($workingPath)
                $resolvedPath = $shortcut.TargetPath
                
                # Check if the shortcut's target is a folder
                if (Test-Path -Path $resolvedPath -PathType Container) {
                    $targetFolderPath = $resolvedPath
                }
                # Check if the shortcut's target is a file, if so, use its parent folder
                elseif (Test-Path -Path $resolvedPath -PathType Leaf) {
                    $targetFolderPath = Split-Path -Path $resolvedPath -Parent
                }
            } catch {
                # Fail silently; the error message at the end will handle it.
            }
        }
        # For any other file type, just get its parent folder.
        else {
            $targetFolderPath = Split-Path -Path $workingPath -Parent
        }
    }
}

if ($targetFolderPath) {
    $Host.UI.RawUI.WindowTitle = '🚀 LLXPRT 🚀'
    cd $targetFolderPath

    # Check if llxprt is installed
    if (-not (Get-Command llxprt -ErrorAction SilentlyContinue)) {
        Write-Host "llxprt not found. Installing via npm..."
        #npx https://github.com/acoliver/llxprt-code
        npm install -g git+https://github.com/acoliver/llxprt-code.git

    } else {
        llxprt
    }



} else {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("Could not resolve a valid folder from the input:`n$workingPath", "Error", "OK", [System.Windows.Forms.MessageBoxIcon]::Error)
}
pause
