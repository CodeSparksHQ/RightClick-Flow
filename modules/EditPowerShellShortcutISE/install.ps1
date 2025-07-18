# --- Module Configuration: EditPowerShellShortcutISE ---
$moduleName = "EditPowerShellShortcutISE"
$menuText = "Edit in PowerShell ISE"
$targetContexts = @("LnkFile")
$commandTemplate = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"{ActionScriptPath}`" -LnkPath `"%1`""
$icon = "$($env:windir)\System32\WindowsPowerShell\v1.0\powershell_ise.exe,0"
