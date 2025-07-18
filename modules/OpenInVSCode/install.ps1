# --- Module Configuration: OpenInVSCode ---
$moduleName = "OpenInVSCode"
$menuText = "Open in VS Code"
$targetContexts = @("Folder", "FolderBackground")
$commandTemplate = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"{ActionScriptPath}`" -PathV `"%V`""
$icon = "code"