# Remove Script for OpenInVSCode Module

# --- Module Configuration ---
$moduleName = "OpenInVSCode"
$targetContexts = @("Folder", "FolderBackground")
# --- End Configuration ---

# --- Registry Paths ---
$commandStorePath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell"
$moduleCommandPath = Join-Path $commandStorePath -ChildPath $moduleName

# --- Removal Logic ---
try {
    # 1. Remove from SubCommands list
    $contextMap = @{
        "Folder" = "Registry::HKEY_CLASSES_ROOT\Directory\shell";
        "FolderBackground" = "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell"
    }

    foreach ($context in $targetContexts) {
        $quickActionsMenuPath = Join-Path -Path $contextMap[$context] -ChildPath "QuickActions"
        if(Test-Path $quickActionsMenuPath) {
            $currentSubCommands = (Get-ItemProperty -Path $quickActionsMenuPath -Name "SubCommands").SubCommands
            $commandsArray = $currentSubCommands.Split(";") | Where-Object { $_ -ne $moduleName }
            $newSubCommands = $commandsArray -join ";"
            Set-ItemProperty -Path $quickActionsMenuPath -Name "SubCommands" -Value $newSubCommands
            Write-Host "    - Unlinked '$moduleName' from '$context' menu."
        }
    }

    # 2. Remove the command from the CommandStore
    if (Test-Path $moduleCommandPath) {
        Remove-Item -Path $moduleCommandPath -Recurse -Force
        Write-Host "    - Removed '$moduleName' from CommandStore."
    }
}
catch {
    Write-Error "    - Failed to remove module '$moduleName'. Error: $($_.Exception.Message)"
}
