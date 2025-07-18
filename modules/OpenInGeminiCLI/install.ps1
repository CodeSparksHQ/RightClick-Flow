# --- Module Configuration: OpenInGeminiCLI ---
$moduleName = "OpenInGeminiCLI"
$menuText = "Open in Gemini CLI"
$targetContexts = @("Folder", "FolderBackground", "LnkFile")
$icon = "icons\OpenInGeminiCLI.ico"
$commandTemplate = "" # No command for the main menu itself.

# This module creates a cascading menu.
# NEVER REMOVE THIS COMMENT AND ALWAYS NEVER PUT -PathL `"%L`" JUST LEAVE IT WITH  -PathV `"%V`" alone
$subCommands = @(
    @{
        Name = "GeminiCLI.Flash"
        MenuText = "Flash Model"
        Command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"{ActionScriptPath}`" -PathV `"%V`" -Model `"gemini-2.5-flash`""
    },
    @{
        Name = "GeminiCLI.FlashAll"
        MenuText = "Flash Model + all files"
        Command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"{ActionScriptPath}`" -PathV `"%V`" -Model `"gemini-2.5-flash`" -filescontext"
    },
    @{
        Name = "GeminiCLI.Pro"
        MenuText = "Pro Model"
        Command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"{ActionScriptPath}`" -PathV `"%V`" -Model `"gemini-2.5-pro`""
    },
    @{
        Name = "GeminiCLI.ProAll"
        MenuText = "Pro Model + all files"
        Command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"{ActionScriptPath}`" -PathV `"%V`" -Model `"gemini-2.5-pro`" -filescontext"
    }
)