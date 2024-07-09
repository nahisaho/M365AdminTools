# setup.ps1

# Get the directory of the current script
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Add the scripts directory to PATH
$path = [System.Environment]::GetEnvironmentVariable("PATH", "User")
if ($path -notcontains "$scriptDir\scripts") {
    [System.Environment]::SetEnvironmentVariable("PATH", "$path;$scriptDir\scripts", "User")
    Write-Host "Added $scriptDir\scripts to PATH"
} else {
    Write-Host "$scriptDir\scripts is already in PATH"
}

# Restart PowerShell session to reflect the environment variable change
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location -Path $scriptDir"
