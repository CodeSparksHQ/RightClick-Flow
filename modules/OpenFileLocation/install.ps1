# --- Module Configuration: OpenFileLocation ---
$moduleName = "OpenFileLocation"
$menuText = "Open File Location"
$targetContexts = @("LnkFile")
$commandTemplate = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"{ActionScriptPath}`" -FilePath `"%1`""
$icon = "icons\OpenFileLocation.ico"