# Remove Script for Run-Manager Module
$moduleName = "Run-Manager"
$commandStorePath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell"
$moduleCommandPath = Join-Path $commandStorePath -ChildPath $moduleName

if (Test-Path $moduleCommandPath) {
    Remove-Item -Path $moduleCommandPath -Recurse -Force
}
