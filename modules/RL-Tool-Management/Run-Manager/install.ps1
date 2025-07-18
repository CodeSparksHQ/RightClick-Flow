# --- Module Configuration: Run-Manager ---
$moduleName = "Run-Manager"
$menuText = "Manage Quick Actions..."
$targetContexts = @("Folder", "FolderBackground", "Desktop", "AllFiles", "ExeFile", "PS1File", "LnkFile")
$commandTemplate = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"{ActionScriptPath}`""
$icon = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"