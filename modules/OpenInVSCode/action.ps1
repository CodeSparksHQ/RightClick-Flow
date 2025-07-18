# Action Script: Opens the target folder in Visual Studio Code using a universal path resolver.
[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$PathL, # Corresponds to %L (long file name for files/folders)

    [Parameter(Mandatory=$false)]
    [string]$PathV  # Corresponds to %V (directory for background clicks)
)

# Determine the correct path: If %L was expanded, use it; otherwise, fall back to %V.
$workingPath = if ($PathL -ne "%L" -and -not [string]::IsNullOrEmpty($PathL)) { $PathL } else { $PathV }

# Check if the resolved path is a valid, existing directory
if ($workingPath -and (Test-Path -Path $workingPath -PathType Container)) {
    # If it is, execute 'code.exe' with the folder path as the argument
    Start-Process code -ArgumentList "`"$workingPath`""
}
else {
    # If the path is somehow invalid, show an error.
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("The specified folder does not exist or could not be resolved:`n$workingPath", "Error", "OK", [System.Windows.Forms.MessageBoxIcon]::Error)
}