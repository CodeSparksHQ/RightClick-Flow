# Action Script: Opens the containing folder of the given file path.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$FilePath
)

# Check if the file actually exists before trying to open its location.
if (Test-Path -Path $FilePath -PathType Leaf) {
    try {
        # Create a Shell object to read the shortcut
        $shell = New-Object -ComObject WScript.Shell
        # Get the shortcut object
        $shortcut = $shell.CreateShortcut($FilePath)
        # Get the "Start in" folder
        $startInFolder = $shortcut.WorkingDirectory

        # Check if the WorkingDirectory path is valid before trying to open it.
        if ($startInFolder -and (Test-Path -Path $startInFolder)) {
            # Open the "Start in" directory in Windows Explorer.
            Invoke-Item -Path $startInFolder
        } else {
            # If the "Start In" folder is blank or doesn't exist, try to parse the target.
            $targetPath = $shortcut.TargetPath
            $arguments = $shortcut.Arguments

            # Check if the target is powershell.exe and arguments contain -File
            if ($targetPath -like "*powershell.exe" -and $arguments -match '-File\s+"([^"]+)"') {
                # Extract the script path from the arguments
                $scriptPath = $matches[1]

                # Check if the script file exists
                if (Test-Path $scriptPath) {
                    # Get the directory of the target script
                    $scriptDirectory = Split-Path -Path $scriptPath -Parent
                    Invoke-Item -Path $scriptDirectory
                } else {
                    [System.Windows.Forms.MessageBox]::Show("The script file in the shortcut target was not found:`n$scriptPath", "Error", "OK", "Error")
                }
            }
            # --- FALLBACK LOGIC FOR OTHER FILE TYPES ---
            elseif (Test-Path -Path $targetPath -PathType Leaf) {
                # Get the directory of the target file
                $parentFolder = Split-Path -Path $targetPath -Parent
                Invoke-Item -Path $parentFolder
            }
            else {
                # If neither logic works, show an error.
                $message = "Action failed.`n`nThe shortcut's 'Start In' folder was not found, and the target file below was not found:`n`n$targetPath"
                Add-Type -AssemblyName System.Windows.Forms
                [System.Windows.Forms.MessageBox]::Show($message, "Error", "OK", "Error")
            }
        }
    } catch {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("An error occurred while reading the shortcut: $($_.Exception.Message)", "Error", "OK", [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}
else {
    # Fallback error message if the path is invalid.
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("The specified file does not exist:`n$FilePath", "Error", "OK", [System.Windows.Forms.MessageBoxIcon]::Error)
}