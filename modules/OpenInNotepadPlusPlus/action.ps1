[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
    [string]$LnkPath
)

try {
    # Create a Shell object to read the shortcut
    $shell = New-Object -ComObject WScript.Shell

    # Get the shortcut object
    $shortcut = $shell.CreateShortcut($LnkPath)

    # Get the full target path string
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

            # Start Notepad++ with the script
            Start-Process -FilePath "notepad++.exe" -ArgumentList $scriptPath -WorkingDirectory $scriptDirectory
        }
        else {
            [System.Windows.Forms.MessageBox]::Show("The script file was not found:`n$scriptPath", "Error", "OK", "Error")
        }
    }
    # --- FALLBACK LOGIC START ---
    else {
        # If the first check fails, check if the main target path is a valid file.
        # Note: This fallback requires Notepad++ to be installed and in the system's PATH.
        if (Test-Path -Path $targetPath -PathType Leaf) {
            # Get the directory of the target file
            $scriptDirectory = Split-Path -Path $targetPath -Parent

            # Start Notepad++ with the target file, using its directory as the working directory
            Start-Process -FilePath "notepad++.exe" -ArgumentList $targetPath -WorkingDirectory $scriptDirectory
        }
        else {
            # If neither logic works, show an error.
            $message = "Action failed.`n`nThe shortcut does not use the -File parameter, and the target file below was not found:`n`n$targetPath"
            Add-Type -AssemblyName System.Windows.Forms
            [System.Windows.Forms.MessageBox]::Show($message, "Error", "OK", "Error")
        }
    }
    # --- FALLBACK LOGIC END ---
}
catch {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("An error occurred: $($_.Exception.Message)", "Error", "OK", "Error")
}
