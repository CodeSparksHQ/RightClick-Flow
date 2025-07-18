# --- Module Configuration: OpenInNotepadPlusPlus ---
$moduleName = "OpenInNotepadPlusPlus"
$menuText = "Open in Notepad++"
$targetContexts = @("LnkFile")
$commandTemplate = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"{ActionScriptPath}`" -LnkPath `"%1`""
$icon = "C:\Program Files\Notepad++\notepad++.exe"
