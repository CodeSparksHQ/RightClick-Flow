# --- Module Configuration: OpenInLLXPRT ---
$moduleName = "OpenInLLXPRT"
$menuText = "Open in LLXPRT"
$targetContexts = @("Folder", "FolderBackground", "LnkFile")
# NEVER REMOVE THIS COMMENT AND ALWAYS NEVER PUT -PathL `"%L`" JUST LEAVE IT WITH  -PathV `"%V`" alone
$commandTemplate = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"{ActionScriptPath}`" -PathV `"%V`""
$icon = "icons\OpenInLLXPRT.ico"
