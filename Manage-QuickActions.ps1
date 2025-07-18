# ===================================================================================
# Quick Actions - Interactive Management Console
# Author: Gemini
# Version: 7.0
#
# Description:
# This version implements a robust, two-pass installation system to prevent
# variable scope conflicts and race conditions. It reads all module configurations
# first, then performs a centralized installation, significantly improving
# speed and reliability. The removal process has also been centralized.
# ===================================================================================

[CmdletBinding()]
param(
    [ValidateSet("Install", "Remove")]
    [string]$Mode
)

# --- SCRIPT SETUP AND SELF-ELEVATION ---
if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Administrator privileges are required. Attempting to re-launch as Administrator..."
    $arguments = "& '" + $MyInvocation.MyCommand.Path + "'"
    if ($Mode) { $arguments += " -Mode $Mode" }
    Start-Process powershell -Verb RunAs -ArgumentList $arguments
    exit
}

# --- GLOBAL PATHS & CONFIG ---
$scriptRoot = (Get-Item -Path $MyInvocation.MyCommand.Path).Directory.FullName
$modulesPath = Join-Path -Path $scriptRoot -ChildPath "modules"
$commandStorePath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell"
$mainMenuKeyName = "QuickActions"
$mainMenuText = "Quick Actions"

# --- EXPANDED CONTEXTS FOR "AllFiles" ---
# To avoid the massive performance hit of using a wildcard ('*') in the registry, we define a list
# of common file extensions to apply the "AllFiles" context to. This is much faster and safer.
$commonFileExtensions = @(
    "txt", "log", "ini", "json", "xml", "csv", "md", "yml", "yaml", "ps1", "bat", "cmd", "js", "ts", "py",
    "html", "css", "c", "cpp", "h", "cs", "java", "php", "rb", "go", "swift", "kt", "kts", "groovy",
    "sh", "sql", "config", "conf", "cfg", "reg", "vbs", "url", "webloc", "desktop", "pdf", "doc", "docx",
    "xls", "xlsx", "ppt", "pptx", "png", "jpg", "jpeg", "gif", "bmp", "svg"
)
$allFilesPaths = $commonFileExtensions | ForEach-Object { "Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.$_\shell" }

$contextRegistryMap = @{
    "Folder"           = "Registry::HKEY_CLASSES_ROOT\Directory\shell";
    "FolderBackground" = "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell";
    "Desktop"          = "Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell";
    "AllFiles"         = $allFilesPaths; # Use the generated list instead of the slow wildcard.
    "ExeFile"          = "Registry::HKEY_CLASSES_ROOT\exefile\shell";
    "PS1File"          = "Registry::HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\shell";
    "LnkFile"          = "Registry::HKEY_CLASSES_ROOT\lnkfile\shell";
}

# --- HELPER FUNCTIONS ---

function Get-ModuleConfigurations {
    $configs = [System.Collections.Generic.List[psobject]]::new()
    $moduleDirs = Get-ChildItem -Path $modulesPath -Filter "install.ps1" -Recurse | ForEach-Object { $_.Directory }

    foreach ($dir in $moduleDirs) {
        # Use a script block to load the config in an isolated scope.
        $scriptBlock = [scriptblock]::Create((Get-Content (Join-Path $dir.FullName "install.ps1") -Raw))

        # Now, extract the variables that were set inside the scriptblock's scope.
        # This requires a bit of reflection on the scriptblock's ast.
        $ast = $scriptBlock.Ast.FindAll( { $args[0] -is [System.Management.Automation.Language.AssignmentStatementAst] }, $true)
        $configData = @{}
        foreach($assignment in $ast){
            $varName = $assignment.Left.VariablePath.UserPath
            # Execute the right-hand side of the assignment to get its value.
            $varValue = Invoke-Expression $assignment.Right.Extent.Text
            $configData[$varName] = $varValue
        }

        $configData['ModulePath'] = $dir.FullName
        $configData['ActionScriptPath'] = Join-Path -Path $dir.FullName -ChildPath "action.ps1"
        $configs.Add((New-Object psobject -Property $configData))
    }
    return $configs
}

function Resolve-IconPath {
    param($IconValue)
    if (-not $IconValue) { return $null }
    if ($IconValue -like "imageres.dll,*" -or $IconValue -like "*powershell_ise.exe*") { return $IconValue }
    if ((Split-Path -Path $IconValue -IsAbsolute) -and (Test-Path $IconValue)) { return $IconValue }
    if ($IconValue -like "*.ico") {
        $localPath = Join-Path -Path $scriptRoot -ChildPath $IconValue
        if (Test-Path $localPath) { return $localPath }
    }
    try {
        $exePath = (Get-Command $IconValue -ErrorAction Stop).Source
        if ($exePath.EndsWith(".cmd")) { $exePath = $exePath.Replace(".cmd", ".exe").Replace("bin\", "") }
        if (Test-Path $exePath) { return "$exePath,0" }
    } catch { Write-Warning "Could not resolve '$IconValue' in PATH for an icon." }
    return $null
}

function Pause-OnError {
    param($ErrorMessage)
    Write-Error $ErrorMessage
    Read-Host "An error occurred. Press Enter to continue..."
}

# --- CORE FUNCTIONS ---

function Do-Installation {
    Write-Host "`nStarting robust installation..." -ForegroundColor Cyan
    $allConfigs = Get-ModuleConfigurations
    if ($allConfigs.Count -eq 0) { Write-Warning "No modules found."; return }

    try {
        $managementModuleNames = @("Run-Manager", "Open-Root")
        $contextModuleMap = @{}

        # PASS 1: INSTALL TO COMMANDSTORE
        Write-Host "-> Pass 1: Installing all module commands to CommandStore..."
        foreach ($config in $allConfigs) {
            $moduleCommandPath = Join-Path $commandStorePath -ChildPath $config.moduleName
            New-Item -Path $moduleCommandPath -Force | Out-Null
            # Handle the separator as a special case for a visual line
            if ($config.moduleName -eq "QuickActionsSeparator") {
                Set-ItemProperty -Path $moduleCommandPath -Name "CommandFlags" -Value 16 -Type DWord -Force
                # Separators MUST NOT have text or they appear as menu items.
                if (Get-ItemProperty -Path $moduleCommandPath -Name "MUIVerb" -ErrorAction SilentlyContinue) {
                    Remove-ItemProperty -Path $moduleCommandPath -Name "MUIVerb" -Force
                }
            }
            # This block handles regular items
            else {
                if ($config.menuText) { Set-ItemProperty -Path $moduleCommandPath -Name "MUIVerb" -Value $config.menuText -Force }
                if ($config.icon) {
                    $resolvedIcon = Resolve-IconPath -IconValue $config.icon
                    if ($resolvedIcon) { Set-ItemProperty -Path $moduleCommandPath -Name "Icon" -Value $resolvedIcon -Force }
                }
            }

            if ($config.commandTemplate) {
                $commandKeyPath = Join-Path -Path $moduleCommandPath -ChildPath "command"
                New-Item -Path $commandKeyPath -Force -ErrorAction SilentlyContinue | Out-Null
                $finalCommand = $config.commandTemplate.Replace("{ActionScriptPath}", $config.ActionScriptPath)
                Set-ItemProperty -Path $commandKeyPath -Name "(default)" -Value $finalCommand -Force
            }
            if ($config.subCommands) {
                Set-ItemProperty -Path $moduleCommandPath -Name "SubCommands" -Value ($config.subCommands.Name -join ";") -Force
                foreach ($sub in $config.subCommands) {
                    $subCommandPath = Join-Path $commandStorePath -ChildPath $sub.Name
                    New-Item -Path $subCommandPath -Force -ErrorAction SilentlyContinue | Out-Null
                    Set-ItemProperty -Path $subCommandPath -Name "MUIVerb" -Value $sub.MenuText -Force
                    
                    # FIX: Create the 'command' subkey first, then set its value to prevent path errors.
                    $subCommandKeyPath = Join-Path -Path $subCommandPath -ChildPath "command"
                    New-Item -Path $subCommandKeyPath -Force -ErrorAction SilentlyContinue | Out-Null
                    
                    $subFinalCommand = $sub.Command.Replace("{ActionScriptPath}", $config.ActionScriptPath)
                    Set-ItemProperty -Path $subCommandKeyPath -Name "(default)" -Value $subFinalCommand -Force

                    if ($config.icon) {
                        $resolvedIcon = Resolve-IconPath -IconValue $config.icon
                        if ($resolvedIcon) { Set-ItemProperty -Path $subCommandPath -Name "Icon" -Value $resolvedIcon -Force }
                    }
                }
            }
            if ($config.targetContexts) {
                foreach ($context in $config.targetContexts) {
                    if (-not $contextModuleMap.ContainsKey($context)) { $contextModuleMap[$context] = [System.Collections.Generic.List[string]]@() }
                    $contextModuleMap[$context].Add($config.moduleName)
                }
            }
        }
        Write-Host "   ...Done." -ForegroundColor Green

        # PASS 2: BUILD MAIN MENUS (RE-ARCHITECTED FOR SAFETY)
        Write-Host "-> Pass 2: Building main context menus..."
        $managementMenuName = "ManageQuickActions"
        $managementMenuText = "Manage Quick Actions"

        foreach ($contextName in $contextModuleMap.Keys) {
            if ($contextRegistryMap.ContainsKey($contextName)) {
                $registryPaths = $contextRegistryMap[$contextName]
                if ($registryPaths -isnot [array]) { $registryPaths = @($registryPaths) }

                $allApplicable = $contextModuleMap[$contextName]
                [string[]]$standardCommands = @($allApplicable | Where-Object { $_ -notin $managementModuleNames -and $_ -ne "QuickActionsSeparator" } | Sort-Object)
                [string[]]$managementCommands = @($managementModuleNames | Where-Object { $_ -in $allApplicable })

                foreach ($regPath in $registryPaths) {
                    # --- Create the Main 'Quick Actions' Menu ---
                    if ($standardCommands.Length -gt 0) {
                        $mainMenuPath = Join-Path -Path $regPath -ChildPath $mainMenuKeyName
                        New-Item -Path $mainMenuPath -Force -ErrorAction SilentlyContinue | Out-Null
                        Set-ItemProperty -Path $mainMenuPath -Name "MUIVerb" -Value $mainMenuText -Force
                        Set-ItemProperty -Path $mainMenuPath -Name "Position" -Value "Top" -Force
                        Set-ItemProperty -Path $mainMenuPath -Name "SubCommands" -Value ($standardCommands -join ";") -Force
                    }

                    # --- Create the Separate 'Manage Quick Actions' Menu ---
                    if ($managementCommands.Length -gt 0) {
                        $mgmtMenuPath = Join-Path -Path $regPath -ChildPath $managementMenuName
                        New-Item -Path $mgmtMenuPath -Force -ErrorAction SilentlyContinue | Out-Null
                        Set-ItemProperty -Path $mgmtMenuPath -Name "MUIVerb" -Value $managementMenuText -Force
                        Set-ItemProperty -Path $mgmtMenuPath -Name "Position" -Value "Bottom" -Force
                        Set-ItemProperty -Path $mgmtMenuPath -Name "SubCommands" -Value ($managementCommands -join ";") -Force
                    }

                    # --- CRITICAL FIX for EXE Hijacking ---
                    # This is the key: ensure the default verb for 'exefile' is ALWAYS 'open'.
                    # This prevents our new menus from ever becoming the default action.
                    if ($contextName -eq "ExeFile") {
                        Write-Host "   -> Applying .exe safety fix to prevent hijacking..." -ForegroundColor Cyan
                        Set-ItemProperty -Path $regPath -Name "(default)" -Value "open" -Force
                    }
                }
            }
        }
        Write-Host "   ...Done." -ForegroundColor Green
        Write-Host "`nInstallation process finished!" -ForegroundColor Yellow
        PAUSE
    } catch {
    $errorDetails = @"
Exception Message  : $($_.Exception.Message)
Exception Type     : $($_.Exception.GetType().FullName)
Stack Trace        : $($_.Exception.StackTrace)
Inner Exception    : $($_.Exception.InnerException)
Script Line Number : $($_.InvocationInfo.ScriptLineNumber)
Command            : $($_.InvocationInfo.Line)
"@
    
    Pause-OnError -ErrorMessage $errorDetails
}
}

function Do-Removal {
    Write-Host "`nStarting FINAL, SAFE, and FAST removal process..." -ForegroundColor Cyan
    try {
        # Step 1: Reliably identify what to remove by reading module configs.
        Write-Host "-> Reading all module configurations to identify specific items for removal..."
        $allConfigs = Get-ModuleConfigurations
        if ($allConfigs.Count -eq 0) {
            Write-Warning "No modules found to remove."
            return # Exit if there's nothing to do.
        }

        # Step 2: Remove the specific entries from the CommandStore with detailed logging.
        Write-Host "-> Found $($allConfigs.Count) modules. Removing their specific entries from CommandStore..."
        foreach ($config in $allConfigs) {
            Write-Host "DEBUG: Processing module '$($config.moduleName)' for removal." -ForegroundColor Magenta

            # Remove the main module command
            $moduleCommandPath = Join-Path $commandStorePath $config.moduleName
            Write-Host "DEBUG: Targeting CommandStore path: $moduleCommandPath" -ForegroundColor Gray
            if (Test-Path $moduleCommandPath) {
                Write-Host "   - Removing command: $($config.moduleName)" -ForegroundColor Yellow
                Remove-Item -Path $moduleCommandPath -Recurse -Force -ErrorAction SilentlyContinue
            } else {
                Write-Host "   - Command not found (already removed): $($config.moduleName)" -ForegroundColor DarkGray
            }

            # Remove any associated sub-commands
            if ($config.subCommands) {
                foreach ($sub in $config.subCommands) {
                    $subCommandPath = Join-Path $commandStorePath $sub.Name
                    Write-Host "DEBUG: Targeting sub-command path: $subCommandPath" -ForegroundColor Gray
                    if (Test-Path $subCommandPath) {
                        Write-Host "   - Removing sub-command: $($sub.Name)" -ForegroundColor Yellow
                        Remove-Item -Path $subCommandPath -Recurse -Force -ErrorAction SilentlyContinue
                    } else {
                         Write-Host "   - Sub-command not found (already removed): $($sub.Name)" -ForegroundColor DarkGray
                    }
                }
            }
        }
        Write-Host "   ...CommandStore cleanup complete." -ForegroundColor Green

        # Step 3: Remove the main menu entries from all contexts.
        Write-Host "-> Removing base menu entries from all context locations."
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        $allPaths = $contextRegistryMap.Values | ForEach-Object { if ($_ -is [array]) { $_ } else { $_ } }
        $uniquePaths = $allPaths | Get-Unique
        
        $menusToRemove = @($mainMenuKeyName, "ManageQuickActions") # Add the new management menu to the list

        Write-Host "DEBUG: Will attempt to remove menu entries from $($uniquePaths.Count) unique registry locations." -ForegroundColor Magenta

        foreach ($path in $uniquePaths) {
            foreach ($menuName in $menusToRemove) {
                $menuPath = Join-Path $path $menuName
                # Directly attempt removal. This is fast and safe.
                # We don't use Test-Path as it's slow and was the source of hangs.
                Remove-Item -Path $menuPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        $stopwatch.Stop()
        Write-Host "DEBUG: Base menu removal loop finished in $($stopwatch.Elapsed.TotalMilliseconds) ms." -ForegroundColor Magenta
        Write-Host "   ...Base menu cleanup complete." -ForegroundColor Green
        Write-Host "`nRemoval process finished!" -ForegroundColor Yellow
        $stopwatch.Stop()
        Write-Host "DEBUG: Base menu removal loop finished in $($stopwatch.Elapsed.TotalMilliseconds) ms." -ForegroundColor Magenta
        Write-Host "   ...Base menu cleanup complete." -ForegroundColor Green
        Write-Host "`nRemoval process finished!" -ForegroundColor Yellow
    } catch { Pause-OnError -ErrorMessage $_.Exception.Message }
}

# --- INTERACTIVE CONSOLE ---
function Show-Interactive-Menu {
    while ($true) {
        Clear-Host
        Write-Host "======================================" -ForegroundColor Yellow
        Write-Host "  Quick Actions - Management Console"
        Write-Host "  (v7.0 - Running as Administrator)"
        Write-Host "======================================" -ForegroundColor Yellow
        $configs = Get-ModuleConfigurations
        if ($configs.Count -gt 0) {
            Write-Host "`nDiscovered $($configs.Count) modules:" -ForegroundColor Cyan
            $configs.moduleName | ForEach-Object { Write-Host " - $_" }
        } else { Write-Warning "`nNo modules found." }
        Write-Host "`nWhat would you like to do?`n" -ForegroundColor Cyan
        Write-Host " [1] Install or Refresh All Actions"
        Write-Host " [2] Remove All Actions`n"
        Write-Host " [Q] Quit`n"
        $choice = Read-Host "Enter your choice"
        switch ($choice) {
            "1" { Do-Installation; break }
            "2" { Do-Removal; break }
            "q" { Write-Host "Exiting."; exit }
            default { Write-Host "`nInvalid choice." -ForegroundColor Red; Read-Host "Press Enter to try again." }
        }
    }
}

# --- SCRIPT EXECUTION ---
if ($Mode) {
    switch ($Mode) {
        "Install" { Do-Installation }
        "Remove"  { Do-Removal }
    }
} else {
    Show-Interactive-Menu
}
Write-Host "`nOperation complete. You may need to restart Windows Explorer for all changes to take effect." -ForegroundColor Green
Read-Host "Press Enter to exit."
