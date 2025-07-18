# Remove Script for OpenInGeminiCLI Module

# --- Module Configuration ---
$moduleName = "OpenInGeminiCLI"
$targetContexts = @("Folder", "FolderBackground", "LnkFile")
$subCommandNames = @(
    "GeminiCLI.Flash",
    "GeminiCLI.FlashAll",
    "GeminiCLI.Pro",
    "GeminiCLI.ProAll"
)
# --- End Configuration ---

# --- Registry Paths ---
$commandStorePath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell"

# --- Removal Logic ---
try {
    # 1. Unlink the main menu from the top-level "QuickActions" menu in each context.
    # The main installation script (Manage-QuickActions.ps1) rebuilds the SubCommands list on install,
    # but a dedicated removal script should clean up after itself.
    $contextMap = @{
        "Folder"           = "Registry::HKEY_CLASSES_ROOT\Directory\shell";
        "FolderBackground" = "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell";
        "LnkFile"          = "Registry::HKEY_CLASSES_ROOT\lnkfile\shell";
    }

    foreach ($context in $targetContexts) {
        if ($contextMap.ContainsKey($context)) {
            $quickActionsMenuPath = Join-Path -Path $contextMap[$context] -ChildPath "QuickActions"
            if(Test-Path $quickActionsMenuPath) {
                try {
                    $currentSubCommands = (Get-ItemProperty -Path $quickActionsMenuPath -Name "SubCommands" -ErrorAction Stop).SubCommands
                    if ($currentSubCommands) {
                        $commandsArray = $currentSubCommands.Split(";") | Where-Object { $_ -ne $moduleName }
                        $newSubCommands = $commandsArray -join ";"
                        Set-ItemProperty -Path $quickActionsMenuPath -Name "SubCommands" -Value $newSubCommands
                        Write-Host "    - Unlinked '$moduleName' from '$context' menu."
                    }
                } catch {
                    # This can happen if the SubCommands value doesn't exist; it's safe to ignore.
                }
            }
        }
    }

    # 2. Remove the main module command (which is now a menu) from the CommandStore
    $moduleCommandPath = Join-Path $commandStorePath -ChildPath $moduleName
    if (Test-Path $moduleCommandPath) {
        Remove-Item -Path $moduleCommandPath -Recurse -Force
        Write-Host "    - Removed main menu '$moduleName' from CommandStore."
    }

    # 3. Remove all associated sub-commands from the CommandStore
    foreach ($subCommandName in $subCommandNames) {
        $subCommandPath = Join-Path $commandStorePath -ChildPath $subCommandName
        if (Test-Path $subCommandPath) {
            Remove-Item -Path $subCommandPath -Recurse -Force
            Write-Host "    - Removed sub-command '$subCommandName' from CommandStore."
        }
    }
}
catch {
    Write-Error "    - Failed to remove module '$moduleName'. Error: $($_.Exception.Message)"
}