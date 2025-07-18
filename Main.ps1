# --- SCRIPT SETUP AND SELF-ELEVATION ---
if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Administrator privileges are required. Attempting to re-launch as Administrator..."
    $arguments = "& '" + $MyInvocation.MyCommand.Path + "'"
    Start-Process powershell -Verb RunAs -ArgumentList $arguments
    exit
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# Load the XAML
$xamlPath = "B:\Github-Repos\Personal Projects\RightClick-Flow\RightClick-Flow\MainWindow.xaml"
$xaml = [System.IO.File]::ReadAllText($xamlPath)
$stringReader = New-Object System.IO.StringReader $xaml
$xmlReader = [System.Xml.XmlReader]::Create($stringReader)
$window = [System.Windows.Markup.XamlReader]::Load($xmlReader)

# Get the controls
$modulesStackPanel = $window.FindName("ModulesStackPanel")
$logsTextBox = $window.FindName("LogsTextBox")

# Function to write logs
function Write-Log {
    param (
        [string]$message
    )
    $logsTextBox.AppendText("$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $message`r`n")
    $logsTextBox.ScrollToEnd()
}

# Scan for modules
$modulesPath = "B:\Github-Repos\Personal Projects\RightClick-Flow\RightClick-Flow\Modules"
$installScripts = Get-ChildItem -Path $modulesPath -Filter "Install.ps1" -Recurse

foreach ($installScript in $installScripts) {
    $moduleDir = $installScript.Directory
    $moduleName = $moduleDir.Name
    $installScriptPath = $installScript.FullName
    $removeScriptPath = Join-Path -Path $moduleDir.FullName -ChildPath "Remove.ps1"


    # Create a grid to hold the module name and toggle button
    $grid = New-Object System.Windows.Controls.Grid
    $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = New-Object System.Windows.GridLength(1, "Star") }))
    $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = New-Object System.Windows.GridLength(1, "Auto") }))


    # Create a TextBlock for the module name
    $textBlock = New-Object System.Windows.Controls.TextBlock
    $textBlock.Text = $moduleName
    $textBlock.Foreground = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromArgb(255, 255, 255, 255))
    $textBlock.VerticalAlignment = "Center"
    $textBlock.Margin = New-Object System.Windows.Thickness(0,0,10,0)
    [System.Windows.Controls.Grid]::SetColumn($textBlock, 0)

    # Create a ToggleButton
    $toggleButton = New-Object System.Windows.Controls.Primitives.ToggleButton
    $toggleButton.Margin = New-Object System.Windows.Thickness(10, 5, 10, 5)
    $toggleButton.VerticalAlignment = "Center"
    [System.Windows.Controls.Grid]::SetColumn($toggleButton, 1)


    # Check if the module is already installed (you might need a more robust way to check this)
    # For now, let's assume it's not installed by default
    $toggleButton.IsChecked = $false

    # Add event handler
    $toggleButton.Add_Click({
        $button = $args[0]
        if ($button.IsChecked) {
            Write-Log "Installing module: $moduleName"
            try {
                $output = & $installScriptPath
                Write-Log "Installation output: $output"
                Write-Log "Module '$moduleName' installed successfully."
            } catch {
                Write-Log "Error installing module '$moduleName': $_"
                $button.IsChecked = $false # Revert the toggle state on error
            }
        } else {
            Write-Log "Removing module: $moduleName"
            try {
                $output = & $removeScriptPath
                Write-Log "Removal output: $output"
                Write-Log "Module '$moduleName' removed successfully."
            } catch {
                Write-Log "Error removing module '$moduleName': $_"
                $button.IsChecked = $true # Revert the toggle state on error
            }
        }
    }.GetNewClosure())

    $grid.Children.Add($textBlock)
    $grid.Children.Add($toggleButton)

    # Add the grid to the StackPanel
    $modulesStackPanel.Children.Add($grid)
}

# Show the window
$window.ShowDialog() | Out-Null

