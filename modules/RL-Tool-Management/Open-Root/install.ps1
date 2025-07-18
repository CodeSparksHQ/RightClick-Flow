# --- Module Configuration: Open-Root ---
$moduleName = "Open-Root"
$menuText = "Open RL-TOOL Folder"
$targetContexts = @("Folder", "FolderBackground", "Desktop", "AllFiles", "ExeFile", "PS1File", "LnkFile")
$commandTemplate = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"{ActionScriptPath}`""
$icon = "imageres.dll,-112"