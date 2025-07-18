[CmdletBinding()]
param()

# This action script finds and runs the main management script with admin rights.
# It determines the script root by navigating up from its own location.
try {
    $scriptRoot = (Get-Item -Path $MyInvocation.MyCommand.Path).Directory.Parent.Parent.Parent.FullName
    $managerScript = Join-Path -Path $scriptRoot -ChildPath "Manage-QuickActions.ps1"

    if (Test-Path $managerScript) {
        # Start the management script with elevated privileges.
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$managerScript`"" -Verb RunAs
    } else {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("The management script could not be found at the expected location:`n$managerScript", "Error", "OK", "Error")
    }
}
catch {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("An unexpected error occurred: $($_.Exception.Message)", "Error", "OK", "Error")
}
