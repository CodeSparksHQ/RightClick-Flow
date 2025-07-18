[CmdletBinding()]
param()

# This action script opens the root directory of the RL-TOOL project.
# It determines the root by navigating up from its own location.
try {
    $scriptRoot = (Get-Item -Path $MyInvocation.MyCommand.Path).Directory.Parent.Parent.Parent.FullName
    Invoke-Item -Path $scriptRoot
}
catch {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("An unexpected error occurred: $($_.Exception.Message)", "Error", "OK", "Error")
}
