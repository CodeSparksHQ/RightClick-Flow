# Action Script: Resolves folder paths from direct folders, backgrounds, or shortcuts, then opens Gemini CLI.
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$PathL, # Corresponds to %L (long file name for files/folders)
    [Parameter(Mandatory = $false)]
    [string]$PathV, # Corresponds to %V (directory for background clicks)
    [Parameter(Mandatory = $true)]
    [string]$Model,
    [Parameter(Mandatory = $false)]
    [switch]$filescontext
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
    # --- Daily Update Check ---
    $LastUpdateFile = "$env:USERPROFILE\Documents\.gemini_cli_last_update"
    $Today = Get-Date -Format "yyyy-MM-dd"
    $LastUpdateDate = Get-Content $LastUpdateFile -ErrorAction SilentlyContinue
    if ($LastUpdateDate -ne $Today) {
        Write-Host "Checking for Gemini CLI updates (first run of the day)..." -ForegroundColor Yellow
        npm install -g @google/gemini-cli
        if ($?) {
            Set-Content -Path $LastUpdateFile -Value $Today
            Write-Host "Update check complete." -ForegroundColor Green
        } else {
            Write-Warning "The npm update command failed. Continuing with the currently installed version."
        }
    }
    # --- End of Daily Update Check ---

    $Host.UI.RawUI.WindowTitle = '🚀 Gemini CLI (YOLO Mode) 🚀'
    Write-Host "`n Y  O  L  O `n-------------" -ForegroundColor Magenta
    
    cd $targetFolderPath
    if ($filescontext) {
        gemini --model "$Model" --all_files --yolo
    }
    else {
        gemini --model "$Model" --yolo
    }
} else {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("Could not resolve a valid folder from the input:`n$workingPath", "Error", "OK", [System.Windows.Forms.MessageBoxIcon]::Error)
}
pause